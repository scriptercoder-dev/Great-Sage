@echo off
setlocal
cd /d "%~dp0"

echo ============================================================
echo GREAT SAGE - ONE FILE WINDOWS BUILD
echo ============================================================
echo.

echo [1/5] Checking Python...
py --version
if errorlevel 1 goto :fail

echo.
echo [2/5] Installing main build dependencies...
py -m pip install -r requirements.txt
if errorlevel 1 goto :fail

echo.
echo [3/5] Preparing overlay Python 3.11...
if not exist ".overlay-venv\Scripts\python.exe" (
    py -3.11 -m venv .overlay-venv
    if errorlevel 1 goto :fail
)
.overlay-venv\Scripts\python.exe -m pip install -U "PySide6==6.4.3" pyinstaller
if errorlevel 1 goto :fail

echo.
echo [4/5] Building ONE GreatSage.exe...
py build.py
if errorlevel 1 goto :fail

echo.
echo [5/5] DONE
echo.
echo ============================================================
echo dist\GreatSage.exe
echo ============================================================
echo.
echo The overlay is embedded inside GreatSage.exe.
echo No overlay folder is required for the user.
echo.
pause
exit /b 0

:fail
echo.
echo BUILD FAILED.
pause
exit /b 1
