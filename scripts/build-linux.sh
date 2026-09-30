#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export QMAKE=/usr/bin/qmake6
cargo test --release --locked
cargo build --release --locked
python3 scripts/package-linux.py
