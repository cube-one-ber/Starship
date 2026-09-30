#!/usr/bin/env python3
"""Use Qt's macdeployqt to bundle and test the macOS app, then create ZIP/DMG."""
import json
import os
from pathlib import Path
import plistlib
import re
import shlex
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SDK = Path(os.environ['STARSHIP_KDE_PREFIX'])
DIST = ROOT / 'dist'
STAGE = ROOT / 'target/macos-package'
APP = STAGE / 'Starship Journal.app'


def run(*command, **kwargs):
    print('Running:', ' '.join(str(value) for value in command), flush=True)
    subprocess.run([str(value) for value in command], check=True, timeout=300, **kwargs)


def main():
    DIST.mkdir(exist_ok=True)
    shutil.rmtree(STAGE, ignore_errors=True)
    (APP / 'Contents/MacOS').mkdir(parents=True)
    resources = APP / 'Contents/Resources'
    resources.mkdir()
    shutil.copy2(ROOT / 'target/release/starship-journal', APP / 'Contents/MacOS/starship-journal')
    version = json.loads(subprocess.check_output(['cargo', 'metadata', '--no-deps', '--format-version', '1'], text=True))['packages'][0]['version']
    info = {'CFBundleName': 'Starship Journal', 'CFBundleDisplayName': 'Starship Journal',
            'CFBundleIdentifier': 'org.starship.journal', 'CFBundleExecutable': 'starship-journal',
            'CFBundlePackageType': 'APPL', 'CFBundleShortVersionString': version,
            'CFBundleVersion': version, 'LSMinimumSystemVersion': '14.0',
            'NSHighResolutionCapable': True, 'CFBundleIconFile': 'Starship.icns'}
    with (APP / 'Contents/Info.plist').open('wb') as file:
        plistlib.dump(info, file)
    # Qt's renderer runs without Quick Look's desktop thumbnail service.
    brew = Path(subprocess.check_output(['brew', '--prefix'], text=True).strip())
    flags = shlex.split(subprocess.check_output(
        ['pkg-config', '--cflags', '--libs', 'Qt6Gui', 'Qt6Svg'], text=True))
    renderer = STAGE / 'render-icon'
    run('clang++', '-std=c++17', ROOT / 'native/macos/render-icon.cpp', '-o', renderer,
        *flags, f'-Wl,-rpath,{brew / "lib"}')
    run(renderer, ROOT / 'native/assets/icon.svg', STAGE / 'icon.svg.png')
    iconset = STAGE / 'Starship.iconset'
    iconset.mkdir()
    for size in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            suffix = '@2x' if scale == 2 else ''
            run('sips', '-z', size * scale, size * scale, STAGE / 'icon.svg.png',
                '--out', iconset / f'icon_{size}x{size}{suffix}.png')
    run('iconutil', '-c', 'icns', iconset, '-o', resources / 'Starship.icns')
    scan = STAGE / 'qml-scan'
    shutil.copytree(ROOT / 'native/qml', scan)
    (scan / 'Deployment.qml').write_text('import QtQuick\nimport QtQuick.Controls.Basic\nimport org.kde.desktop\nimport org.kde.sonnet\nItem {}\n')
    icons = APP / 'Contents/MacOS/icons/breeze'
    icons.mkdir(parents=True)
    shutil.copy2(next(SDK.rglob('breeze-icons.rcc')), icons / 'breeze-icons.rcc')
    shutil.copy2(ROOT / 'native/data/photos.json', resources / 'photo-credits.json')
    licenses = resources / 'licenses'
    licenses.mkdir()
    for source in (ROOT / 'target/macos-sources').iterdir():
        if (source / 'LICENSES').is_dir():
            shutil.copytree(source / 'LICENSES', licenses / source.name)
    cellar = Path(subprocess.check_output(['brew', '--cellar'], text=True).strip())
    for formula in cellar.iterdir():
        for installed in formula.iterdir():
            if not installed.is_dir():
                continue
            for notice in installed.iterdir():
                if notice.name.upper().startswith(('LICENSE', 'COPYING', 'COPYRIGHT')):
                    destination = licenses / 'homebrew' / formula.name / installed.name / notice.name
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    if notice.is_dir():
                        shutil.copytree(notice, destination, dirs_exist_ok=True)
                    else:
                        shutil.copy2(notice, destination)
    (resources / 'runtime-packages.txt').write_text(subprocess.check_output(['brew', 'list', '--versions'], text=True) + '\nKDE Frameworks 6.30.0\n')
    (resources / 'README.txt').write_text('Starship Journal — macOS 14+ Apple Silicon\nQt, KDE Kirigami, and JPEG XL are bundled.\nThis development app has an ad-hoc signature; it is not Apple-notarized.\nDependency sources: https://download.kde.org/stable/frameworks/6.30/ and https://github.com/Homebrew/homebrew-core\nPhoto credits: photo-credits.json.\n')
    # A fresh bundle lets macdeployqt rewrite every QML plugin and deploy each
    # shared framework once. Precopying QML would bypass its relocation logic.
    run(brew / 'bin/macdeployqt', APP, '-no-codesign', f'-qmldir={scan}',
        f'-qmlimport={SDK / "qml"}', f'-libpath={SDK / "lib"}', '-verbose=1')
    (resources / 'qt.conf').write_text('[Paths]\nPlugins=PlugIns\nQmlImports=Resources/qml\n')
    # Clearing PATH does not hide absolute Mach-O dependencies; reject SDK paths too.
    visited = set()
    minimum_macos = (14, 0, 0)
    for binary in APP.rglob('*'):
        if not binary.is_file() or binary.resolve() in visited:
            continue
        visited.add(binary.resolve())
        with binary.open('rb') as file:
            magic = file.read(4)
        if magic not in (b'\xcf\xfa\xed\xfe', b'\xfe\xed\xfa\xcf', b'\xca\xfe\xba\xbe', b'\xca\xfe\xba\xbf'):
            continue
        imports = subprocess.check_output(['otool', '-L', str(binary)], text=True)
        for line in imports.splitlines()[1:]:
            dependency = line.strip().split(' (')[0]
            if dependency.startswith((str(brew), str(SDK), '/usr/local/')):
                raise RuntimeError(f'Unbundled SDK dependency in {binary}: {dependency}')
        commands = subprocess.check_output(['otool', '-l', str(binary)], text=True)
        for block in commands.split('Load command'):
            field = 'minos' if 'cmd LC_BUILD_VERSION' in block else 'version' if 'cmd LC_VERSION_MIN_MACOSX' in block else None
            if field and (match := re.search(rf'\b{field}\s+(\d+(?:\.\d+){{1,2}})', block)):
                parts = tuple(int(part) for part in match[1].split('.'))
                minimum_macos = max(minimum_macos, parts + (0,) * (3 - len(parts)))
    minimum_version = '.'.join(str(part) for part in minimum_macos)
    info['LSMinimumSystemVersion'] = minimum_version
    with (APP / 'Contents/Info.plist').open('wb') as file:
        plistlib.dump(info, file)
    compatibility = {'architecture': 'arm64', 'minimum_macos': minimum_version,
                     'signature': 'ad-hoc', 'notarized': False}
    (DIST / 'Starship-Journal-macos-arm64.json').write_text(json.dumps(compatibility, indent=2) + '\n')
    print('Minimum macOS version from bundled dependencies:', minimum_version, flush=True)
    # Sign nested code after deployment rewrites its library references.
    run('codesign', '--force', '--deep', '--sign', '-', APP)
    run('codesign', '--verify', '--deep', '--strict', APP)
    archive = DIST / 'Starship-Journal-macos-arm64.zip'
    run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', APP, archive)
    with tempfile.TemporaryDirectory(prefix='Starship extracted 🛰 ') as work:
        run('ditto', '-x', '-k', archive, work)
        run('python3', ROOT / 'scripts/check-portable.py',
            Path(work) / 'Starship Journal.app/Contents/MacOS/starship-journal',
            '--output', ROOT / 'target/macos-smoke-tests/zip')
    image = STAGE / 'dmg'
    image.mkdir()
    shutil.copytree(APP, image / APP.name, symlinks=True)
    (image / 'Applications').symlink_to('/Applications')
    dmg = DIST / 'Starship-Journal-macos-arm64.dmg'
    run('hdiutil', 'create', '-volname', 'Starship Journal', '-srcfolder', image,
        '-ov', '-format', 'UDZO', dmg)
    run('hdiutil', 'verify', dmg)
    mount = STAGE / 'mounted'
    run('hdiutil', 'attach', '-readonly', '-nobrowse', '-mountpoint', mount, dmg)
    try:
        run('python3', ROOT / 'scripts/check-portable.py',
            mount / 'Starship Journal.app/Contents/MacOS/starship-journal',
            '--output', ROOT / 'target/macos-smoke-tests/dmg')
    finally:
        run('hdiutil', 'detach', mount)


if __name__ == '__main__':
    main()
