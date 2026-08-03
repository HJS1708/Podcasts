# Taeglicher Automatik-Lauf: neue Podcast-Folgen laden + transkribieren ->
# Claude fasst zusammen -> E-Mail. Aufruf durch die Windows-Aufgabenplanung.
# Protokoll in logs\.

$ErrorActionPreference = "Stop"
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Base

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Today  = Get-Date -Format "yyyy-MM-dd"
$Python = Join-Path $Base ".venv\Scripts\python.exe"
$OutDir = Join-Path $Base "output\$Today"
$LogDir = Join-Path $Base "logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }
$Log = Join-Path $LogDir "run_$Today.log"

function Write-Log($msg) {
    $line = "{0}  {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    Add-Content -Path $Log -Value $line -Encoding utf8
    Write-Output $line
}

$Claude = "C:\Users\Schäfer\.local\bin\claude.exe"
if (-not (Test-Path $Claude)) {
    $cmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($cmd) { $Claude = $cmd.Source }
}

Write-Log "=== Lauf gestartet fuer $Today ==="

# 1. Neue Folgen laden + transkribieren
Write-Log "Schritt 1/3: Neue Folgen laden + transkribieren ..."
& $Python (Join-Path $Base "fetch_and_transcribe.py") 2>&1 | ForEach-Object { Add-Content -Path $Log -Value $_ -Encoding utf8 }

# 2. Digest durch Claude (nutzt das Abo, keine API)
Write-Log "Schritt 2/3: Zusammenfassung durch Claude ..."
$Prompt = (Get-Content (Join-Path $Base "daily_prompt.md") -Raw) -replace "HEUTE", $Today
$claudeOut = $Prompt | & $Claude -p --permission-mode acceptEdits 2>&1
Add-Content -Path $Log -Value "Claude: $claudeOut" -Encoding utf8

# 3. E-Mail-Versand - nur wenn ein Digest erstellt wurde
$Md = Join-Path $OutDir "digest_kurz.md"
if (-not (Test-Path $Md)) { $Md = Join-Path $OutDir "digest.md" }
if (Test-Path $Md) {
    Write-Log "Schritt 3/3: E-Mail versenden ..."
    try {
        & (Join-Path $Base "send_email.ps1") -Date $Today 2>&1 | ForEach-Object { Add-Content -Path $Log -Value $_ -Encoding utf8 }
    } catch {
        Write-Log "E-Mail-Versand fehlgeschlagen: $_"
    }
} else {
    Write-Log "Kein Digest (keine neuen Folgen) - kein Versand."
}

Write-Log "=== Lauf beendet ==="
