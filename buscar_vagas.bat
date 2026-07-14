@echo off
setlocal
set "REPO=C:\Users\amanda.salmeida\Desktop\Python\ai-job-search"
set "PATH=%PATH%;C:\Users\amanda.salmeida\AppData\Local\Microsoft\WinGet\Packages\Oven-sh.Bun_Microsoft.Winget.Source_8wekyb3d8bbwe\bun-windows-x64;C:\Users\amanda.salmeida\AppData\Local\Microsoft\WinGet\Packages\OpenJS.NodeJS_Microsoft.Winget.Source_8wekyb3d8bbwe\node-v26.3.0-win-x64"
cd /d "%REPO%"

set "LOGFILE=%REPO%\job_scraper\ultimo_log.txt"

echo ================================================
echo   DATA SYNC - STARTING
echo ================================================
echo Started: %date% %time%
echo.
echo Running scheduled sync job...
echo This usually takes 3 to 10 minutes. Do not close this window.
echo.
echo (detailed progress will appear below when finished)
echo.

echo Started: %date% %time% > "%LOGFILE%"

claude -p "You are a scheduled job-search automation. IMPORTANT: at each major step, print one short, simple status line in English (e.g. 'Searching Data Analyst roles...', 'Found 5 new postings, checking location...', 'Match found: XX%% - Company - Role', 'No new postings in this category') so a non-technical person can follow along. Run the full job search covering these 4 categories: (1) Analista de Dados Pleno/Senior, (2) Engenheiro de Dados Junior e Pleno, (3) Analista de BI Pleno/Senior, (4) Analista de Modelagem de Dados Pleno/Senior. For each category, search both hybrid in Sao Paulo capital and 100%% remote in Brazil, using the example queries in .claude/skills/job-scraper/search-queries.md as reference (use every portal-search skill available under .agents/skills/, including gupy-search if it exists by then, not just linkedin-search and freehire-search), with --jobage 1 (last 24h). Announce the start of each category with a simple line like 'Category 1 of 4: Data Analyst'. Deduplicate against job_scraper/seen_jobs.json (do not reprocess existing URLs). Mandatory filters: always skip estagio/trainee; skip junior except for the Data Engineer category; verify the real location of any ambiguous posting via curl -s -A 'Mozilla/5.0' (exclude Barueri, Osasco, Campinas, Taboao da Serra, Sao Carlos, Porto Alegre, Guarulhos, and any city outside Sao Paulo capital, and exclude fully on-site roles even in the capital; only accept hybrid in SP capital or 100%% remote in Brazil); exclude any posting requiring advanced or fluent English (only intermediate/basic is acceptable). For survivors, fetch the full description and score against the profile in CLAUDE.md using the rubric in .claude/skills/job-application-assistant/04-job-evaluation.md (Technical 30%% + Experience 25%% + Behavioral 15%% + Career 30%%). When scoring each posting, print one simple result line (approved or not, and why in a few words). Persist ALL processed postings (approved or not) to job_scraper/seen_jobs.json following the existing schema, without deleting prior entries. Never pause to ask for confirmation. At the end, write to job_scraper/ultimo_resumo.txt (overwriting prior content) only the postings scoring 65%% or higher, sorted highest first, one line each, format: 'XX%% | Company | Role | link'. If there are none, write one line saying so. Then try to send an email to amandasouza7a2@gmail.com with the same list: look for an available Gmail MCP tool (something like mcp__claude_ai_Gmail__create_draft or a send-email tool); if one is available and authorized, use it -- subject 'Vagas encontradas - <date/time>' if there are any 65%%+ matches (body: the same list) or subject 'Nenhuma vaga nova - <date/time>' with a one-line body if there were none. If no Gmail tool is available, authorized, or it errors, skip the email step silently and do not fail the rest of the run -- print one simple line either way ('Email sent' or 'Email skipped: <short reason>'). Finish by printing a simple final summary like 'DONE! Found N good match(es) out of M analyzed.'" --permission-mode bypassPermissions >> "%LOGFILE%" 2>&1

echo.
echo ================================================
echo   RUN LOG:
echo ================================================
type "%LOGFILE%"
echo ================================================
echo   DONE! Finished: %date% %time%
echo   See also: job_scraper\ultimo_resumo.txt
echo ================================================
echo Finished: %date% %time% >> "%LOGFILE%"
