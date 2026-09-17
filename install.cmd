@echo off
setlocal EnableExtensions
title opencode aiTunnel installer (Windows)
echo.
echo   opencode + aiTunnel quick install  (Windows)
echo.

set "DST=%USERPROFILE%\.config\opencode\opencode.json"
set "OC="

REM --------------------------------------------------------------- 1) opencode
where opencode >nul 2>nul
if %errorlevel%==0 (
  set "OC=opencode"
  echo [1/3] opencode already installed:
) else (
  where node >nul 2>nul
  if %errorlevel%==0 (
    echo [1/3] Installing opencode via npm ^(~2 min^)...
    call npm i -g opencode-ai
    if errorlevel 1 echo FAILED: npm install failed & pause & exit /b 1
    set "OC=opencode"
  ) else (
    echo FAILED: opencode not found and Node.js is missing.
    echo Install Node.js LTS from https://nodejs.org then re-run this file.
    pause
    exit /b 1
  )
)
echo        %OC% --version
call %OC% --version

REM --------------------------------------------------------------- 2) config
if not exist "%USERPROFILE%\.config\opencode" mkdir "%USERPROFILE%\.config\opencode"

findstr /c:"\"aitunnel\"" "%DST%" >nul 2>nul
if %errorlevel%==0 (
  echo.
  echo [2/3] aiTunnel provider already present in %DST%
) else (
  echo.
  if exist "%DST%" (
    echo [2/3] Merging aiTunnel into existing %DST% ...
    node "%~dp0install-merge.js" "%~dp0opencode.json" "%DST%"
  ) else (
    echo [2/3] Writing new config to %DST% ...
    copy /y "%~dp0opencode.json" "%DST%" >nul
  )
)

REM --------------------------------------------------------------- 3) key
if defined AITUNNEL_API_KEY (
  echo.
  echo [3/3] AITUNNEL_API_KEY is set. Good.
) else (
  echo.
  echo [3/3] Add your aiTunnel key ONE time:
  echo        setx AITUNNEL_API_KEY sk-aiTunnel-xxxxxxxx
  echo        ^(then close and reopen the terminal^)
)

echo.
echo ============================================================
echo   DONE. Now run:   opencode
echo   Then in the app:  /models   -^> choose  aitunnel/...
echo   Default model: aitunnel/auto   Small: aitunnel/deepseek-v4-flash
echo   For remote servers (SSH + browser GUI) read QUICKSTART.md
echo ============================================================
echo.
pause