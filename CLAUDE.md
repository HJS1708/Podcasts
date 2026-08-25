# Projekt: Podcasts – täglicher Zusammenfassungs-Digest

Fasst neue Folgen der Lieblingspodcasts (Liste in `podcasts.json`) zusammen. Ablauf:
`fetch_and_transcribe.py` lädt neue Folgen und transkribiert sie lokal (Whisper) →
`output/<datum>/episodes.json` + Transkripte in `output/<datum>/transcripts/`.
Danach erstellt Claude daraus `output/<datum>/digest.md`. Details siehe README.md.

## Kommunikation mit HJS
**Immer auf Deutsch antworten.** Das gilt für sämtliche Antworten, Rückfragen,
Erklärungen und Statusmeldungen – unabhängig davon, in welcher Sprache die Anfrage
gestellt wird oder der Code kommentiert ist. Diese Regel betrifft jede Arbeit in
diesem Projekt, nicht nur die Digest-Erstellung (dafür gilt zusätzlich die
Sprachregel unter „Regeln").

## Aufgabe von Claude
Aus `output/<datum>/episodes.json` (Liste der neuen Folgen mit Transkript-Pfad) **zwei**
Dateien erstellen. Für JEDE Folge das zugehörige Transkript lesen und zusammenfassen:

1. `output/<datum>/digest_kurz.md` – **Kurzfassung zum Überfliegen** (geht in die E-Mail)
2. `output/<datum>/digest.md` – ausführliche Fassung (bleibt im Tagesordner)

Beide aus derselben Lektüre erzeugen; die Kurzfassung ist keine Kürzung per Textschere,
sondern die Beschränkung auf das wirklich Wichtigste.

## Regeln (verbindlich)
- **Sprache:** Zusammenfassung immer auf Deutsch – auch bei englischen Podcasts
  (z. B. „The Rest Is Politics: US") den Inhalt auf Deutsch wiedergeben.
- **Umfang je Folge:** 3–6 stichpunktartige Kernaussagen + ein einzeiliges Kurzfazit.
- **Inhaltlich:** die wichtigsten Themen/Thesen, genannte Personen, Zahlen und
  Prognosen festhalten. Sachlich, nüchtern, keine Ausschmückung.
- **Kein Wort-für-Wort:** zusammenfassen, nicht zitieren.
- **Hörfehler stillschweigend korrigieren.** Die Transkription läuft mit einem schnellen,
  etwas ungenaueren Modell („base"). Erwartbar sind verhörte Wörter und Namen
  (z. B. „Waldbrinde" → Waldbrände, „Handels-Dad" → Handelsblatt, Personennamen
  ungenau). Wenn der Zusammenhang eindeutig ist: richtig schreiben. Bei **Zahlen und
  Namen, die sich nicht sicher erschließen**, lieber allgemeiner formulieren als etwas
  Falsches behaupten – nie raten.
- **Gruppierung:** nach Podcast; je Folge Titel, Dauer und Datum als Überschrift,
  mit Link zur Folge.

## Aufbau von `digest_kurz.md` (Kurzfassung – geht in die E-Mail)
```
# Podcast-Digest – <Wochentag, DD. Monat YYYY>

*Kurzüberblick: N neue Folgen aus M Podcasts.*

## <Podcast-Name>  ([Folge öffnen](Link))
- Kernpunkt 1
- Kernpunkt 2
- Kernpunkt 3
```
Regeln der Kurzfassung:
- **Höchstens 3–4 Bulletpoints je Podcast** – nicht je Folge. Hat ein Podcast mehrere
  neue Folgen, werden sie zu **einem** Block zusammengefasst (Links dann mehrfach hinter
  der Überschrift).
- Ein Bulletpoint = **ein Satz**, das Wichtigste zuerst. Zahlen/Namen nur, wenn sie den
  Kern tragen. **Kein Kurzfazit**, keine Folgentitel, keine Dauer.
- Streichen, was nur Beiwerk ist. Lieber 3 starke Punkte als 4 mit Füllung.

## Aufbau von `digest.md` (ausführliche Fassung – bleibt im Tagesordner)
```
# Podcast-Digest – <Wochentag, DD. Monat YYYY>

*Zusammenfassung von N neuen Folgen aus M Podcasts.*

## <Podcast-Name>
### <Folgentitel> · <Dauer> Min · <Datum>  ([Folge öffnen](Link))
- Kernaussage 1
- Kernaussage 2
- ...
*Kurzfazit: <ein Satz>.*
```
Hier gilt weiterhin: 3–6 Kernaussagen **je Folge** plus Kurzfazit.

Reihenfolge der Podcasts in beiden Dateien wie in `episodes.json`. Bei mehreren Folgen
eines Podcasts alle unter dessen Überschrift (neueste zuerst).

## Wenn keine neuen Folgen
Ist `episoden` in `episodes.json` leer: nur `output/<datum>/keine_folgen.txt` mit einer
Zeile schreiben, keine Digest-Dateien, keine E-Mail.
