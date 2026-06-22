#!/usr/bin/env bash
set -euo pipefail

APP_NAME="WalkFlow-Mac"
DEFAULT_IDENTITY_NAME="WalkFlow Local Development"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_SIGNING_ENV="$ROOT_DIR/.walkflow-local-signing.env"
IDENTITY_NAME="${WALKFLOW_LOCAL_SIGNING_IDENTITY:-$DEFAULT_IDENTITY_NAME}"
VALID_DAYS="${WALKFLOW_LOCAL_SIGNING_DAYS:-3650}"
KEYCHAIN="${WALKFLOW_LOCAL_SIGNING_KEYCHAIN:-}"
TEMP_DIR_TO_CLEAN=""
trap cleanup EXIT

usage() {
  cat <<EOF
usage: $0 [--check|--help]

Creates a local self-signed Code Signing identity for $APP_NAME and writes:
  $LOCAL_SIGNING_ENV

This is for local development only. It is not for distribution, notarization,
or release signing.

Environment overrides:
  WALKFLOW_LOCAL_SIGNING_IDENTITY   Certificate common name. Default: $DEFAULT_IDENTITY_NAME
  WALKFLOW_LOCAL_SIGNING_DAYS       Validity in days. Default: 3650
  WALKFLOW_LOCAL_SIGNING_KEYCHAIN   Target keychain. Default: user's default keychain
EOF
}

main() {
  case "${1:-}" in
    --help|-h)
      usage
      return 0
      ;;
    --check)
      resolve_keychain
      if identity_is_valid; then
        write_local_env
        echo "Found valid local signing identity: $IDENTITY_NAME"
        echo "Wrote $LOCAL_SIGNING_ENV"
        return 0
      fi
      echo "No valid local signing identity found: $IDENTITY_NAME" >&2
      return 1
      ;;
    "")
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac

  require_tool /usr/bin/security
  require_tool /usr/bin/codesign
  require_openssl
  resolve_keychain

  if identity_is_valid; then
    write_local_env
    echo "Found existing valid local signing identity: $IDENTITY_NAME"
    echo "Wrote $LOCAL_SIGNING_ENV"
    print_next_steps
    return 0
  fi

  if identity_exists; then
    echo "An identity named '$IDENTITY_NAME' exists but is not a valid code signing identity." >&2
    echo "Trust it for Code Signing in Keychain Access, or delete it and rerun this script." >&2
    echo "Then run: $0 --check" >&2
    return 1
  fi

  echo "Creating local self-signed Code Signing identity: $IDENTITY_NAME"
  echo "macOS may ask for password or Touch ID to trust the certificate for code signing."
  create_identity
  verify_identity
  write_local_env
  print_next_steps
}

require_tool() {
  local tool="$1"
  if [[ ! -x "$tool" ]]; then
    echo "Missing required tool: $tool" >&2
    exit 2
  fi
}

cleanup() {
  if [[ -n "${TEMP_DIR_TO_CLEAN:-}" ]]; then
    rm -rf "$TEMP_DIR_TO_CLEAN"
  fi
}

require_openssl() {
  if ! command -v openssl >/dev/null 2>&1; then
    echo "Missing required tool: openssl" >&2
    echo "Install OpenSSL, then rerun this script." >&2
    exit 2
  fi
}

resolve_keychain() {
  if [[ -z "$KEYCHAIN" ]]; then
    KEYCHAIN="$(/usr/bin/security default-keychain -d user \
      | /usr/bin/sed -e 's/^[[:space:]]*"//' -e 's/"[[:space:]]*$//')"
  fi
}

identity_is_valid() {
  /usr/bin/security find-identity -p codesigning -v "$KEYCHAIN" \
    | /usr/bin/grep -F "\"$IDENTITY_NAME\"" >/dev/null
}

identity_exists() {
  /usr/bin/security find-identity -p codesigning "$KEYCHAIN" \
    | /usr/bin/grep -F "\"$IDENTITY_NAME\"" >/dev/null
}

create_identity() {
  local previous_umask
  previous_umask="$(umask)"
  umask 077

  TEMP_DIR_TO_CLEAN="$(/usr/bin/mktemp -d)"
  /bin/chmod 700 "$TEMP_DIR_TO_CLEAN"

  local openssl_config="$TEMP_DIR_TO_CLEAN/codesign.cnf"
  local private_key="$TEMP_DIR_TO_CLEAN/key.pem"
  local certificate="$TEMP_DIR_TO_CLEAN/cert.pem"
  local identity_p12="$TEMP_DIR_TO_CLEAN/identity.p12"
  local p12_password
  p12_password="$(/usr/bin/uuidgen)-$(/usr/bin/uuidgen)"

  write_openssl_config "$openssl_config"

  openssl req \
    -x509 \
    -newkey rsa:2048 \
    -nodes \
    -keyout "$private_key" \
    -out "$certificate" \
    -days "$VALID_DAYS" \
    -config "$openssl_config" >/dev/null 2>&1

  local pkcs12_args=(
    pkcs12
    -export
    -inkey "$private_key"
    -in "$certificate"
    -out "$identity_p12"
    -passout "pass:$p12_password"
    -name "$IDENTITY_NAME"
  )
  if openssl pkcs12 -help 2>&1 | /usr/bin/grep -q -- "-legacy"; then
    pkcs12_args=(pkcs12 -legacy "${pkcs12_args[@]:1}")
  fi

  openssl "${pkcs12_args[@]}" >/dev/null 2>&1

  /usr/bin/security import "$identity_p12" \
    -k "$KEYCHAIN" \
    -P "$p12_password" \
    -T /usr/bin/codesign \
    -T /usr/bin/security >/dev/null

  /usr/bin/security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$certificate"
  umask "$previous_umask"
}

write_openssl_config() {
  local config_path="$1"
  cat > "$config_path" <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = codesign_ext

[ dn ]
CN = $IDENTITY_NAME

[ codesign_ext ]
basicConstraints = critical, CA:TRUE
keyUsage = critical, digitalSignature, keyCertSign
extendedKeyUsage = codeSigning
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
EOF
}

write_local_env() {
  cat > "$LOCAL_SIGNING_ENV" <<EOF
# Local-only WalkFlow-Mac signing configuration.
# Generated by script/setup_local_signing.sh. Do not commit this file.
export WALKFLOW_CODESIGN_IDENTITY=$(shell_quote "$IDENTITY_NAME")
export WALKFLOW_CODESIGN_KEYCHAIN=$(shell_quote "$KEYCHAIN")
export WALKFLOW_REQUIRE_CERT_SIGNING=1
EOF
}

shell_quote() {
  local value="$1"
  printf "'%s'" "$(printf "%s" "$value" | /usr/bin/sed "s/'/'\\\\''/g")"
}

verify_identity() {
  if ! identity_is_valid; then
    echo "Created certificate, but it is not a valid code signing identity yet." >&2
    echo "Open Keychain Access, trust '$IDENTITY_NAME' for Code Signing, then rerun: $0 --check" >&2
    exit 1
  fi
}

print_next_steps() {
  cat <<EOF

Local signing is configured.

This identity is for local development only. It is not for distribution,
notarization, or release signing.

Next:
  ./script/build_and_run.sh --verify

Validation:
  /usr/bin/codesign -dr - dist/WalkFlow-Mac.app

The designated requirement should no longer be cdhash-only.
EOF
}

main "$@"
