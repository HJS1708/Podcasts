# Podcasts – täglicher Zusammenfassungs-Digest

Fasst neue Folgen der Lieblingspodcasts (Spotify/YouTube laufen fast immer über einen
öffentlichen RSS-Feed dahinter) täglich zusammen und schickt sie per E-Mail.

## Ablauf
1. `fetch_and_transcribe.py` prüft alle Feeds (`podcasts.json`), lädt **neue** Folgen
   (Zeitfenster, noch nicht verarbeitet – siehe `state.json`) und transkribiert sie
   **lokal** mit Whisper (`faster-whisper`, Modell „base", ~20× Echtzeit, kostenlos).
   → `output/<datum>/episodes.json` + Transkripte in `output/<datum>/transcripts/`.
   Die Audiodateien werden nach der Transkription gelöscht (Platz sparen).
2. Claude erstellt daraus **zwei** Fassungen (Regeln: `CLAUDE.md`), immer auf Deutsch –
   auch bei englischen Podcasts:
   - `output/<datum>/digest_kurz.md` – **Kurzfassung**: höchstens 3–4 Bulletpoints
     **je Podcast** (nicht je Folge), ein Satz pro Punkt, kein Kurzfazit.
   - `output/<datum>/digest.md` – **ausführliche Fassung**: 3–6 Kernaussagen je Folge
     plus Kurzfazit.
3. `send_email.ps1` schickt die **Kurzfassung** an **hjs@rm-beteiligung.de**
   (Outlook-Desktop, ohne Passwort). Die ausführliche Fassung bleibt im Tagesordner.
   Fehlt die Kurzfassung, wird ersatzweise die ausführliche verschickt.

## Podcasts (`podcasts.json`)
Morning Briefing (Pioneer), Frontrunners (Pioneer), Handelsblatt Morning Briefing,
Handelsblatt Trump Watch, POLITICO Berlin Playbook, Machtwechsel (WELT),
The Rest Is Politics: US (engl.), RONZHEIMER.
- **Ausstehend:** Pioneer „Feld & Haucap" – nur im zahlungspflichtigen Mitgliederbereich;
  benötigt einen privaten Feed-Link (aus dem Pioneer-Konto/App), dann in `podcasts.json` ergänzen.
- Neue Podcasts einfach als weiteren Eintrag in `podcasts.json` hinzufügen (`sprache`: de/en).

## Automatik
Windows-Aufgabe „Daily Podcasts Overview", täglich **6:00 Uhr**, mit Nachholung
bei verpasstem Start. Protokoll je Tag in `logs/`.

```powershell
Start-ScheduledTask -TaskName "Daily Podcasts Overview"          # sofort ausführen (dauert je nach Audiomenge ~15-30 Min)
Set-ScheduledTask   -TaskName "Daily Podcasts Overview" -Trigger (New-ScheduledTaskTrigger -Daily -At 6:30am)  # Uhrzeit ändern
Disable-ScheduledTask -TaskName "Daily Podcasts Overview"        # pausieren
Get-ScheduledTaskInfo -TaskName "Daily Podcasts Overview"        # letzter Lauf, Ergebnis (0 = fehlerfrei), nächster Start
```

Aufgabe umbenannt oder nicht gefunden? Der aktuelle Name lässt sich so ermitteln:

```powershell
Get-ScheduledTask | Where-Object { $_.Actions.Arguments -like "*run_daily*" } | Select-Object TaskName, State
```

## Bedienung (manuell)
```bash
.venv/Scripts/python.exe fetch_and_transcribe.py            # alle, neue Folgen
.venv/Scripts/python.exe fetch_and_transcribe.py --nur hb_morning --tage 1   # nur einer
# danach: Claude erstellt digest.md; dann send_email.ps1 <datum>
```

## Abhängigkeiten
- Python (`.venv`): `feedparser`, `faster-whisper`
- Zusammenfassung: Claude-Abo (keine API). Transkription: lokal, kostenlos.

## Kosten / Grenzen
- Alles kostenlos (lokale Transkription + Abo).
- **Spotify-exklusive Inhalte** ohne öffentlichen Feed lassen sich nicht inhaltlich
  zusammenfassen (kein Audio-Zugriff). Lösung: privater Feed (falls vorhanden) oder YouTube.

## Technische Notiz
Die `.ps1`-Skripte sind als **UTF-8 mit BOM** gespeichert, sonst liest Windows PowerShell 5.1
Umlaute/Sonderzeichen falsch. Beim Bearbeiten darauf achten (sonst Intro-Zeile prüfen).
