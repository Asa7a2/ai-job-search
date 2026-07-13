@echo off
setlocal
set "REPO=C:\Users\amanda.salmeida\Desktop\Python\ai-job-search"
set "PATH=%PATH%;C:\Users\amanda.salmeida\AppData\Local\Microsoft\WinGet\Packages\Oven-sh.Bun_Microsoft.Winget.Source_8wekyb3d8bbwe\bun-windows-x64"
cd /d "%REPO%"

set "LOGFILE=%REPO%\job_scraper\ultimo_log.txt"

echo Buscando vagas novas... isso pode levar alguns minutos.
echo (Log completo em job_scraper\ultimo_log.txt)

claude -p "Rode o fluxo completo: primeiro /scrape para buscar vagas novas (janela de 7 dias, usando as queries em .claude/skills/job-scraper/search-queries.md), depois deduplique contra job_scraper/seen_jobs.json (nao reprocessar URLs ja existentes), verifique a localizacao real de cada vaga ambigua via WebFetch ou curl -s -A (excluir Barueri, Osasco, Campinas, Taboao da Serra, Sao Carlos, Porto Alegre e qualquer cidade fora da capital de Sao Paulo; aceitar apenas hibrido na capital de SP ou 100%% remoto no Brasil), exclua qualquer vaga que exija ingles avancado ou fluente (aceitar apenas intermediario/basico), pule vagas junior/estagio, rode o rubric de /rank nas sobreviventes, e persista tudo em job_scraper/seen_jobs.json seguindo o schema existente sem apagar entradas anteriores. Nao pare para pedir nenhuma confirmacao em nenhum momento. Ao final escreva um resumo em texto simples (apenas vagas Strong Fit ou Good Fit novas: empresa, cargo, score, motivo, link) no arquivo job_scraper/ultimo_resumo.txt, sobrescrevendo o conteudo anterior." --permission-mode bypassPermissions > "%LOGFILE%" 2>&1

echo.
echo Concluido! Abra job_scraper\ultimo_resumo.txt para ver as vagas novas.
pause
