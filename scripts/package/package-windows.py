#!/usr/bin/env python3
"""Package the UCRT64 build with Qt, KDE and the recursive native DLL dependencies."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SYSTEM_PREFIXES = ("api-ms-win-", "ext-ms-win-")


def run(*args: str | Path) -> str:
    return subprocess.check_output([str(arg) for arg in args], text=True, encoding="utf-8").strip()


def imports(binary: Path, objdump: Path) -> list[str]:
    return re.findall(r"DLL Name:\s*(\S+)", run(objdump, "-p", binary), re.IGNORECASE)


def copy_dll_dependencies(destination: Path, sdk_bin: Path, system_dir: Path, inspect) -> None:
    """Fail on unresolved imports; never bundle Windows system DLLs."""
    available = {p.name.casefold(): p for p in sdk_bin.glob("*.dll")}
    system = {p.name.casefold() for p in system_dir.glob("*.dll")}
    pending = [p for p in destination.rglob("*") if p.suffix.casefold() in (".dll", ".exe")]
    root_dlls = {p.name.casefold(): p for p in destination.glob("*.dll")}
    visited = set()
    while pending:
        binary = pending.pop()
        key = binary.resolve()
        if key in visited:
            continue
        visited.add(key)
        for name in inspect(binary):
            normalized = name.casefold()
            if normalized.startswith(SYSTEM_PREFIXES):
                continue
            if normalized in root_dlls:
                continue
            # SDK libraries take precedence over same-named optional system libraries.
            if source := available.get(normalized):
                target = destination / source.name
                shutil.copy2(source, target)
                root_dlls[normalized] = target
                pending.append(target)
            elif normalized not in system:
                raise RuntimeError(f"Missing DLL {name}, imported by {binary.relative_to(destination)}")


def copy_tree(source: Path, destination: Path, required: bool = True) -> None:
    if not source.is_dir():
        if required:
            raise RuntimeError(f"Missing runtime directory: {source}")
        return
    shutil.copytree(source, destination, dirs_exist_ok=True)


def prepare_build_tools(qmake: str) -> None:
    """Make MSYS2's Qt host tools runnable when CXX-Qt clears their environment."""
    sdk_bin = Path(run(qmake, "-query", "QT_INSTALL_BINS"))
    tools = Path(run(qmake, "-query", "QT_HOST_LIBEXECS"))
    objdump = sdk_bin / "objdump.exe"
    copy_dll_dependencies(tools, sdk_bin, Path(os.environ["SystemRoot"]) / "System32",
                          lambda path: imports(path, objdump))
    # DLLs moved beside the tools must still resolve the original SDK's QML/plugins.
    paths = {"Prefix": "QT_INSTALL_PREFIX", "Binaries": "QT_INSTALL_BINS",
             "Libraries": "QT_INSTALL_LIBS", "Headers": "QT_INSTALL_HEADERS",
             "LibraryExecutables": "QT_INSTALL_LIBEXECS", "Plugins": "QT_INSTALL_PLUGINS",
             "QmlImports": "QT_INSTALL_QML", "Data": "QT_INSTALL_DATA", "ArchData": "QT_INSTALL_ARCHDATA"}
    configuration = "[Paths]\n" + "".join(f"{key}={run(qmake, '-query', value)}\n" for key, value in paths.items())
    (tools / "qt.conf").write_text(configuration, encoding="utf-8")
    for name in ("moc", "rcc", "qmltyperegistrar", "qmlcachegen"):
        subprocess.run([str(tools / f"{name}.exe"), "--help"], env={}, check=True,
                       stdout=subprocess.DEVNULL)
    print("Qt build tools run successfully without PATH.", flush=True)


def package(exe: Path, qmake: str, output: Path) -> Path:
    sdk = Path(run(qmake, "-query", "QT_INSTALL_PREFIX"))
    sdk_bin = Path(run(qmake, "-query", "QT_INSTALL_BINS"))
    sdk_qml = Path(run(qmake, "-query", "QT_INSTALL_QML"))
    sdk_plugins = Path(run(qmake, "-query", "QT_INSTALL_PLUGINS"))
    objdump = sdk_bin / "objdump.exe"
    deploy = sdk_bin / "windeployqt6.exe"
    if not exe.is_file() or not objdump.is_file() or not deploy.is_file():
        raise RuntimeError("Build the EXE and install the UCRT64 Qt and binutils packages first")
    output.mkdir(parents=True, exist_ok=True)
    name = "Starship-Journal-windows-x64"
    # Stage in a fresh directory so removed dependencies never linger in later packages.
    with tempfile.TemporaryDirectory(prefix="starship-package-") as work:
        stage = Path(work) / name
        stage.mkdir()
        target_exe = stage / "starship-journal.exe"
        shutil.copy2(exe, target_exe)
        scan = Path(work) / "qml-scan"
        shutil.copytree(ROOT / "qml", scan)
        shutil.copy2(ROOT / "packaging/windows/Deployment.qml", scan)
        subprocess.run([
            str(deploy), "--release", "--no-translations", "--dir", str(stage),
            "--plugindir", str(stage / "plugins"), "--qmldir", str(scan),
            "--qmlimport", str(sdk_qml), str(target_exe),
        ], check=True)
        # windeployqt primarily handles Qt; explicitly retain KDE's dynamic styles.
        for module in ("kirigami", "desktop", "qqc2desktopstyle", "iconthemes", "sonnet"):
            copy_tree(sdk_qml / "org/kde" / module, stage / "qml/org/kde" / module)
        for plugin in ("styles", "kf6/kirigami/platform", "kiconthemes6/iconengines"):
            copy_tree(sdk_plugins / plugin, stage / "plugins" / plugin)
        # Sonnet's QML module is required by the desktop controls, but this app
        # does not use its optional spellchecking backends (or their dictionaries).
        # Include offscreen for the same smoke test on Windows and Linux.
        for group, filename in (("platforms", "qoffscreen.dll"), ("imageformats", "qsvg.dll"),
                                ("iconengines", "qsvgicon.dll")):
            path = sdk_plugins / group / filename
            target = stage / "plugins" / group / filename
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
        icons = sdk_bin / "data/icons/breeze/breeze-icons.rcc"
        target_icons = stage / "icons/breeze/breeze-icons.rcc"
        target_icons.parent.mkdir(parents=True)
        shutil.copy2(icons, target_icons)
        (stage / "qt.conf").write_text("[Paths]\nPrefix=.\nPlugins=plugins\nQmlImports=qml\n", encoding="utf-8")
        copy_dll_dependencies(stage, sdk_bin, Path(os.environ["SystemRoot"]) / "System32",
                              lambda path: imports(path, objdump))
        # Keep the SDK-provided licensing notices and package versions with the runtime.
        copy_tree(sdk / "share/licenses", stage / "licenses", required=False)
        (stage / "runtime-packages.txt").write_text(run("pacman", "-Q") + "\n", encoding="utf-8")
        shutil.copy2(ROOT / "resources/data/photos.json", stage / "photo-credits.json")
        (stage / "README.txt").write_text(
            "Starship Journal — Windows x64\n\n"
            "Extract the entire folder and double-click starship-journal.exe.\n"
            "Windows 10/11, 64-bit. No separate Qt, KDE or Rust installation is needed.\n"
            "Keep the DLLs, qml, plugins and icons beside the executable.\n\n"
            "Qt: https://www.qt.io/licensing/\nKDE: https://invent.kde.org/\n"
            "JPEG XL: https://github.com/libjxl/libjxl\n"
            "Dependency sources: https://github.com/msys2/MINGW-packages\n"
            "Package versions: runtime-packages.txt. License notices: licenses/.\n"
            "Photo credits: photo-credits.json. Photos remain their creators' property.\n",
            encoding="utf-8")
        manifest = {str(p.relative_to(stage)).replace("\\", "/"): hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in sorted(stage.rglob("*")) if p.is_file()}
        (stage / "manifest-sha256.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        archive = output / f"{name}.zip"
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as bundle:
            for path in sorted(stage.rglob("*")):
                if path.is_file():
                    bundle.write(path, path.relative_to(stage.parent))
        return archive


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", type=Path, default=ROOT / "target/windows/x86_64-pc-windows-gnu/release/starship-journal.exe")
    parser.add_argument("--qmake", default=os.environ.get("QMAKE", "qmake6"))
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    parser.add_argument("--prepare-build-tools", action="store_true", help="Prepare and verify the MSYS2 Qt host tools before Cargo builds")
    args = parser.parse_args()
    try:
        if args.prepare_build_tools:
            prepare_build_tools(args.qmake)
        else:
            print(package(args.exe.resolve(), args.qmake, args.output.resolve()))
    except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Windows packaging failed: {error}\n")
