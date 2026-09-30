#!/usr/bin/env python3
"""Exercise an extracted app in both layouts with developer SDK overrides removed."""
import argparse
from pathlib import Path
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('executable', type=Path)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
executable = args.executable.resolve()
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='Starship portable 🛰 ') as work:
    locale = 'en_US.UTF-8' if sys.platform == 'darwin' else 'C.UTF-8'
    env = {'PATH': '/usr/bin:/bin:/usr/sbin:/sbin', 'HOME': work, 'LANG': locale,
           'QT_QPA_PLATFORM': 'offscreen', 'QT_QUICK_BACKEND': 'software',
           'QT_FORCE_STDERR_LOGGING': '1', 'STARSHIP_TEST_OUTPUT_DIR': str(output)}
    for variant in ('desktop', 'narrow'):
        with (output / f'{variant}.log').open('w') as log:
            command = [str(executable), '--smoke-test']
            if variant == 'narrow':
                command.append('--narrow-test')
            else:
                command.extend(['-qwindowgeometry', '1600x1000'])
            try:
                subprocess.run(command, cwd=work, env=env, stdout=log, stderr=subprocess.STDOUT,
                               timeout=45, check=True)
            finally:
                log.flush()
                print((output / f'{variant}.log').read_text())
    for name in ('desktop', 'narrow', 'mission', 'mission-narrow', 'cards', 'cards-narrow'):
        assert (output / f'starship-kirigami-{name}.png').stat().st_size, name
print('PASS: portable desktop/narrow UI, navigation, filtering, and 14 JPEG XL photos')
