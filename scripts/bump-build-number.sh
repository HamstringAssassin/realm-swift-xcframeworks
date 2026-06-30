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

# Parallel release jobs (community + master) both push to main. Retry with
# rebase to survive non-fast-forward rejections from a racing job.
for attempt in 1 2 3 4 5; do
  if git push origin HEAD:main; then
    exit 0
  fi
  echo "push rejected (attempt ${attempt}) — rebasing onto latest main"
  git fetch origin main
  git rebase origin/main
done

echo "ERROR: push failed after 5 attempts" >&2
exit 1
