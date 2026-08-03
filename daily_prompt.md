Du erstellst den heutigen Podcast-Digest. Halte Dich strikt an die Regeln in CLAUDE.md.

Vorgehen:
1. Lies `output/HEUTE/episodes.json` (HEUTE = heutiges Datum YYYY-MM-DD).
2. Ist die Liste `episoden` leer: schreibe nur `output/HEUTE/keine_folgen.txt` (eine Zeile) und beende.
3. Andernfalls: lies für JEDE Folge die im Feld `transkript` angegebene Datei
   (relativ zu `output/HEUTE/`) und fasse sie gemäß den Regeln zusammen.
4. Schreibe ZWEI Dateien im jeweils vorgegebenen Aufbau:
   - `output/HEUTE/digest_kurz.md` – Kurzfassung: höchstens **3–4 Bulletpoints je Podcast**
     (nicht je Folge), ein Satz pro Punkt, kein Kurzfazit, keine Folgentitel.
     Diese Fassung geht in die E-Mail.
   - `output/HEUTE/digest.md` – ausführliche Fassung: 3–6 Kernaussagen je Folge + Kurzfazit.

Arbeite eigenständig, ohne Rückfragen. Vorhandene Dateien überschreiben.
Gib am Ende nur eine kurze Statuszeile aus. Der Versand übernimmt das Skript.
