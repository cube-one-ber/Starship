"""Download selected Max Evans photos using gallery-dl; encode with official libjxl tools."""
import concurrent.futures, hashlib, json, pathlib, subprocess, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[1]

def run(*args):
    subprocess.run([str(a) for a in args], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)

def prepare(item):
    name, photo = item
    original = ROOT / 'assets/originals' / f'{name}.jpg'
    original.parent.mkdir(parents=True, exist_ok=True)
    run('gallery-dl', '--no-input', '--no-mtime', '-D', original.parent, '-f', original.name, photo['url'])
    archive = ROOT / 'assets/jxl' / f'{name}.jxl'
    archive.parent.mkdir(parents=True, exist_ok=True)
    run('cjxl', original, archive, '--lossless_jpeg=1', '--effort=7')
    with tempfile.TemporaryDirectory() as tmp:
        reconstructed = pathlib.Path(tmp) / 'roundtrip.jpg'
        run('djxl', archive, reconstructed)
        assert original.read_bytes() == reconstructed.read_bytes(), f'Lossless roundtrip failed: {name}'
    bundled = ROOT / 'native/assets/photos' / name
    bundled.parent.mkdir(parents=True, exist_ok=True)
    run('magick', original, '-auto-orient', '-resize', '2400x2400>' if name == 'hero' else '1200x1200>', '-quality', '88', str(bundled)+'.jpg')
    run('cjxl', str(bundled)+'.jpg', str(bundled)+'.jxl', '--lossless_jpeg=1', '--effort=7')
    print(f'{name}: downloaded, JPEG XL encoded, exact JPEG roundtrip verified', flush=True)
    return name, dict(photo, path='/photos/'+name, originalSha256=hashlib.sha256(original.read_bytes()).hexdigest(), originalBytes=original.stat().st_size, jxlBytes=archive.stat().st_size)

if __name__ == '__main__':
    selection=json.loads((ROOT/'assets/selection.json').read_text())
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        prepared=dict(pool.map(prepare, selection.items()))
    photos={str(v['flight']): v for k,v in prepared.items() if k != 'hero'}
    photos['hero']=prepared['hero']
    for n in [4,7]:
        src=ROOT/f'native/assets/images/flight-{n}.jpg'
        run('cjxl',src,src.with_suffix('.jxl'),'--lossless_jpeg=1','--effort=7')
        photos[str(n)]={'path':f'/images/flight-{n}','credit':'SpaceX','url':f'https://www.spacex.com/launches/starship-flight-{n}','alt':f'Starship Flight {n}, photographed by SpaceX'}
    (ROOT/'native/data/photos.json').write_text(json.dumps(photos,indent=2)+'\n')
    (ROOT/'assets/conversion-report.json').write_text(json.dumps(prepared,indent=2)+'\n')
