#!/bin/bash
set -euo pipefail

# Usage: bash scripts/create-release.sh <branch> <version> <sha> <tag> <build_number> <artifacts_dir> <repo>
# Creates a GitHub Release with xcframework artifacts

BRANCH="$1"
VERSION="$2"
SHA="$3"
TAG="$4"
BUILD_NUMBER="$5"
ARTIFACTS_DIR="$6"
REPO="$7"

# Checksums come from the files that are published.
checksum() { shasum -a 256 "$1" | cut -d ' ' -f 1; }

REALM_CHECKSUM=$(checksum "${ARTIFACTS_DIR}/Realm.spm.zip")
CHECKSUM_LINES="Realm.spm.zip: ${REALM_CHECKSUM}"
USAGE=""

for zip in "${ARTIFACTS_DIR}"/RealmSwift@*.spm.zip; do
  REALM_SWIFT_FILE=$(basename "$zip")
  REALM_SWIFT_CHECKSUM=$(checksum "$zip")
  XCODE_VERSION=${REALM_SWIFT_FILE#RealmSwift@}
  XCODE_VERSION=${XCODE_VERSION%.spm.zip}
  CHECKSUM_LINES+=$'\n'"${REALM_SWIFT_FILE}: ${REALM_SWIFT_CHECKSUM}"
  USAGE+="
#### Xcode ${XCODE_VERSION}

\`\`\`swift
.binaryTarget(
    name: \"Realm\",
    url: \"https://github.com/${REPO}/releases/download/${TAG}/Realm.spm.zip\",
    checksum: \"${REALM_CHECKSUM}\"
),
.binaryTarget(
    name: \"RealmSwift\",
    url: \"https://github.com/${REPO}/releases/download/${TAG}/${REALM_SWIFT_FILE}\",
    checksum: \"${REALM_SWIFT_CHECKSUM}\"
),
\`\`\`
"
done

RELEASE_NOTES="## ${BRANCH} branch — realm-swift ${VERSION}

**Source commit:** [\`${SHA:0:8}\`](https://github.com/realm/realm-swift/commit/${SHA})

### Checksums

\`\`\`
${CHECKSUM_LINES}
\`\`\`

### Usage in Package.swift
${USAGE}"

gh release create "$TAG" \
  --title "${BRANCH} ${VERSION} (build.${BUILD_NUMBER})" \
  --notes "$RELEASE_NOTES" \
  "${ARTIFACTS_DIR}/Realm.spm.zip" \
  "${ARTIFACTS_DIR}"/RealmSwift@*.spm.zip
