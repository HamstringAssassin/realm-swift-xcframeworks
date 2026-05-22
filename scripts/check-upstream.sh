#!/bin/bash
set -euo pipefail

# Usage: ./scripts/check-upstream.sh <branch> <last_built_sha>
# Outputs JSON: {"has_update": true/false, "sha": "...", "version": "...", "compare_url": "..."}

BRANCH="$1"
LAST_BUILT_SHA="$2"
UPSTREAM_REPO="realm/realm-swift"

HEAD_SHA=$(gh api "repos/${UPSTREAM_REPO}/commits/${BRANCH}" --jq '.sha')

if [ "$HEAD_SHA" = "$LAST_BUILT_SHA" ]; then
  echo "{\"has_update\": false}"
  exit 0
fi

# Extract version from dependencies.list on that branch
VERSION=$(gh api "repos/${UPSTREAM_REPO}/contents/dependencies.list?ref=${BRANCH}" \
  --jq '.content' | base64 -d | sed -n 's/^VERSION=\(.*\)$/\1/p')

if [ -z "$VERSION" ]; then
  VERSION="unknown"
fi

# Build compare URL
COMPARE_URL=""
if [ -n "$LAST_BUILT_SHA" ]; then
  COMPARE_URL="https://github.com/${UPSTREAM_REPO}/compare/${LAST_BUILT_SHA}...${HEAD_SHA}"
fi

echo "{\"has_update\": true, \"sha\": \"${HEAD_SHA}\", \"version\": \"${VERSION}\", \"compare_url\": \"${COMPARE_URL}\"}"
