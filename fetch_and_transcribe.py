"""
Prueft die Podcast-Feeds, findet NEUE Folgen (innerhalb Zeitfenster, noch nicht
verarbeitet), laedt die Audiodatei und transkribiert sie lokal (faster-whisper).
Ergebnis: output/<datum>/episodes.json (Metadaten + Transkript-Pfad je Folge) und
die Transkripte in output/<datum>/transcripts/. Die Zusammenfassung erstellt danach
Claude auf Basis dieser Dateien.

Aufruf:  python fetch_and_transcribe.py [--tage N] [--nur key1,key2]
"""
import argparse
import json
import sys
import time
import urllib.request
from datetime import datetime, timezone, timedelta
from pathlib import Path

import feedparser
from faster_whisper import WhisperModel

BASE = Path(__file__).parent
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/126.0 Safari/537.36")
# Whisper-Modell. Gemessen am 28.07.2026 an einer 10-Minuten-Folge (CPU, int8):
#   "small" :  92 s (6,9x Echtzeit) - sauberere Eigennamen und Fachbegriffe
#   "base"  :  30 s (21x Echtzeit)  - rund 3x schneller, dafuer mehr Hoerfehler
#              (z. B. "Waldbrinde" statt "Waldbraende", Namen ungenauer)
# Auf Wunsch HJS steht es auf "base"; Claude korrigiert die meisten Fehler beim
# Zusammenfassen aus dem Zusammenhang. Zum Zurueckstellen einfach "small" eintragen.
MODEL = "base"
# cpu_threads bewusst NICHT gesetzt: Der Test zeigte, dass mehr Threads (16) das
# Ganze sogar verlangsamen - die Bibliothek waehlt selbst die guenstigste Zahl.
MAX_STATE = 60           # je Podcast max. so viele verarbeitete IDs merken


def load_json(path, default):
    if path.exists():
        return json.load(open(path, encoding="utf-8"))
    return default


def entry_time(entry):
    for key in ("published_parsed", "updated_parsed"):
        t = entry.get(key)
        if t:
            return datetime.fromtimestamp(time.mktime(t), tz=timezone.utc)
    return None


def enclosure(entry):
    for enc in entry.get("enclosures", []):
        if enc.get("href"):
            return enc["href"]
    return None


def download(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as r, open(dest, "wb") as f:
        while True:
            chunk = r.read(65536)
            if not chunk:
                break
            f.write(chunk)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tage", type=int, default=2, help="Zeitfenster in Tagen")
    ap.add_argument("--nur", type=str, default="", help="nur diese keys (kommagetrennt)")
    args = ap.parse_args()
    only = set(x.strip() for x in args.nur.split(",") if x.strip())

    cfg = load_json(BASE / "podcasts.json", {"podcasts": []})
    state = load_json(BASE / "state.json", {})
    cutoff = datetime.now(timezone.utc) - timedelta(days=args.tage)
    today = datetime.now().strftime("%Y-%m-%d")
    out_dir = BASE / "output" / today
    tdir = out_dir / "transcripts"
    tdir.mkdir(parents=True, exist_ok=True)

    # Erst pruefen, welche Folgen neu sind (bevor das Modell geladen wird)
    todo = []
    for pod in cfg["podcasts"]:
        if only and pod["key"] not in only:
            continue
        done = set(state.get(pod["key"], []))
        feed = feedparser.parse(pod["feed"], request_headers={"User-Agent": UA})
        for e in feed.entries:
            ts = entry_time(e)
            eid = e.get("id") or e.get("link") or e.get("title")
            if ts and ts < cutoff:
                continue
            if eid in done:
                continue
            url = enclosure(e)
            if not url:
                continue
            todo.append({"pod": pod, "eid": eid, "titel": e.get("title", ""),
                         "link": e.get("link", ""),
                         "datum": ts.isoformat() if ts else None, "url": url})

    print(f"Neue Folgen: {len(todo)}")
    for t in todo:
        print(f"  - {t['pod']['name']}: {t['titel'][:60]}")

    episodes = []
    if todo:
        print(f"Lade Whisper-Modell '{MODEL}' ...")
        model = WhisperModel(MODEL, device="cpu", compute_type="int8")

        for i, t in enumerate(todo, 1):
            pod = t["pod"]
            print(f"[{i}/{len(todo)}] {pod['name']}: laden + transkribieren ...")
            mp3 = tdir / f"{pod['key']}_{i}.mp3"
            try:
                download(t["url"], mp3)
                t0 = time.time()
                segments, info = model.transcribe(str(mp3), language=pod["sprache"], beam_size=1)
                text = " ".join(s.text.strip() for s in segments)
                dt = time.time() - t0
                print(f"      {info.duration/60:.1f} Min Audio -> {len(text)} Zeichen ({dt:.0f}s)")
            except Exception as e:  # noqa: BLE001
                print(f"      FEHLER: {e}")
                continue
            finally:
                if mp3.exists():
                    mp3.unlink()   # Audiodatei nach Transkription loeschen (Platz sparen)

            tfile = tdir / f"{pod['key']}_{i}.txt"
            tfile.write_text(text, encoding="utf-8")
            episodes.append({
                "podcast": pod["name"], "key": pod["key"],
                "titel": t["titel"], "link": t["link"], "datum": t["datum"],
                "sprache": pod["sprache"], "dauer_min": round(info.duration / 60, 1),
                "transkript": str(tfile.relative_to(out_dir)),
            })
            state.setdefault(pod["key"], [])
            state[pod["key"]] = ([t["eid"]] + state[pod["key"]])[:MAX_STATE]

    (out_dir / "episodes.json").write_text(
        json.dumps({"erstellt": datetime.now().isoformat(timespec="seconds"),
                    "episoden": episodes}, ensure_ascii=False, indent=2), encoding="utf-8")
    json.dump(state, open(BASE / "state.json", "w", encoding="utf-8"),
              ensure_ascii=False, indent=2)
    print(f"\nFertig: {len(episodes)} Folgen transkribiert -> {out_dir / 'episodes.json'}")


if __name__ == "__main__":
    main()
