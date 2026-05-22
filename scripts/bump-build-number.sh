#!/bin/bash
set -euo pipefail

# Usage: bash scripts/bump-build-number.sh <branch> <new_build_number>
# Updates upstream.json and commits with [skip ci]

BRANCH="$1"
NEW_BUILD_NUM="$2"

jq --arg b "$BRANCH" --arg bn "$NEW_BUILD_NUM" \
  '.branches[$b].build_number = ($bn | tonumber)' \
  config/upstream.json > config/upstream.json.tmp
mv config/upstream.json.tmp config/upstream.json

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add config/upstream.json
git commit -m "build: bump ${BRANCH} build number to ${NEW_BUILD_NUM} [skip ci]"
git push
