#!/bin/bash
set -euo pipefail

# Usage: bash scripts/package-release.sh <input_dir> <output_dir> <xcode_version>
# Input dir must contain Realm.xcframework and RealmSwift.xcframework
# Produces:
#   <output_dir>/Realm.spm.zip
#   <output_dir>/RealmSwift@<xcode_version>.spm.zip

INPUT_DIR="$(cd "$1" && pwd)"
mkdir -p "$2"
OUTPUT_DIR="$(cd "$2" && pwd)"
XCODE_VERSION="$3"

if [ ! -d "${INPUT_DIR}/Realm.xcframework" ]; then
  echo "ERROR: Realm.xcframework not found in ${INPUT_DIR}"
  exit 1
fi
if [ ! -d "${INPUT_DIR}/RealmSwift.xcframework" ]; then
  echo "ERROR: RealmSwift.xcframework not found in ${INPUT_DIR}"
  exit 1
fi

# Zip Realm (Xcode-version agnostic)
echo "Packaging Realm.spm.zip..."
cd "${INPUT_DIR}"
zip --symlinks -r "${OUTPUT_DIR}/Realm.spm.zip" Realm.xcframework
cd - > /dev/null

# Zip RealmSwift (Xcode-version specific)
REALM_SWIFT_ZIP="RealmSwift@${XCODE_VERSION}.spm.zip"
echo "Packaging ${REALM_SWIFT_ZIP}..."
cd "${INPUT_DIR}"
zip --symlinks -r "${OUTPUT_DIR}/${REALM_SWIFT_ZIP}" RealmSwift.xcframework
cd - > /dev/null

echo "=== Packaging complete ==="
