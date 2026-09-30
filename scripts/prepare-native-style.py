#!/usr/bin/env python3
"""Cache the official Arch KDE Breeze runtime locally; no system installation required."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
runtime = root / 'native/runtime'
url = subprocess.check_output(
    ['pacman', '-Sp', '--print-format', '%l', 'qqc2-breeze-style'], text=True
).strip().splitlines()[-1]
runtime.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='starship-breeze-') as directory:
    archive = Path(directory) / 'breeze.pkg.tar.zst'
    subprocess.run(["curl", "--fail", "--location", "--max-time", "30", "--silent", "--show-error", "--output", str(archive), url], check=True)
    subprocess.run([
        'bsdtar', '-xf', str(archive), '-C', str(runtime),
        '--include', 'usr/lib/qt6/qml/*', '--include', 'usr/lib/qt6/plugins/*'
    ], check=True)
    (runtime / 'source.json').write_text(json.dumps({
        'package': 'qqc2-breeze-style', 'url': url,
        'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
        'upstream': 'https://invent.kde.org/plasma/qqc2-breeze-style',
        'license': 'LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL'
    }, indent=2) + '\n')
print('KDE Breeze runtime ready:', runtime)
