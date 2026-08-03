# Versendet den Podcast-Digest per Outlook-Desktop (COM, ohne Passwort).
# Aufruf:  powershell -File send_email.ps1 <YYYY-MM-DD>

param(
    [Parameter(Mandatory = $true)][string]$Date
)

$ErrorActionPreference = "Stop"
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutDir  = Join-Path $Base "output\$Date"
# Versendet wird die Kurzfassung (3-4 Punkte je Podcast). Die ausfuehrliche
# Fassung (digest.md) bleibt im Tagesordner, falls Details gebraucht werden.
$MdFile  = Join-Path $OutDir "digest_kurz.md"
if (-not (Test-Path $MdFile)) { $MdFile = Join-Path $OutDir "digest.md" }   # Rueckfall
$Recipient = "hjs@rm-beteiligung.de"

if (-not (Test-Path $MdFile)) {
    Write-Output "Kein Digest fuer $Date - kein Versand."
    return
}

function Convert-InlineMarkdown([string]$text) {
    $t = $text -replace "&", "&amp;"
    $t = [regex]::Replace($t, '\[([^\]]+)\]\((https?://[^\)]+)\)', '<a href="$2">$1</a>')
    $t = [regex]::Replace($t, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
    return $t
}

$lines = Get-Content $MdFile -Encoding utf8
$sb = New-Object System.Text.StringBuilder
$inList = $false
$title = "Podcast-Digest $Date"

foreach ($raw in $lines) {
    $line = $raw.TrimEnd()
    if ($inList -and $line -notmatch '^\s*-\s+') { [void]$sb.Append("</ul>"); $inList = $false }

    if ($line -match '^#\s+(.*)') {
        $title = $matches[1].Trim()
        [void]$sb.Append("<h2>$(Convert-InlineMarkdown $matches[1])</h2>")
    }
    elseif ($line -match '^###\s+(.*)') { [void]$sb.Append("<h4 style='margin:14px 0 4px;color:#333'>$(Convert-InlineMarkdown $matches[1])</h4>") }
    elseif ($line -match '^##\s+(.*)')  { [void]$sb.Append("<h3 style='margin:22px 0 6px;border-bottom:2px solid #2b6cb0;padding-bottom:3px;color:#2b6cb0'>$(Convert-InlineMarkdown $matches[1])</h3>") }
    elseif ($line -match '^---+$')       { }
    elseif ($line -match '^\s*-\s+(.*)') {
        if (-not $inList) { [void]$sb.Append("<ul style='margin:4px 0 10px;padding-left:20px'>"); $inList = $true }
        [void]$sb.Append("<li style='margin-bottom:5px'>$(Convert-InlineMarkdown $matches[1])</li>")
    }
    elseif ($line -match '^\*(.*)\*$')   { [void]$sb.Append("<p style='color:#555;font-style:italic;margin:4px 0 8px'>$(Convert-InlineMarkdown $matches[1])</p>") }
    elseif ($line.Trim() -ne "")          { [void]$sb.Append("<p>$(Convert-InlineMarkdown $line)</p>") }
}
if ($inList) { [void]$sb.Append("</ul>") }

$intro = "<p>Guten Morgen,</p><p>hier ist Ihr täglicher Podcast-Digest – das Wichtigste aus den neuen Folgen Ihrer Lieblingspodcasts. Die ausführliche Fassung liegt im Tagesordner.</p>"
$html = "<div style='font-family:Segoe UI,Arial,sans-serif;font-size:14px;line-height:1.45;color:#222;max-width:720px'>$intro$($sb.ToString())</div>"

$outlook = New-Object -ComObject Outlook.Application
$mail = $outlook.CreateItem(0)
$mail.To = $Recipient
$mail.Subject = $title
$mail.HTMLBody = $html
$mail.Send()

Write-Output "E-Mail an $Recipient gesendet (Betreff: $title)."
