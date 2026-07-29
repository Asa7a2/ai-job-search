$ErrorActionPreference = "Continue"

# Evita disparar logo no instante em que o PC acorda da Espera Moderna (lid wake),
# quando processos de console recem-iniciados podem receber um Ctrl+C do sistema.
Start-Sleep -Seconds 45

$repo = "C:\Users\amanda.salmeida\Desktop\Python\ai-job-search"
$env:PATH = "$env:PATH;C:\Users\amanda.salmeida\AppData\Local\Microsoft\WinGet\Packages\Oven-sh.Bun_Microsoft.Winget.Source_8wekyb3d8bbwe\bun-windows-x64;C:\Users\amanda.salmeida\AppData\Local\Microsoft\WinGet\Packages\OpenJS.NodeJS_Microsoft.Winget.Source_8wekyb3d8bbwe\node-v26.3.0-win-x64"
Set-Location $repo

$logFile = Join-Path $repo "job_scraper\ultimo_log.txt"
"Started: $(Get-Date)" | Out-File -FilePath $logFile -Encoding utf8

Write-Host "================================================"
Write-Host "  DATA SYNC - STARTING"
Write-Host "================================================"
Write-Host "Started: $(Get-Date)"
Write-Host ""
Write-Host "Live progress will appear below as it happens."
Write-Host ""

$prompt = @"
You are a scheduled job-search automation running in a fully non-interactive, one-shot session: there is no follow-up turn, no user available to resume anything, and no way to check back later. NEVER run any tool call in the background (no async/backgrounded bash jobs of any kind, including for fetching job description details) - if you background a task in this session, its result is permanently lost and the run silently stalls. Always run every tool call, including fetching full job descriptions for survivors, synchronously/in the foreground and wait for its result before moving on. IMPORTANT: at each major step, print one short, simple status line in English (e.g. 'Searching Data Analyst roles...', 'Found 5 new postings, checking location...', 'Match found: XX% - Company - Role', 'No new postings in this category') so a non-technical person can follow along. Run the full job search covering these 6 categories: (1) Analista de Dados Pleno/Senior, (2) Engenheiro de Dados Junior e Pleno, (3) Analista de BI Pleno/Senior, (4) Analista de Modelagem de Dados Pleno/Senior, (5) Analytics Engineer Pleno/Senior, (6) Data Governance / Data Catalog Analyst Pleno/Senior. For each category, search both hybrid in Sao Paulo capital and 100% remote in Brazil, using the example queries in .claude/skills/job-scraper/search-queries.md as reference (for category 5 use the Priority 3 'Analytics Engineer' queries; for category 6 use the Priority 4 'Data Governance / Data Catalog' queries), with --jobage 3 (last 3 days). Announce the start of each category with a simple line like 'Category 1 of 6: Data Analyst'. Deduplicate against job_scraper/seen_jobs.json (do not reprocess existing URLs). Also read job_search_tracker.csv if it exists (columns: date,company,sector,role,role_type,channel,status,contact_person,fit_rating,notes,cv_file,cover_letter_file,source) and skip/exclude any posting whose company+role already appears there as an already-applied entry, even if seen_jobs.json does not have it marked - the tracker is the authoritative record of what she has actually applied to (including applications made outside this automation). Mandatory filters: always skip estagio/trainee; skip junior except for the Data Engineer category; verify the real location of any ambiguous posting via curl -s -A 'Mozilla/5.0' (exclude Barueri, Osasco, Campinas, Taboao da Serra, Sao Carlos, Porto Alegre, Guarulhos, and any city outside Sao Paulo capital, and exclude fully on-site roles even in the capital; only accept hybrid in SP capital or 100% remote in Brazil); exclude any posting requiring advanced or fluent English (only intermediate/basic is acceptable). For survivors, fetch the full description and score against the profile in CLAUDE.md using the rubric in .claude/skills/job-application-assistant/04-job-evaluation.md (Technical 30% + Experience 25% + Behavioral 15% + Career 30%). When scoring each posting, print one simple result line (approved or not, and why in a few words). Persist ALL processed postings (approved or not) to job_scraper/seen_jobs.json following the existing schema, without deleting prior entries. Never pause to ask for confirmation. At the end, write to job_scraper/ultimo_resumo.txt (overwriting prior content) only the postings scoring 55% or higher, sorted highest first, one line each, format: 'XX% | Company | Role | link'. If there are none, write one line saying so (email sending is handled separately, outside this run). Finish by printing a simple final summary like 'DONE! Found N good match(es) out of M analyzed.'
"@

$promptFile = Join-Path $repo "job_scraper\prompt.tmp"
[System.IO.File]::WriteAllText($promptFile, $prompt, (New-Object System.Text.UTF8Encoding($false)))

$proc = Start-Process -FilePath "claude.cmd" -ArgumentList @("-p", "--permission-mode", "bypassPermissions") `
    -RedirectStandardInput $promptFile -RedirectStandardOutput "$logFile.tmp" -RedirectStandardError "$logFile.err" `
    -NoNewWindow -PassThru

$reader = New-Object System.IO.FileStream("$logFile.tmp", [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$streamReader = New-Object System.IO.StreamReader($reader)

while (-not $proc.HasExited) {
    $line = $streamReader.ReadLine()
    if ($null -ne $line) {
        Write-Host $line
        Add-Content -Path $logFile -Value $line
    } else {
        Start-Sleep -Milliseconds 500
    }
}
while ($null -ne ($line = $streamReader.ReadLine())) {
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}
$streamReader.Close()
try {
    $proc.Refresh()
    $claudeExitCode = $proc.ExitCode
} catch {
    $claudeExitCode = $null
}
$claudeExitCodeDisplay = if ($null -eq $claudeExitCode) { "unknown" } else { $claudeExitCode }
Remove-Item "$logFile.tmp" -ErrorAction SilentlyContinue
Remove-Item "$logFile.err" -ErrorAction SilentlyContinue
Remove-Item $promptFile -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "================================================"
Write-Host "  DONE! Finished: $(Get-Date)"
Write-Host "  See also: job_scraper\ultimo_resumo.txt"
Write-Host "================================================"
Add-Content -Path $logFile -Value "Finished: $(Get-Date) (claude exit code: $claudeExitCodeDisplay)"

$credFile = Join-Path $repo "job_scraper\email_credentials.ps1"
$resumoFile = Join-Path $repo "job_scraper\ultimo_resumo.txt"
if (Test-Path $credFile) {
    . $credFile
    $body = if (Test-Path $resumoFile) { Get-Content $resumoFile -Raw -Encoding UTF8 } else { "(sem resumo disponivel)" }
    $hasMatches = $body -match '%\s*\|'
    $subject = if ($hasMatches) { "Vagas encontradas - $(Get-Date -Format 'dd/MM HH:mm')" } else { "Nenhuma vaga nova - $(Get-Date -Format 'dd/MM HH:mm')" }
    $emailAttempts = 0
    $emailSent = $false
    $lastEmailError = $null
    while (-not $emailSent -and $emailAttempts -lt 3) {
        $emailAttempts++
        try {
            $smtp = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
            $smtp.EnableSsl = $true
            $smtp.Credentials = New-Object System.Net.NetworkCredential($GmailUser, $GmailAppPassword)
            $mail = New-Object System.Net.Mail.MailMessage($GmailUser, $GmailTo, $subject, $body)
            $mail.BodyEncoding = [System.Text.Encoding]::UTF8
            $mail.SubjectEncoding = [System.Text.Encoding]::UTF8
            $smtp.Send($mail)
            $emailSent = $true
            Write-Host "Email sent to $GmailTo"
            Add-Content -Path $logFile -Value "Email sent to $GmailTo"
            $emailStatus = "sent"
        } catch {
            $detail = $_.Exception.Message
            if ($_.Exception.InnerException) { $detail += " | inner: $($_.Exception.InnerException.Message)" }
            $lastEmailError = $detail
            if ($emailAttempts -lt 3) { Start-Sleep -Seconds 20 }
        }
    }
    if (-not $emailSent) {
        Write-Host "Email skipped after $emailAttempts attempts: $lastEmailError"
        Add-Content -Path $logFile -Value "Email skipped after $emailAttempts attempts: $lastEmailError"
        $emailStatus = "FAILED after $emailAttempts attempts: $lastEmailError"
    }
} else {
    Write-Host "Email skipped: no credentials file found"
    $emailStatus = "SKIPPED: no credentials file"
}

# Historico persistente (uma linha por rodada) - o ultimo_log.txt acima e sobrescrito a cada
# rodada, entao sem isso nao ha como diagnosticar falhas passadas sem vasculhar o Event Log do Windows.
$historyFile = Join-Path $repo "job_scraper\historico_execucoes.log"
$matchCount = if (Test-Path $resumoFile) { ([regex]::Matches((Get-Content $resumoFile -Raw -Encoding UTF8), '%\s*\|')).Count } else { 0 }
Add-Content -Path $historyFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | claude_exit=$claudeExitCodeDisplay | matches=$matchCount | email=$emailStatus"

# Propaga falha real do claude.cmd para o exit code do wrapper, senao o Agendador de Tarefas
# nunca aciona o RestartOnFailure (o processo powershell.exe sempre retornava 0 antes disso,
# mesmo quando o claude.cmd morria/travava). So dispara quando temos confirmacao positiva de
# um exit code != 0 - "unknown" (captura falhou) NAO deve forcar retry, senao um bug de leitura
# do ExitCode gera retry (e gasto de tokens) em toda rodada, inclusive nas bem-sucedidas.
if ($null -ne $claudeExitCode -and $claudeExitCode -ne 0) {
    exit 1
}
