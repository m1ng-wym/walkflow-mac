#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="WalkFlowMac"
BUNDLE_NAME="WalkFlow-Mac.app"
BUNDLE_ID="com.m1ngwym.walkflowmac"
RESOURCE_BUNDLE_NAME="WalkFlowMac_WalkFlowMacApp.bundle"
CONFIGURATION="debug"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_SIGNING_ENV="$ROOT_DIR/.walkflow-local-signing.env"
if [[ -f "$LOCAL_SIGNING_ENV" ]]; then
  source "$LOCAL_SIGNING_ENV"
fi

DIST_DIR="$ROOT_DIR/dist"
BUNDLE_PATH="$DIST_DIR/$BUNDLE_NAME"
EXECUTABLE_PATH="$BUNDLE_PATH/Contents/MacOS/$APP_NAME"
FRAMEWORKS_DIR="$BUNDLE_PATH/Contents/Frameworks"
INFO_PLIST_SOURCE="$ROOT_DIR/Sources/WalkFlowMacApp/Resources/Info.plist"
CODESIGN_IDENTITY="${WALKFLOW_CODESIGN_IDENTITY:-}"
CODESIGN_KEYCHAIN="${WALKFLOW_CODESIGN_KEYCHAIN:-}"
CODESIGN_ENTITLEMENTS="${WALKFLOW_CODESIGN_ENTITLEMENTS:-$ROOT_DIR/script/WalkFlowMac.debug.entitlements}"
REQUIRE_CERT_SIGNING="${WALKFLOW_REQUIRE_CERT_SIGNING:-0}"
BUILD_PRODUCTS_DIR=""

stop_app() {
  /usr/bin/pkill -x "$APP_NAME" 2>/dev/null || true
}

stage_bundle() {
  if [[ -d "$BUNDLE_PATH" ]]; then
    case "$BUNDLE_PATH" in
      "$DIST_DIR"/*.app) /bin/rm -R "$BUNDLE_PATH" ;;
      *) echo "Refusing to remove unexpected bundle path: $BUNDLE_PATH" >&2; exit 2 ;;
    esac
  fi
  /bin/mkdir -p "$BUNDLE_PATH/Contents/MacOS" "$FRAMEWORKS_DIR" "$BUNDLE_PATH/Contents/Resources/Lottie"
  /bin/cp "$BUILD_PRODUCTS_DIR/$APP_NAME" "$EXECUTABLE_PATH"
  for framework in "$BUILD_PRODUCTS_DIR"/*.framework; do
    [[ -e "$framework" ]] || continue
    /bin/cp -R "$framework" "$FRAMEWORKS_DIR/"
  done
  add_framework_rpath
  stage_lottie_resources
  /bin/cp "$INFO_PLIST_SOURCE" "$BUNDLE_PATH/Contents/Info.plist"
}

add_framework_rpath() {
  local framework_rpath="@executable_path/../Frameworks"
  if ! /usr/bin/otool -l "$EXECUTABLE_PATH" | /usr/bin/grep -F -- "$framework_rpath" >/dev/null; then
    /usr/bin/install_name_tool -add_rpath "$framework_rpath" "$EXECUTABLE_PATH"
  fi
}

stage_lottie_resources() {
  local resource_bundle_path="$BUILD_PRODUCTS_DIR/$RESOURCE_BUNDLE_NAME"
  if [[ ! -d "$resource_bundle_path/Lottie" ]]; then
    echo "Missing SwiftPM Lottie resource directory: $resource_bundle_path/Lottie" >&2
    exit 2
  fi

  /bin/mkdir -p "$BUNDLE_PATH/Contents/Resources"
  /bin/cp -R "$resource_bundle_path/Lottie" "$BUNDLE_PATH/Contents/Resources/"
}

build_app() {
  cd "$ROOT_DIR"
  swift build -c "$CONFIGURATION" --product "$APP_NAME"
  BUILD_PRODUCTS_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
}

launch_app() {
  /usr/bin/open -n "$BUNDLE_PATH"
}

launch_existing_app() {
  if [[ ! -x "$EXECUTABLE_PATH" ]]; then
    echo "Existing app bundle is missing or not executable: $EXECUTABLE_PATH" >&2
    exit 2
  fi
  launch_app
}

verify_app() {
  sleep 2
  /usr/bin/pgrep -x "$APP_NAME" >/dev/null
  test -s "$BUNDLE_PATH/Contents/Resources/Lottie/alertTriangle.json"
}

build_and_stage_app() {
  preflight_codesign_configuration
  build_app
  stage_bundle
  sign_staged_app_if_configured
}

preflight_codesign_configuration() {
  if [[ -z "$CODESIGN_IDENTITY" ]]; then
    if [[ "$REQUIRE_CERT_SIGNING" == "1" || "$REQUIRE_CERT_SIGNING" == "true" ]]; then
      echo "Certificate-backed signing is required, but WALKFLOW_CODESIGN_IDENTITY is not set." >&2
      exit 2
    fi
    return 0
  fi

  validate_codesign_identity
}

sign_staged_app_if_configured() {
  if [[ -z "$CODESIGN_IDENTITY" ]]; then
    sign_ad_hoc_debug_bundle
    return 0
  fi

  validate_codesign_identity
  sign_nested_code
  sign_app_bundle
  verify_signed_app_bundle
}

validate_codesign_identity() {
  if [[ ! -f "$CODESIGN_ENTITLEMENTS" ]]; then
    echo "Missing codesign entitlements file: $CODESIGN_ENTITLEMENTS" >&2
    exit 2
  fi

  local identity_output
  if [[ -n "$CODESIGN_KEYCHAIN" ]]; then
    identity_output="$(/usr/bin/security find-identity -p codesigning -v "$CODESIGN_KEYCHAIN")"
  else
    identity_output="$(/usr/bin/security find-identity -p codesigning -v)"
  fi

  if ! matches_codesign_identity "$identity_output"; then
    echo "Configured WALKFLOW_CODESIGN_IDENTITY was not found: $CODESIGN_IDENTITY" >&2
    echo "Run ./script/setup_local_signing.sh to create a free local signing identity." >&2
    echo "To use ad-hoc debug fallback instead, remove .walkflow-local-signing.env or unset WALKFLOW_CODESIGN_IDENTITY." >&2
    exit 2
  fi
}

matches_codesign_identity() {
  local identity_output="$1"
  if [[ "$CODESIGN_IDENTITY" =~ ^[[:xdigit:]]{40}$ ]]; then
    /usr/bin/grep -E "^[[:space:]]*[0-9]+\\) ${CODESIGN_IDENTITY}[[:space:]]+\"" <<<"$identity_output" >/dev/null
  else
    /usr/bin/grep -F "\"$CODESIGN_IDENTITY\"" <<<"$identity_output" >/dev/null
  fi
}

codesign_keychain_args() {
  if [[ -n "$CODESIGN_KEYCHAIN" ]]; then
    printf '%s\n' --keychain "$CODESIGN_KEYCHAIN"
  fi
}

sign_nested_code() {
  local keychain_args=()
  while IFS= read -r arg; do
    keychain_args+=("$arg")
  done < <(codesign_keychain_args)

  while IFS= read -r -d '' framework; do
    /usr/bin/codesign --force --timestamp=none "${keychain_args[@]}" --sign "$CODESIGN_IDENTITY" "$framework"
  done < <(/usr/bin/find "$FRAMEWORKS_DIR" -type d -name "*.framework" -prune -print0)
}

sign_ad_hoc_debug_bundle() {
  if [[ ! -f "$CODESIGN_ENTITLEMENTS" ]]; then
    echo "Missing codesign entitlements file: $CODESIGN_ENTITLEMENTS" >&2
    exit 2
  fi

  while IFS= read -r -d '' framework; do
    /usr/bin/codesign --force --timestamp=none --sign - "$framework"
  done < <(/usr/bin/find "$FRAMEWORKS_DIR" -type d -name "*.framework" -prune -print0)

  /usr/bin/codesign \
    --force \
    --timestamp=none \
    --entitlements "$CODESIGN_ENTITLEMENTS" \
    --sign - \
    "$BUNDLE_PATH"

  verify_debug_ad_hoc_app_bundle
}

verify_debug_ad_hoc_app_bundle() {
  verify_nested_code_signature_integrity
  /usr/bin/codesign --verify --strict --verbose=4 "$BUNDLE_PATH"
}

sign_app_bundle() {
  local keychain_args=()
  while IFS= read -r arg; do
    keychain_args+=("$arg")
  done < <(codesign_keychain_args)

  /usr/bin/codesign \
    --force \
    --timestamp=none \
    --options runtime \
    --entitlements "$CODESIGN_ENTITLEMENTS" \
    "${keychain_args[@]}" \
    --sign "$CODESIGN_IDENTITY" \
    "$BUNDLE_PATH"
}

verify_signed_app_bundle() {
  verify_nested_code
  /usr/bin/codesign --verify --strict --verbose=4 "$BUNDLE_PATH"
  if /usr/bin/codesign -dr - "$BUNDLE_PATH" 2>&1 | /usr/bin/grep -q 'designated => cdhash'; then
    echo "Signed app still has a cdhash-only designated requirement; use a certificate-backed signing identity." >&2
    exit 2
  fi
}

verify_nested_code() {
  verify_nested_code_signature_integrity
  while IFS= read -r -d '' framework; do
    if /usr/bin/codesign -dr - "$framework" 2>&1 | /usr/bin/grep -q 'designated => cdhash'; then
      echo "Nested code still has a cdhash-only designated requirement: $framework" >&2
      exit 2
    fi
  done < <(/usr/bin/find "$FRAMEWORKS_DIR" -type d -name "*.framework" -prune -print0)
}

verify_nested_code_signature_integrity() {
  while IFS= read -r -d '' framework; do
    /usr/bin/codesign --verify --strict --verbose=4 "$framework"
  done < <(/usr/bin/find "$FRAMEWORKS_DIR" -type d -name "*.framework" -prune -print0)
}

case "$MODE" in
  run)
    stop_app
    build_and_stage_app
    launch_app
    ;;
  --verify|verify)
    stop_app
    build_and_stage_app
    launch_app
    verify_app
    echo "Verified $APP_NAME is running."
    ;;
  --logs|logs)
    stop_app
    build_and_stage_app
    launch_app
    /usr/bin/log stream --info --style compact --predicate 'process == "WalkFlowMac"'
    ;;
  --telemetry|telemetry)
    stop_app
    build_and_stage_app
    launch_app
    /usr/bin/log stream --info --style compact --predicate 'subsystem == "com.m1ngwym.walkflowmac"'
    ;;
  --launch-existing|launch-existing)
    stop_app
    launch_existing_app
    ;;
  --debug|debug)
    stop_app
    build_and_stage_app
    lldb -- "$EXECUTABLE_PATH"
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--launch-existing]" >&2
    exit 2
    ;;
esac
