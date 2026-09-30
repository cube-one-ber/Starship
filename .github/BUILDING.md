# Automatic prerelease builds

Every branch push runs Windows, Linux, and macOS builds and publishes a prerelease for its tip commit after all backend, packaging, and portable UI checks pass on all three platforms. There are no path filters or automatic cancellations, so documentation commits also build. Pull requests run the checks without publishing releases.

Download packages from [Releases](https://github.com/cube-one-ber/Starship/releases):

| Platform | Formats | Minimum runtime |
| --- | --- | --- |
| Windows x64 | Portable ZIP | Windows 10/11 |
| Linux x86_64 | AppImage, tar.gz, DEB, RPM | glibc 2.41 (Debian 13+, Ubuntu 25.04+, Fedora 42+) |
| macOS Apple Silicon | DMG, app bundle ZIP | macOS 14+ |

Qt, Kirigami, icons, and JPEG XL runtime dependencies are bundled. Each release includes `SHA256SUMS.txt` for every download. Windows runs `starship-journal.exe`; Linux's portable archive runs `AppRun`; macOS's DMG installs by dragging the app to Applications. The macOS development builds have an ad-hoc signature and are not Apple-notarized.

Packaged UI checks use a 1600×1000 desktop window and a 420×880 narrow window. Fixed dimensions exercise the same layouts despite different platform font metrics.

Linux builds in a Debian 13 container. `scripts/build-linux.sh` and `scripts/package-linux.py` build all four formats, extract each package, and test both layouts. AppImage tests use extraction so they do not require FUSE in CI. The DEB and RPM install the bundled runtime under `/opt/starship-journal` with a desktop entry and command launcher.

macOS builds on an Apple Silicon runner with Homebrew Qt and libjxl, plus pinned official KDE Frameworks 6.30.0 sources. `scripts/build-macos.sh` builds those KDE dependencies; `scripts/package-macos.py` uses official `macdeployqt`, signs the bundled code, creates ZIP/DMG, and tests both the extracted ZIP and the mounted DMG.

Releases use `build-<full commit SHA>` tags and link to the exact source commit and its workflow run. Rerunning a commit refreshes its release assets. Manual branch runs also publish a prerelease. Prereleases do not replace stable releases as GitHub's latest release.

The build jobs have read-only repository access. Only the publication job receives `contents: write`, and it runs after every build succeeds. GitHub's built-in token handles publication; no personal token or additional repository secret is needed.

The workflow is `.github/workflows/windows.yml`; publication is handled by `scripts/publish-prerelease.sh`.
