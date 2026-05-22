#!/bin/bash
set -euo pipefail

# Usage: bash scripts/open-pr.sh <branch> <result_json> <token> <repo>
# Creates a PR to update upstream.json with new SHA/version

BRANCH="$1"
RESULT="$2"
TOKEN="$3"
REPO="$4"

NEW_SHA=$(echo "$RESULT" | jq -r '.sha')
VERSION=$(echo "$RESULT" | jq -r '.version')
COMPARE_URL=$(echo "$RESULT" | jq -r '.compare_url')
PR_BRANCH="update/${BRANCH}-${NEW_SHA:0:8}"

# Check if PR already exists for this SHA
EXISTING=$(gh pr list --head "$PR_BRANCH" --json number --jq 'length')
if [ "$EXISTING" != "0" ]; then
  echo "PR already exists for ${PR_BRANCH}, skipping"
  exit 0
fi

# Delete stale remote branch if it exists (from a previous failed run)
if git ls-remote --exit-code --heads origin "$PR_BRANCH" > /dev/null 2>&1; then
  git push origin --delete "$PR_BRANCH"
fi

git config user.name "realm-xcframework-bot[bot]"
git config user.email "realm-xcframework-bot[bot]@users.noreply.github.com"
git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${REPO}.git"
git checkout -b "$PR_BRANCH"

jq --arg branch "$BRANCH" \
   --arg sha "$NEW_SHA" \
   --arg version "$VERSION" \
   '.branches[$branch].last_built_sha = $sha | .branches[$branch].last_built_version = $version' \
   config/upstream.json > config/upstream.json.tmp
mv config/upstream.json.tmp config/upstream.json

git add config/upstream.json
git commit -m "build: update ${BRANCH} to ${VERSION} (${NEW_SHA:0:8})"
git push origin "$PR_BRANCH"

PR_BODY="## ${BRANCH} branch update

**Version:** ${VERSION}
**Commit:** [\`${NEW_SHA:0:8}\`](https://github.com/realm/realm-swift/commit/${NEW_SHA})"

if [ -n "$COMPARE_URL" ] && [ "$COMPARE_URL" != "null" ]; then
  PR_BODY="${PR_BODY}
**Changes:** [View diff](${COMPARE_URL})"
fi

PR_BODY="${PR_BODY}

Merging this PR will trigger the build workflow to produce new xcframework artifacts."

gh pr create \
  --title "build(${BRANCH}): update to ${VERSION} (${NEW_SHA:0:8})" \
  --body "$PR_BODY" \
  --base main
