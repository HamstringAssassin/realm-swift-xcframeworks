#!/bin/bash
set -euo pipefail

# Usage: bash scripts/detect-changes.sh
# Outputs a GitHub Actions matrix JSON to stdout
# Must be run in a git repo with fetch-depth >= 2

XCODE_VERSIONS=$(jq -c '[.versions[]]' config/xcode-versions.json)

# Determine which branches changed
CHANGED_BRANCHES=$(diff <(git show "HEAD~1:config/upstream.json" 2>/dev/null | jq -r '.branches | to_entries[] | "\(.key)=\(.value.last_built_sha)"' | sort) \
                        <(jq -r '.branches | to_entries[] | "\(.key)=\(.value.last_built_sha)"' config/upstream.json | sort) \
                        | grep '^>' | sed 's/^> //' | cut -d= -f1 || true)

# If xcode-versions.json changed, rebuild all branches
if git diff HEAD~1 --name-only 2>/dev/null | grep -q 'config/xcode-versions.json'; then
  CHANGED_BRANCHES=$(jq -r '.branches | keys[]' config/upstream.json)
fi

# If no branches detected, build all
if [ -z "$CHANGED_BRANCHES" ]; then
  CHANGED_BRANCHES=$(jq -r '.branches | keys[]' config/upstream.json)
fi

MATRIX_ENTRIES="[]"
for branch in $CHANGED_BRANCHES; do
  SHA=$(jq -r --arg b "$branch" '.branches[$b].last_built_sha' config/upstream.json)
  VERSION=$(jq -r --arg b "$branch" '.branches[$b].last_built_version' config/upstream.json)
  BUILD_NUM=$(jq -r --arg b "$branch" '.branches[$b].build_number' config/upstream.json)

  if [ -z "$SHA" ] || [ "$SHA" = "" ]; then
    echo "Skipping ${branch}: no SHA configured" >&2
    continue
  fi

  for xcode in $(echo "$XCODE_VERSIONS" | jq -r '.[].version'); do
    APP=$(echo "$XCODE_VERSIONS" | jq -r --arg v "$xcode" '.[] | select(.version == $v) | .app')
    MATRIX_ENTRIES=$(echo "$MATRIX_ENTRIES" | jq -c --arg b "$branch" --arg s "$SHA" \
      --arg v "$VERSION" --arg bn "$BUILD_NUM" --arg xv "$xcode" --arg xa "$APP" \
      '. + [{"branch": $b, "sha": $s, "version": $v, "build_number": ($bn | tonumber), "xcode_version": $xv, "xcode_app": $xa}]')
  done
done

if [ "$MATRIX_ENTRIES" = "[]" ]; then
  echo "No builds needed" >&2
  echo '{"include":[]}'
else
  echo "{\"include\":${MATRIX_ENTRIES}}"
fi
