"""Build the Windows release of Great Sage as one EXE."""
import argparse
import os
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
DIST = os.path.join(HERE, "dist")
OVERLAY_DIST = os.path.join(DIST, "GreatSageOverlay")
OVERLAY_VENV_PY = os.path.join(HERE, ".overlay-venv", "Scripts", "python.exe")
ONEFILE = os.path.join(DIST, "GreatSage.exe")


def _run(cmd, label):
    print(f"\n=== {label} ===\n    {' '.join(cmd[:4])} ...", flush=True)
    t0 = time.time()
    p = subprocess.run(cmd, cwd=HERE)
    if p.returncode:
        raise SystemExit(f"\n{label} FAILED (exit {p.returncode})")
    print(f"    done in {time.time() - t0:.0f}s", flush=True)


def _check_locked(name):
    try:
        out = subprocess.run(
            ["tasklist", "/FI", f"IMAGENAME eq {name}.exe", "/FO", "CSV"],
            capture_output=True, text=True, timeout=20,
        ).stdout
        if f"{name}.exe" in out:
            raise SystemExit(f"{name}.exe is still running. Close it first.")
    except FileNotFoundError:
        pass


def build_overlay():
    if not os.path.exists(OVERLAY_VENV_PY):
        raise SystemExit(
            "Missing .overlay-venv. Create it with Python 3.11, then install "
            "PySide6==6.4.3 and pyinstaller."
        )
    _check_locked("GreatSageOverlay")
    _run([OVERLAY_VENV_PY, "-m", "PyInstaller", "--noconfirm", "overlay.spec"],
         "Overlay bundle (embedded into the final EXE)")


def build_app():
    for script in ("check_js.py", "check_shaders.py", "check_routing.py"):
        if subprocess.run([sys.executable, script], cwd=HERE).returncode:
            raise SystemExit(f"{script} failed - refusing to build.")
    if not os.path.isdir(OVERLAY_DIST):
        raise SystemExit("Overlay bundle was not built; cannot create one-file EXE.")
    _check_locked("GreatSage")
    for path in (ONEFILE, os.path.join(DIST, "GreatSage")):
        if os.path.isdir(path):
            shutil.rmtree(path, ignore_errors=True)
        elif os.path.isfile(path):
            try:
                os.remove(path)
            except PermissionError:
                raise SystemExit("Close GreatSage.exe and rebuild.")
    _run([sys.executable, "-m", "PyInstaller", "--noconfirm", "great_sage.spec"],
         "Great Sage single-file EXE")
    # The overlay bundle was only a build input; it is already embedded in
    # GreatSage.exe and must not be shipped as a second user-facing file.
    shutil.rmtree(OVERLAY_DIST, ignore_errors=True)


def verify():
    if not os.path.isfile(ONEFILE):
        raise SystemExit("GreatSage.exe was not produced.")
    size = os.path.getsize(ONEFILE) / (1024 ** 3)
    print("\n=== verify ===")
    print("    OK    dist\\GreatSage.exe")
    print(f"    size  {size:.2f} GB")
    print("\n    Release artifact: dist\\GreatSage.exe")
    print("    The overlay is embedded; no overlay folder is required.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--overlay-only", action="store_true")
    ap.add_argument("--app-only", action="store_true")
    ap.add_argument("--clean", action="store_true", help="remove old PyInstaller build caches before building")
    args = ap.parse_args()
    if args.clean:
        for _cache in (os.path.join(HERE, 'build'),):
            if os.path.isdir(_cache):
                shutil.rmtree(_cache, ignore_errors=True)
        for _spec_cache in (os.path.join(HERE, '__pycache__'),):
            if os.path.isdir(_spec_cache):
                shutil.rmtree(_spec_cache, ignore_errors=True)
    if not args.app_only:
        build_overlay()
    if not args.overlay_only:
        build_app()
        verify()
