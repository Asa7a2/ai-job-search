$ErrorActionPreference = "Continue"
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
You are a scheduled job-search automation. IMPORTANT: at each major step, print one short, simple status line in English (e.g. 'Searching Data Analyst roles...', 'Found 5 new postings, checking location...', 'Match found: XX% - Company - Role', 'No new postings in this category') so a non-technical person can follow along. Run the full job search covering these 4 categories: (1) Analista de Dados Pleno/Senior, (2) Engenheiro de Dados Junior e Pleno, (3) Analista de BI Pleno/Senior, (4) Analista de Modelagem de Dados Pleno/Senior. For each category, search both hybrid in Sao Paulo capital and 100% remote in Brazil, using the example queries in .claude/skills/job-scraper/search-queries.md as reference, with --jobage 1 (last 24h). Announce the start of each category with a simple line like 'Category 1 of 4: Data Analyst'. Deduplicate against job_scraper/seen_jobs.json (do not reprocess existing URLs). Mandatory filters: always skip estagio/trainee; skip junior except for the Data Engineer category; verify the real location of any ambiguous posting via curl -s -A 'Mozilla/5.0' (exclude Barueri, Osasco, Campinas, Taboao da Serra, Sao Carlos, Porto Alegre, Guarulhos, and any city outside Sao Paulo capital, and exclude fully on-site roles even in the capital; only accept hybrid in SP capital or 100% remote in Brazil); exclude any posting requiring advanced or fluent English (only intermediate/basic is acceptable). For survivors, fetch the full description and score against the profile in CLAUDE.md using the rubric in .claude/skills/job-application-assistant/04-job-evaluation.md (Technical 30% + Experience 25% + Behavioral 15% + Career 30%). When scoring each posting, print one simple result line (approved or not, and why in a few words). Persist ALL processed postings (approved or not) to job_scraper/seen_jobs.json following the existing schema, without deleting prior entries. Never pause to ask for confirmation. At the end, write to job_scraper/ultimo_resumo.txt (overwriting prior content) only the postings scoring 65% or higher, sorted highest first, one line each, format: 'XX% | Company | Role | link'. If there are none, write one line saying so (email sending is handled separately, outside this run). Finish by printing a simple final summary like 'DONE! Found N good match(es) out of M analyzed.'
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
Remove-Item "$logFile.tmp" -ErrorAction SilentlyContinue
Remove-Item "$logFile.err" -ErrorAction SilentlyContinue
Remove-Item $promptFile -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "================================================"
Write-Host "  DONE! Finished: $(Get-Date)"
Write-Host "  See also: job_scraper\ultimo_resumo.txt"
Write-Host "================================================"
Add-Content -Path $logFile -Value "Finished: $(Get-Date)"

$credFile = Join-Path $repo "job_scraper\email_credentials.ps1"
$resumoFile = Join-Path $repo "job_scraper\ultimo_resumo.txt"
if (Test-Path $credFile) {
    . $credFile
    $body = if (Test-Path $resumoFile) { Get-Content $resumoFile -Raw -Encoding UTF8 } else { "(sem resumo disponivel)" }
    $hasMatches = $body -match '%\s*\|'
    $subject = if ($hasMatches) { "Vagas encontradas - $(Get-Date -Format 'dd/MM HH:mm')" } else { "Nenhuma vaga nova - $(Get-Date -Format 'dd/MM HH:mm')" }
    try {
        $smtp = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
        $smtp.EnableSsl = $true
        $smtp.Credentials = New-Object System.Net.NetworkCredential($GmailUser, $GmailAppPassword)
        $mail = New-Object System.Net.Mail.MailMessage($GmailUser, $GmailTo, $subject, $body)
        $mail.BodyEncoding = [System.Text.Encoding]::UTF8
        $mail.SubjectEncoding = [System.Text.Encoding]::UTF8
        $smtp.Send($mail)
        Write-Host "Email sent to $GmailTo"
        Add-Content -Path $logFile -Value "Email sent to $GmailTo"
    } catch {
        Write-Host "Email skipped: $($_.Exception.Message)"
        Add-Content -Path $logFile -Value "Email skipped: $($_.Exception.Message)"
    }
} else {
    Write-Host "Email skipped: no credentials file found"
}
