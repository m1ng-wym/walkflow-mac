#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="WalkFlowMac"
BUNDLE_NAME="WalkFlow-Mac.app"
BUNDLE_ID="com.m1ngwym.walkflowmac"
RESOURCE_BUNDLE_NAME="WalkFlowMac_WalkFlowMacApp.bundle"
CONFIGURATION="debug"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUNDLE_PATH="$DIST_DIR/$BUNDLE_NAME"
EXECUTABLE_PATH="$BUNDLE_PATH/Contents/MacOS/$APP_NAME"
INFO_PLIST_SOURCE="$ROOT_DIR/Sources/WalkFlowMacApp/Resources/Info.plist"
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
  /bin/mkdir -p "$BUNDLE_PATH/Contents/MacOS" "$BUNDLE_PATH/Contents/Resources"
  /bin/cp "$BUILD_PRODUCTS_DIR/$APP_NAME" "$EXECUTABLE_PATH"
  for framework in "$BUILD_PRODUCTS_DIR"/*.framework; do
    [[ -e "$framework" ]] || continue
    /bin/cp -R "$framework" "$BUNDLE_PATH/Contents/MacOS/"
  done
  for resource_bundle in "$BUILD_PRODUCTS_DIR"/*.bundle "$BUILD_PRODUCTS_DIR"/*.resources; do
    [[ -e "$resource_bundle" ]] || continue
    /bin/cp -R "$resource_bundle" "$BUNDLE_PATH/"
  done
  /bin/cp "$INFO_PLIST_SOURCE" "$BUNDLE_PATH/Contents/Info.plist"
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
  test -s "$BUNDLE_PATH/$RESOURCE_BUNDLE_NAME/Lottie/alertTriangle.json"
}

build_and_stage_app() {
  build_app
  stage_bundle
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
