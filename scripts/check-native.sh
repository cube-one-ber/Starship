#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
cargo test
cargo build
export QT_FORCE_STDERR_LOGGING=1
export QT_QPA_PLATFORM=offscreen
export QT_QUICK_BACKEND=software
timeout 30s ./target/debug/starship-journal --smoke-test
timeout 30s ./target/debug/starship-journal --smoke-test --narrow-test
