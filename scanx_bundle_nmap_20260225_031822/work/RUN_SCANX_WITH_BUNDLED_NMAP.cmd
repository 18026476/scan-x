@echo off
setlocal
set "SCANX_DIR=%~dp0"
set "NMAP_DIR=%SCANX_DIR%tools\nmap"
set "PATH=%NMAP_DIR%;%PATH%"
cd /d "%SCANX_DIR%"
start "" "%SCANX_DIR%scanx_app.exe"
endlocal
