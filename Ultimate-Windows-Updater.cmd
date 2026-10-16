@echo off
setlocal EnableExtensions EnableDelayedExpansion
color 0B
title Ultimate System Updater v2.0 - Abdul Wahid Chohan

:: ============================================================
::  Ultimate-Windows-Updater.cmd  v2.0
::  Made by Abdul Wahid Chohan
::
::  This file is a lightweight CMD launcher.
::  All update logic lives in PowerShell-Updater.ps1
::  If the PS1 is not present beside this file, it is
::  downloaded automatically from GitHub.
:: ============================================================

set "ELEVATED_ATTEMPTED=0"
set "NON_INTERACTIVE=0"

for %%A in (%*) do (
    if /I "%%~A"=="--elevated"        set "ELEVATED_ATTEMPTED=1"
    if /I "%%~A"=="--non-interactive" set "NON_INTERACTIVE=1"
)

:: ── Detect non-interactive / piped session ───────────────────────────────────
if "%NON_INTERACTIVE%"=="0" (
    for /f %%I in ('powershell -NoProfile -Command "[Console]::IsInputRedirected -or [Console]::IsOutputRedirected" 2^>nul') do set "REDIR=%%I"
    if /I "!REDIR!"=="True" set "NON_INTERACTIVE=1"
)

:: ── Administrator elevation guard ───────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    if "%ELEVATED_ATTEMPTED%"=="1" (
        echo [!] Administrator elevation was denied or failed. Exiting.
        exit /b 1
    )
    echo [!] Administrator privileges required. Requesting elevation...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -ArgumentList '/c \"%~f0\" --elevated %*' -Verb RunAs"
    exit /b
)

:: ── Locate or download PowerShell-Updater.ps1 ───────────────────────────────
set "LOCAL_PS1=%~dp0PowerShell-Updater.ps1"
set "TEMP_PS1=%TEMP%\PowerShell-Updater_%RANDOM%.ps1"
set "USE_TEMP=0"
set "PS1_PATH=%LOCAL_PS1%"

if not exist "%LOCAL_PS1%" (
    echo [*] PowerShell-Updater.ps1 not found locally. Downloading from GitHub...
    curl -L -s --fail -o "%TEMP_PS1%" "https://raw.githubusercontent.com/abdulwahidchohan/Ultimate-System-Updater/main/PowerShell-Updater.ps1"
    if %errorlevel% neq 0 (
        echo [!] Download failed. Please check your internet connection.
        echo [!] Or place PowerShell-Updater.ps1 alongside this file and re-run.
        pause
        exit /b 1
    )
    echo [*] Download successful.
    set "PS1_PATH=%TEMP_PS1%"
    set "USE_TEMP=1"
)

:: ── Build argument list for the PS1 ─────────────────────────────────────────
set "PS_ARGS=-ElevatedAttempted"
if "%NON_INTERACTIVE%"=="1" set "PS_ARGS=%PS_ARGS% -NonInteractive"

:: ── Execute PowerShell script ────────────────────────────────────────────────
echo [*] Launching PowerShell update engine...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_PATH%" %PS_ARGS%

:: ── Cleanup temp download ────────────────────────────────────────────────────
if "%USE_TEMP%"=="1" (
    del "%TEMP_PS1%" 2>nul
)

endlocal
exit /b