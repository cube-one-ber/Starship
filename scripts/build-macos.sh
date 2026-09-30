#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
brew_prefix=$(brew --prefix)
export QMAKE="$brew_prefix/bin/qmake"
export MACOSX_DEPLOYMENT_TARGET=14.0
export STARSHIP_KDE_PREFIX="$PWD/target/macos-sdk"
export CMAKE_PREFIX_PATH="$STARSHIP_KDE_PREFIX:$brew_prefix"
export PKG_CONFIG_PATH="$(brew --prefix jpeg-xl)/lib/pkgconfig:$brew_prefix/lib/pkgconfig"
export QML_IMPORT_PATH="$STARSHIP_KDE_PREFIX/qml:$brew_prefix/share/qt/qml"
export QT_PLUGIN_PATH="$STARSHIP_KDE_PREFIX/plugins:$brew_prefix/share/qt/plugins"
version=6.30.0
mkdir -p target/macos-sources
for module in extra-cmake-modules kconfig kirigami sonnet qqc2-desktop-style breeze-icons; do
  source_dir="$PWD/target/macos-sources/$module"
  curl --fail --location --retry 3 "https://download.kde.org/stable/frameworks/6.30/$module-$version.tar.xz" -o "target/macos-sources/$module.tar.xz"
  mkdir -p "$source_dir"
  tar -xf "target/macos-sources/$module.tar.xz" --strip-components=1 -C "$source_dir"
  cmake -S "$source_dir" -B "$source_dir/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$STARSHIP_KDE_PREFIX" \
    -DCMAKE_PREFIX_PATH="$STARSHIP_KDE_PREFIX;$brew_prefix" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 -DBUILD_TESTING=OFF -DBUILD_QCH=OFF \
    -DBUILD_DOCS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_DESIGNERPLUGIN=OFF -DUSE_DBUS=OFF \
    -DKDE_INSTALL_USE_QT_SYS_PATHS=OFF -DKDE_INSTALL_LIBDIR=lib \
    -DKDE_INSTALL_QMLDIR="$STARSHIP_KDE_PREFIX/qml" \
    -DKDE_INSTALL_PLUGINDIR="$STARSHIP_KDE_PREFIX/plugins" \
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6IconThemes=ON \
    -DCMAKE_DISABLE_FIND_PACKAGE_KF6ColorScheme=ON \
    -DSONNET_NO_BACKENDS=ON -DWITH_ICON_GENERATION=OFF \
    -DBINARY_ICONS_RESOURCE=ON -DWITH_ICONS_LIBRARY=ON -DSKIP_INSTALL_ICONS=ON
  cmake --build "$source_dir/build" --parallel 3
  cmake --install "$source_dir/build"
done
cargo test --release --locked
cargo build --release --locked
python3 scripts/package-macos.py
