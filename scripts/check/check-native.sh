#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
cargo test
cargo build
export QT_FORCE_STDERR_LOGGING=1
export QT_QPA_PLATFORM=offscreen
export QT_QUICK_BACKEND=software
timeout 40s ./target/debug/starship-journal --smoke-test
timeout 40s ./target/debug/starship-journal --smoke-test --narrow-test
# Exercise the same native-widget-backed control style used on Windows.
QT_QUICK_CONTROLS_STYLE=org.kde.desktop timeout 40s ./target/debug/starship-journal --smoke-test --bundled-icons
QT_QUICK_CONTROLS_STYLE=org.kde.desktop timeout 40s ./target/debug/starship-journal --smoke-test --narrow-test --bundled-icons
