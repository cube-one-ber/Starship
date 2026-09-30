#!/usr/bin/env bash
# Publish only the portable ZIP produced by the successful Windows build job.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${GITHUB_SHA:?Missing build commit}"
: "${GITHUB_REPOSITORY:?Missing repository}"
: "${GITHUB_RUN_ID:?Missing workflow run}"
: "${GITHUB_REF_NAME:?Missing branch}"
[[ "$GITHUB_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid build commit' >&2; exit 1; }

archive=dist/Starship-Journal-windows-x64.zip
test -s "$archive"
tag="build-$GITHUB_SHA"
short_sha="${GITHUB_SHA:0:7}"
notes=$(mktemp)
trap 'rm -f "$notes"' EXIT
(
  cd dist
  sha256sum Starship-Journal-windows-x64.zip > SHA256SUMS.txt
)
cat > "$notes" <<EOF
Automated prerelease for commit [$short_sha](https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA) on \`$GITHUB_REF_NAME\`.

Windows 10/11 x64: extract **Starship-Journal-windows-x64.zip** and run **starship-journal.exe**. Qt, KDE Breeze, Kirigami, and JPEG XL dependencies are included.

Backend tests and the desktop/narrow portable-app checks passed before publication. Screenshots and diagnostics are available in the [build run](https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID).

This is a development build. SHA256SUMS.txt contains the ZIP checksum.
EOF

if gh release view "$tag" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
  # Rerunning a successful commit refreshes its assets instead of duplicating releases.
  gh release upload "$tag" "$archive" dist/SHA256SUMS.txt --clobber --repo "$GITHUB_REPOSITORY"
else
  gh release create "$tag" "$archive" dist/SHA256SUMS.txt \
    --repo "$GITHUB_REPOSITORY" --target "$GITHUB_SHA" \
    --title "Development build $short_sha" --prerelease --latest=false \
    --notes-file "$notes"
fi
