#!/usr/bin/env python3
"""Create a bundled Linux runtime, AppImage, tarball, DEB, and RPM."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / 'dist'
STAGE = ROOT / 'target/linux-package'
APP = STAGE / 'Starship-Journal.AppDir'
EXCLUDED = re.compile(r'^(?:ld-linux|lib(?:c|m|dl|pthread|rt|resolv|util|nss_[^.]*)\.so)')


def run(*command, **kwargs):
    subprocess.run([str(value) for value in command], check=True, **kwargs)


def copy(source, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)


def elf(path):
    with path.open('rb') as file:
        return file.read(4) == b'\x7fELF'


def dependencies():
    pending = [path for path in APP.rglob('*') if path.is_file() and elf(path)]
    visited = set()
    while pending:
        binary = pending.pop()
        if binary in visited:
            continue
        visited.add(binary)
        output = subprocess.check_output(['ldd', str(binary)], text=True)
        if 'not found' in output:
            raise RuntimeError(f'Unresolved runtime dependency in {binary}:\n{output}')
        for name, source in re.findall(r'^\s*(\S+) => (/\S+) ', output, re.MULTILINE):
            if EXCLUDED.match(name):
                continue
            destination = APP / 'usr/lib' / name
            if not destination.exists():
                copy(Path(source), destination)
                pending.append(destination)
    for binary in visited:
        # Prevent absolute SDK paths from taking precedence over the bundled runtime.
        run('patchelf', '--remove-rpath', binary)


def check(executable, name):
    run('python3', ROOT / 'scripts/check-portable.py', executable,
        '--output', ROOT / 'target/linux-smoke-tests' / name)


def main():
    DIST.mkdir(exist_ok=True)
    shutil.rmtree(STAGE, ignore_errors=True)
    APP.mkdir(parents=True)
    qt_qml = Path(subprocess.check_output(['qmake6', '-query', 'QT_INSTALL_QML'], text=True).strip())
    qt_plugins = Path(subprocess.check_output(['qmake6', '-query', 'QT_INSTALL_PLUGINS'], text=True).strip())
    copy(ROOT / 'target/release/starship-journal', APP / 'usr/bin/starship-journal')
    shutil.copytree(qt_qml, APP / 'usr/qml', symlinks=False)
    for group in ('platforms', 'imageformats', 'iconengines', 'xcbglintegrations',
                  'wayland-graphics-integration-client', 'wayland-shell-integration',
                  'styles', 'kf6/kirigami/platform', 'kiconthemes6/iconengines'):
        if (qt_plugins / group).is_dir():
            shutil.copytree(qt_plugins / group, APP / 'usr/plugins' / group, symlinks=False)
    shutil.copytree('/usr/share/icons/breeze', APP / 'usr/share/icons/breeze', symlinks=False)
    copy(ROOT / 'native/assets/icon.svg', APP / 'org.starship.journal.svg')
    copy(ROOT / 'native/assets/icon.svg', APP / 'usr/share/icons/hicolor/scalable/apps/org.starship.journal.svg')
    copy(ROOT / 'native/linux/org.starship.journal.desktop', APP / 'org.starship.journal.desktop')
    copy(ROOT / 'native/linux/org.starship.journal.desktop', APP / 'usr/share/applications/org.starship.journal.desktop')
    (APP / 'usr/bin/qt.conf').write_text('[Paths]\nPrefix=..\nPlugins=plugins\nQmlImports=qml\n')
    (APP / 'AppRun').write_text('''#!/bin/sh
set -eu
app_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export LD_LIBRARY_PATH="$app_dir/usr/lib"
export QT_PLUGIN_PATH="$app_dir/usr/plugins"
export QML_IMPORT_PATH="$app_dir/usr/qml"
export QML2_IMPORT_PATH="$app_dir/usr/qml"
export XDG_DATA_DIRS="$app_dir/usr/share:/usr/local/share:/usr/share"
exec "$app_dir/usr/bin/starship-journal" "$@"
''')
    (APP / 'AppRun').chmod(0o755)
    dependencies()
    copy(ROOT / 'native/data/photos.json', APP / 'photo-credits.json')
    (APP / 'runtime-packages.txt').write_text(subprocess.check_output(['dpkg-query', '-W'], text=True))
    notices = APP / 'licenses'
    notices.mkdir()
    for directory in Path('/usr/share/doc').iterdir():
        if (directory / 'copyright').is_file():
            copy(directory / 'copyright', notices / f'{directory.name}.copyright')
    (APP / 'README.txt').write_text('Starship Journal — Linux x86_64\nRun ./AppRun. Requires glibc 2.41 or newer (Debian 13+, Ubuntu 25.04+, Fedora 42+).\nQt, KDE, and libjxl are bundled. Package versions and copyright notices accompany the app.\nDependency sources: https://sources.debian.org/\nPhotographs remain their credited creators’ property.\n')
    check(APP / 'AppRun', 'portable')
    with tarfile.open(DIST / 'Starship-Journal-linux-x86_64.tar.gz', 'w:gz') as archive:
        archive.add(APP, arcname='Starship-Journal-linux-x86_64')
    with tempfile.TemporaryDirectory(prefix='Starship extracted 🛰 ') as work:
        with tarfile.open(DIST / 'Starship-Journal-linux-x86_64.tar.gz') as archive:
            archive.extractall(work, filter='data')
        check(Path(work) / 'Starship-Journal-linux-x86_64/AppRun', 'tarball')
    tool = STAGE / 'appimagetool.AppImage'
    run('curl', '--fail', '--location', '--retry', '3', '-o', tool,
        'https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage')
    assert hashlib.sha256(tool.read_bytes()).hexdigest() == 'ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0'
    tool.chmod(0o755)
    env = dict(os.environ, ARCH='x86_64', APPIMAGE_EXTRACT_AND_RUN='1')
    appimage = DIST / 'Starship-Journal-linux-x86_64.AppImage'
    run(tool, '--no-appstream', APP, appimage, env=env)
    # Verify the actual release image, using extraction rather than requiring FUSE in CI.
    run(appimage, '--appimage-extract', cwd=STAGE)
    check(STAGE / 'squashfs-root/AppRun', 'appimage')
    version = json.loads(subprocess.check_output(['cargo', 'metadata', '--no-deps', '--format-version', '1'], text=True))['packages'][0]['version']
    package_root = STAGE / 'installed'
    shutil.copytree(APP, package_root / 'opt/starship-journal', symlinks=True)
    (package_root / 'usr/bin').mkdir(parents=True)
    launcher = package_root / 'usr/bin/starship-journal'
    launcher.write_text('#!/bin/sh\nexec /opt/starship-journal/AppRun "$@"\n')
    launcher.chmod(0o755)
    copy(ROOT / 'native/linux/org.starship.journal.desktop', package_root / 'usr/share/applications/org.starship.journal.desktop')
    copy(ROOT / 'native/assets/icon.svg', package_root / 'usr/share/icons/hicolor/scalable/apps/org.starship.journal.svg')
    deb = STAGE / 'deb'
    shutil.copytree(package_root, deb, symlinks=True)
    (deb / 'DEBIAN').mkdir()
    (deb / 'DEBIAN/control').write_text(f'Package: starship-journal\nVersion: {version}\nArchitecture: amd64\nMaintainer: Starship Journal <cube-one-ber@users.noreply.github.com>\nDepends: libc6 (>= 2.41)\nSection: education\nPriority: optional\nDescription: Starship flight history and countdowns with a bundled KDE runtime\n')
    run('dpkg-deb', '--root-owner-group', '--build', deb, DIST / 'Starship-Journal-linux-x86_64.deb')
    extracted = STAGE / 'deb-extracted'
    run('dpkg-deb', '--extract', DIST / 'Starship-Journal-linux-x86_64.deb', extracted)
    check(extracted / 'opt/starship-journal/AppRun', 'deb')
    rpm = STAGE / 'rpmbuild'
    for directory in ('BUILD', 'BUILDROOT', 'RPMS', 'SOURCES', 'SPECS', 'SRPMS'):
        (rpm / directory).mkdir(parents=True)
    spec = rpm / 'SPECS/starship.spec'
    spec.write_text(f'''Name: starship-journal
Version: {version}
Release: 1
Summary: Starship flight journal
License: LicenseRef-Proprietary
AutoReqProv: no
Requires: glibc >= 2.41
%description
Starship flight history and countdowns with bundled Qt, KDE, and JPEG XL.
Dependency copyright notices and photo credits accompany the runtime.
%install
mkdir -p %{{buildroot}}
cp -a {package_root}/. %{{buildroot}}/
%files
/opt/starship-journal
/usr/bin/starship-journal
/usr/share/applications/org.starship.journal.desktop
/usr/share/icons/hicolor/scalable/apps/org.starship.journal.svg
''')
    run('rpmbuild', '--define', f'_topdir {rpm}', '--define', '__os_install_post %{nil}', '-bb', spec)
    output = next((rpm / 'RPMS').rglob('*.rpm'))
    copy(output, DIST / 'Starship-Journal-linux-x86_64.rpm')
    rpm_extract = STAGE / 'rpm-extracted'
    rpm_extract.mkdir()
    # bsdtar can unpack RPM payloads without installing into the CI host.
    run('bsdtar', '-xf', DIST / 'Starship-Journal-linux-x86_64.rpm', '-C', rpm_extract)
    check(rpm_extract / 'opt/starship-journal/AppRun', 'rpm')


if __name__ == '__main__':
    main()
