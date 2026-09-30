#!/usr/bin/env bash
# Publish the packages produced by all successful platform build jobs.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${GITHUB_SHA:?Missing build commit}"
: "${GITHUB_REPOSITORY:?Missing repository}"
: "${GITHUB_RUN_ID:?Missing workflow run}"
: "${GITHUB_REF_NAME:?Missing branch}"
[[ "$GITHUB_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid build commit' >&2; exit 1; }

assets=(
  dist/Starship-Journal-windows-x64.zip
  dist/Starship-Journal-linux-x86_64.AppImage
  dist/Starship-Journal-linux-x86_64.tar.gz
  dist/Starship-Journal-linux-x86_64.deb
  dist/Starship-Journal-linux-x86_64.rpm
  dist/Starship-Journal-macos-arm64.zip
  dist/Starship-Journal-macos-arm64.dmg
  dist/Starship-Journal-macos-arm64.json
)
for asset in "${assets[@]}"; do test -s "$asset"; done
macos_minimum=$(python3 -c 'import json; print(json.load(open("dist/Starship-Journal-macos-arm64.json"))["minimum_macos"])')
[[ "$macos_minimum" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || { echo 'Invalid macOS compatibility metadata' >&2; exit 1; }
tag="build-$GITHUB_SHA"
short_sha="${GITHUB_SHA:0:7}"
notes=$(mktemp)
trap 'rm -f "$notes"' EXIT
(
  cd dist
  sha256sum Starship-Journal-* > SHA256SUMS.txt
)
cat > "$notes" <<EOF
Automated prerelease for commit [$short_sha](https://github.com/$GITHUB_REPOSITORY/commit/$GITHUB_SHA) on \`$GITHUB_REF_NAME\`.

Windows 10/11 x64: extract **Starship-Journal-windows-x64.zip** and run **starship-journal.exe**. Qt, KDE Breeze, Kirigami, and JPEG XL dependencies are included.

Linux x86_64: choose the **AppImage**, portable **tar.gz**, **DEB**, or **RPM**. The bundled runtime requires glibc 2.41 or newer (Debian 13+, Ubuntu 25.04+, Fedora 42+). For the AppImage, make it executable and launch it; use **--appimage-extract-and-run** if FUSE is unavailable. For the tarball, extract and run **AppRun**.

macOS $macos_minimum+ Apple Silicon: open the **DMG** and drag **Starship Journal.app** to Applications, or extract the **ZIP**. The development app is ad-hoc signed, not Apple-notarized; macOS may require allowing it in Privacy & Security. The compatibility JSON records the requirements of this build.

All three platform builds, backend tests, and desktop/narrow packaged-app checks passed before publication. Screenshots and diagnostics are available in the [build run](https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID).

This is a development build. SHA256SUMS.txt contains checksums for every package.
EOF

if gh release view "$tag" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
  # Rerunning a successful commit refreshes its assets instead of duplicating releases.
  gh release upload "$tag" "${assets[@]}" dist/SHA256SUMS.txt --clobber --repo "$GITHUB_REPOSITORY"
else
  gh release create "$tag" "${assets[@]}" dist/SHA256SUMS.txt \
    --repo "$GITHUB_REPOSITORY" --target "$GITHUB_SHA" \
    --title "Development build $short_sha" --prerelease --latest=false \
    --notes-file "$notes"
fi
