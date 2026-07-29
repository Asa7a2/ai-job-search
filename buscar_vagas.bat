@echo off
setlocal
set "REPO=C:\Users\amanda.salmeida\Desktop\Python\ai-job-search"
cd /d "%REPO%"

echo ================================================
echo   DATA SYNC - STARTING (manual run)
echo ================================================
echo Started: %date% %time%
echo.
echo Running the same automation as the scheduled task.
echo This usually takes 5 to 15 minutes. Do not close this window.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%REPO%\buscar_vagas.ps1"

echo.
echo ================================================
echo   RUN LOG:
echo ================================================
type "%REPO%\job_scraper\ultimo_log.txt"
echo ================================================
echo   DONE! See also: job_scraper\ultimo_resumo.txt
echo ================================================
pause
