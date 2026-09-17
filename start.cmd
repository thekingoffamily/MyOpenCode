@echo off
setlocal
if not defined AITUNNEL_API_KEY (
  echo.
  echo   [WARN] AITUNNEL_API_KEY не задана.
  echo   Задай один раз (свой ключ с https://aitunnel.ru):
  echo     setx AITUNNEL_API_KEY sk-...
  echo   Затем перезапусти этот терминал / окно.
  echo.
)
opencode %*
endlocal