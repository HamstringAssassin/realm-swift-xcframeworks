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

CHECKSUMS=$(cat "${ARTIFACTS_DIR}/checksums.json")

REALM_CHECKSUM=$(echo "$CHECKSUMS" | jq -r '.["Realm.spm.zip"]')
REALM_SWIFT_FILE=$(echo "$CHECKSUMS" | jq -r 'keys[] | select(startswith("RealmSwift"))')
REALM_SWIFT_CHECKSUM=$(echo "$CHECKSUMS" | jq -r '[to_entries[] | select(.key | startswith("RealmSwift"))] | .[0].value')

RELEASE_NOTES="## ${BRANCH} branch — realm-swift ${VERSION}

**Source commit:** [\`${SHA:0:8}\`](https://github.com/realm/realm-swift/commit/${SHA})

### Checksums

\`\`\`
$(echo "$CHECKSUMS" | jq -r 'to_entries[] | "\(.key): \(.value)"')
\`\`\`

### Usage in Package.swift

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
\`\`\`"

gh release create "$TAG" \
  --title "${BRANCH} ${VERSION} (build.${BUILD_NUMBER})" \
  --notes "$RELEASE_NOTES" \
  "${ARTIFACTS_DIR}/Realm.spm.zip" \
  ${ARTIFACTS_DIR}/RealmSwift@*.spm.zip
