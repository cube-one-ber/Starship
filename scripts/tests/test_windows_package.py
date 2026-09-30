import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("windows_package", Path(__file__).parents[1] / "package-windows.py")
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


class DllPackagingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="starship packaging 🛰 ")
        self.addCleanup(self.temporary.cleanup)
        root = Path(self.temporary.name)
        self.stage, self.sdk, self.system = (root / name for name in ("package", "sdk", "System32"))
        for path in (self.stage, self.sdk, self.system):
            path.mkdir()
        (self.stage / "starship.exe").write_bytes(b"app")
        (self.stage / "qml/org/kde").mkdir(parents=True)
        (self.stage / "qml/org/kde/plugin.dll").write_bytes(b"qml plugin")
        (self.system / "KERNEL32.dll").touch()

    def test_recursive_imports_cycles_and_case_insensitive_names(self):
        for name in ("libjxl.dll", "libhwy.dll", "libKF6.dll"):
            (self.sdk / name).write_bytes(name.encode())
        dependencies = {
            "starship.exe": ["LIBJXL.DLL", "KERNEL32.dll", "api-ms-win-core-file-l1-1-0.dll"],
            "plugin.dll": ["libKF6.dll"],
            "libjxl.dll": ["libhwy.dll"],
            "libhwy.dll": ["libjxl.dll"],
            "libKF6.dll": ["kernel32.DLL"],
        }
        package.copy_dll_dependencies(self.stage, self.sdk, self.system, lambda path: dependencies[path.name])
        self.assertEqual({p.name for p in self.stage.glob("*.dll")}, {"libjxl.dll", "libhwy.dll", "libKF6.dll"})
        self.assertFalse((self.stage / "KERNEL32.dll").exists())

    def test_missing_library_is_an_error_even_from_a_qml_plugin(self):
        with self.assertRaisesRegex(RuntimeError, "Missing DLL absent.dll, imported by"):
            package.copy_dll_dependencies(self.stage, self.sdk, self.system,
                                          lambda path: ["absent.dll"] if path.name == "plugin.dll" else [])

    def test_existing_runtime_is_still_scanned(self):
        (self.stage / "libjxl.dll").touch()
        (self.sdk / "libhwy.dll").write_bytes(b"codec dependency")
        package.copy_dll_dependencies(self.stage, self.sdk, self.system,
                                      lambda path: ["libhwy.dll"] if path.name == "libjxl.dll" else [])
        self.assertEqual((self.stage / "libhwy.dll").read_bytes(), b"codec dependency")

    def test_objdump_import_parsing(self):
        with patch.object(package, "run", return_value="DLL Name: libjxl.dll\n\tDLL Name: KERNEL32.dll\n"):
            self.assertEqual(package.imports(Path("app.exe"), Path("objdump")), ["libjxl.dll", "KERNEL32.dll"])


if __name__ == "__main__":
    unittest.main()
