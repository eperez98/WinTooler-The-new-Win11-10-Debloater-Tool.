@echo off
:: WinToolerV1 Launcher - by Eperez98
:: Double-click this file to launch WinToolerV1 as Administrator

title WinToolerV1 - by Eperez98

:: ── Check if already running as Admin ──────────────────────────
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo  Requesting Administrator privileges...
    echo.
    :: Self-elevate via PowerShell UAC prompt
    powershell -NoProfile -Command ^
        "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:: ── We are Admin - launch the script ───────────────────────────
echo.
echo  ============================================
echo    WinToolerV1 - by Eperez98
echo    Starting GUI...
echo  ============================================
echo.

:: Use %~dp0 (directory of this .bat) to build absolute path to .ps1
set "SCRIPT=%~dp0WinToolerV1.ps1"

if not exist "%SCRIPT%" (
    echo  [ERROR] WinToolerV1.ps1 not found in:
    echo  %~dp0
    echo.
    echo  Make sure Launch.bat is in the same folder as WinToolerV1.ps1
    echo.
    pause
    exit /b 1
)

echo  Script: %SCRIPT%
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%SCRIPT%"

:: Keep window open if something went wrong
if %errorLevel% neq 0 (
    echo.
    echo  ============================================
    echo    [ERROR] Script exited with code %errorLevel%
    echo    Check log in: %TEMP%\WinToolerV1_*.log
    echo  ============================================
    echo.
    pause
)
