#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if [[ "${MSYSTEM:-}" != UCRT64 ]]; then
    echo 'Open the MSYS2 UCRT64 terminal to build the Windows app.' >&2
    exit 1
fi

# Use the native UCRT64 tools rather than an unrelated rustup/MSVC installation.
export PATH="$MINGW_PREFIX/bin:/usr/bin:$PATH"
export QMAKE="$(cygpath -m "$MINGW_PREFIX/bin/qmake6.exe")"
export CC="$(cygpath -m "$MINGW_PREFIX/bin/gcc.exe")"
export CXX="$(cygpath -m "$MINGW_PREFIX/bin/g++.exe")"
export AR="$(cygpath -m "$MINGW_PREFIX/bin/ar.exe")"
export WINDRES="$(cygpath -m "$MINGW_PREFIX/bin/windres.exe")"
export PKG_CONFIG="$(cygpath -m "$MINGW_PREFIX/bin/pkgconf.exe")"
export PKG_CONFIG_PATH="$(cygpath -m "$MINGW_PREFIX/lib/pkgconfig")"
export CARGO_TARGET_DIR="$(cygpath -m "$PWD/target/windows")"
export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER="$CC"
rust_info=$("$MINGW_PREFIX/bin/rustc.exe" -vV)
[[ "$rust_info" == *'host: x86_64-pc-windows-gnu'* ]] || { echo 'Install the UCRT64 Rust package.' >&2; exit 1; }
"$MINGW_PREFIX/bin/cargo.exe" test --locked --target x86_64-pc-windows-gnu
"$MINGW_PREFIX/bin/cargo.exe" build --release --locked --target x86_64-pc-windows-gnu
"$MINGW_PREFIX/bin/python.exe" scripts/package-windows.py --exe target/windows/x86_64-pc-windows-gnu/release/starship-journal.exe
