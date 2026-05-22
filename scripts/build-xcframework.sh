#!/bin/bash
set -euo pipefail

# Usage: bash scripts/build-xcframework.sh <branch> <sha> <xcode_app_name> <output_dir>
# Example: bash scripts/build-xcframework.sh community abc123 Xcode_26.0.1 ./artifacts

BRANCH="$1"
SHA="$2"
XCODE_APP="$3"
mkdir -p "$4"
OUTPUT_DIR="$(cd "$4" && pwd)"
UPSTREAM_REPO="https://github.com/realm/realm-swift.git"
WORK_DIR="$(mktemp -d)"

cleanup() {
  echo "Cleaning up ${WORK_DIR}..."
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

echo "=== Build Configuration ==="
echo "Branch: ${BRANCH}"
echo "SHA: ${SHA}"
echo "Xcode: ${XCODE_APP}"
echo "Output: ${OUTPUT_DIR}"
echo "Work dir: ${WORK_DIR}"

# Select Xcode
XCODE_PATH="/Applications/${XCODE_APP}.app"
if [ ! -d "$XCODE_PATH" ]; then
  echo "ERROR: Xcode not found at ${XCODE_PATH}"
  echo "Available Xcode installations:"
  ls -d /Applications/Xcode*.app 2>/dev/null || echo "  (none found)"
  exit 1
fi
sudo xcode-select -s "${XCODE_PATH}/Contents/Developer"
XCODE_VERSION=$(xcodebuild -version 2>&1 || true)
echo "Using $(echo "$XCODE_VERSION" | head -1)"

# Clone realm-swift at the target SHA
echo "=== Cloning realm-swift at ${SHA} ==="
git clone --depth 1 "${UPSTREAM_REPO}" "${WORK_DIR}/realm-swift"
cd "${WORK_DIR}/realm-swift"
git fetch origin "${SHA}" --depth 1
git checkout "${SHA}"

# Download realm-core binary dependency
echo "=== Downloading realm-core ==="
bash build.sh download-core

# Build static xcframeworks for all platforms
echo "=== Building static xcframeworks ==="
export CI=true
export CONFIGURATION=Static
export LINKAGE=static
unset GITHUB_WORKSPACE
bash build.sh xcframework

# The xcframeworks are in build/Static/
BUILD_DIR="${WORK_DIR}/realm-swift/build/Static"

if [ ! -d "${BUILD_DIR}/Realm.xcframework" ]; then
  echo "ERROR: Realm.xcframework not found in ${BUILD_DIR}"
  ls -la "${BUILD_DIR}/" 2>/dev/null || echo "Build directory does not exist"
  exit 1
fi

if [ ! -d "${BUILD_DIR}/RealmSwift.xcframework" ]; then
  echo "ERROR: RealmSwift.xcframework not found in ${BUILD_DIR}"
  exit 1
fi

# Copy to output directory
cp -R "${BUILD_DIR}/Realm.xcframework" "${OUTPUT_DIR}/"
cp -R "${BUILD_DIR}/RealmSwift.xcframework" "${OUTPUT_DIR}/"

echo "=== Build complete ==="
echo "Realm.xcframework -> ${OUTPUT_DIR}/Realm.xcframework"
echo "RealmSwift.xcframework -> ${OUTPUT_DIR}/RealmSwift.xcframework"
