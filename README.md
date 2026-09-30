# Starship — The Flight Journal

A native **Rust + KDE Kirigami** app with a KDE-style flight archive, searchable mission debriefs, and a live next-flight countdown. The interface uses Kirigami navigation, system colors and fonts, standard controls, form layouts, and adaptive cards. Covers integrated Flights 1–14; early prototype hops are outside this archive.

## Run

Requires Rust, a C++ compiler, pkg-config, Qt 6 development tools (including Qt Quick, Quick Controls and Widgets), Kirigami, qqc2-desktop-style, and libjxl development files. On Arch Linux these are provided by `rust`, `gcc`, `pkgconf`, `qt6-base`, `qt6-declarative`, `kirigami`, `qqc2-desktop-style`, and `libjxl`.

For the polished KDE appearance, install `qqc2-breeze-style`, or cache the official Arch package locally with:

```sh
python scripts/prepare-native-style.py
```

The script requires pacman, curl and bsdtar. It puts KDE's unmodified Breeze QML controls and Kirigami theme plugin in `native/runtime`, without changing desktop settings. The app discovers this local runtime or the installed Breeze package automatically. The cached dependency is ignored by version control; its source URL, license and SHA-256 are recorded in `native/runtime/source.json`. Without Breeze, the app falls back to qqc2-desktop-style. `QT_QUICK_CONTROLS_STYLE` can override the app's default.

```sh
cargo run --release
```

If Qt discovery needs help, use `QMAKE=/usr/bin/qmake6 cargo run --release`. The compiled executable is `target/release/starship-journal`. Flight data and photography are bundled into the executable. Launch updates are fetched in a background Rust thread and saved atomically in Qt's platform cache directory: under `$XDG_CACHE_HOME` or `~/.cache` on Linux, and `%LOCALAPPDATA%` on Windows.

Kirigami provides the navigation, cards, dialogs and adaptive layouts. Rust handles the flight archive, filtering, schedule normalization, countdown and networking, connected to QML through CXX-Qt. The small C++ image provider decodes JPEG XL directly with the official libjxl library.

## Windows

The Windows build targets **Windows 10/11 x64** and uses [MSYS2 UCRT64](https://www.msys2.org/). Install MSYS2, open its **UCRT64** terminal, run `pacman -Syu`, and follow any instructions to restart the terminal and finish updating. Then, from this project directory:

```sh
mapfile -t packages < <(tr -d '\r' < native/windows/packages.txt)
pacman -S --needed --noconfirm "${packages[@]}"
bash scripts/build-windows.sh
```

This uses the MSYS2 Rust/GNU toolchain, runs the backend tests, and builds `target/windows/x86_64-pc-windows-gnu/release/starship-journal.exe`. It produces **`dist/Starship-Journal-windows-x64.zip`**, including Qt, Kirigami, KDE's Breeze widget style, icon theme, libjxl, and their DLL dependencies. Extract the entire ZIP and double-click `starship-journal.exe`; the end user does not need MSYS2, Rust, Qt, or KDE installed. Keep the accompanying runtime folders and DLLs beside the EXE.

Windows keeps the KDE appearance using Breeze and qqc2-desktop-style, following [KDE's Windows setup guidance](https://develop.kde.org/docs/getting-started/kirigami/platforms-windows/). The release EXE has an application icon, a Windows manifest for monitor scaling, and opens without a console window. `QT_QUICK_CONTROLS_STYLE` still overrides the default style.

The packager uses Qt's official `windeployqt` and checks the recursive DLL imports of the EXE and all runtime plugins. It fails if a dependency is missing, and includes package versions, license notices, photo credits and SHA-256 checksums.

Before compilation, the build script copies the required SDK DLLs beside MSYS2's Qt host tools and verifies that those tools run with an empty environment. This accommodates CXX-Qt's isolated tool invocations without changing or patching Rust dependencies.

To verify an extracted package from PowerShell:

```powershell
./scripts/check-windows.ps1 -PackagePath 'C:/path/to/Starship-Journal-windows-x64'
```

This checks both layouts with the SDK removed from `PATH` and Qt's import overrides, including Breeze style/icons and JPEG XL decoding. `.github/workflows/windows.yml` builds and tests the portable package on a Windows runner and uploads the ZIP and UI previews. The Windows build cannot be executed on the current Linux development machine; the workflow and PowerShell check provide the Windows validation path.

## Launch information

Mission summaries were checked against SpaceX post-flight reports on 29 September 2026. Each debrief links to the official report and replay.

The schedule reads structured launch data embedded in [NextSpaceflight's public Starship launch pages](https://nextspaceflight.com/launches/?q=Starship) on load and every ten minutes, with a manual refresh. It verifies the next numbered flight against its detail page and links directly to that launch. NextSpaceflight [does not yet offer a public launch API](https://api.nextspaceflight.com/api_access/), so this adapter depends on its website format. If a request fails or the page format changes, the last saved NextSpaceflight schedule or bundled `native/data/schedule.json` snapshot is shown. Older caches from other providers are discarded.

The app displays tentative day/month/quarter/year windows without starting a countdown. Only a precise minute/second time with Go status and a confirmed liftoff time starts ticking; holds, scrubs and withdrawn windows clear it. Checked on 30 September 2026, [Flight 15](https://nextspaceflight.com/launches/details/8403/) is listed as NET October 2026 with no exact launch time. Flight history remains curated from SpaceX mission reports and needs editorial updates after future flights.

## Photography and JPEG XL

13 selected photographs (12 mission cards plus the hero) were downloaded **using gallery-dl** from [Max Evans's SmugMug](https://maxevans.smugmug.com/Rockets). His public gallery had no dedicated Flight 4 or 7 albums, so those two use credited SpaceX photography. Source URLs are recorded in `assets/selection.json` and `native/data/photos.json`.

- `assets/originals/`: JPEG downloads at the largest publicly available size.
- `assets/jxl/`: losslessly recompressed archival JPEG XL files.
- `native/assets/photos/`: resized JPEG XL photographs and JPEG fallbacks.
- `native/assets/images/`: credited SpaceX photographs for Flights 4 and 7.
- `assets/conversion-report.json`: source URLs, original SHA-256 checksums, and size comparisons.

All JPEG XL encoding uses **cjxl 0.12.0**, from the official [libjxl reference implementation](https://github.com/libjxl/libjxl). All 13 archival files were decoded with `djxl` and verified to reconstruct the exact original JPEG bytes. The native app decodes its bundled JPEG XL photographs using libjxl, with JPEG fallbacks for image errors.

To reproduce downloads and conversion (requires gallery-dl, ImageMagick, cjxl and djxl):

```sh
python scripts/prepare-photos.py
```

Photographs remain the property of their credited photographers; no license or ownership transfer is implied.

## Verification

Native backend tests and interactive QML smoke checks:

```sh
cargo test
# Optional check against the live website:
cargo test live_nextspaceflight_schedule -- --ignored --nocapture
cargo build
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software ./target/debug/starship-journal --smoke-test
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software ./target/debug/starship-journal --smoke-test --narrow-test
```

The smoke checks exercise the actual search and year controls, mission and navigation pages, and all 14 JPEG XL mission cards. They save `starship-kirigami-*.png` previews in the platform temporary directory (`/tmp` on Linux), then exit with a success or failure status. Set `STARSHIP_TEST_OUTPUT_DIR` to choose a different screenshot directory. The Windows verification script saves screenshots and logs in `target/windows-smoke-tests`. Use `QT_FORCE_STDERR_LOGGING=1` to print Qt diagnostics.

Packaging dependency checks run on either platform:

```sh
python -m unittest discover -s scripts/tests -v
```
