# Automatic prerelease builds

Every branch push runs the Windows build and publishes a prerelease for its tip commit after all backend, packaging, and portable UI checks pass. There are no path filters or automatic cancellations, so documentation commits also build. Pull requests run the checks without publishing releases.

Download the portable Windows ZIP from [Releases](https://github.com/cube-one-ber/Starship/releases). Extract the whole folder and run `starship-journal.exe`. Each release includes `SHA256SUMS.txt` for the ZIP.

Releases use `build-<full commit SHA>` tags and link to the exact source commit and its workflow run. Rerunning a commit refreshes its release assets. Manual branch runs also publish a prerelease. Prereleases do not replace stable releases as GitHub's latest release.

The build job has read-only repository access. Only the publication job receives `contents: write`, and it runs after the Windows job succeeds. GitHub's built-in token handles publication; no personal token or additional repository secret is needed.

The workflow is `.github/workflows/windows.yml`; publication is handled by `scripts/publish-prerelease.sh`.
