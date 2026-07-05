#!/usr/bin/env python3
"""Import the on-disk /media/movies library into Radarr so Bazarr can manage
subtitles for every film — including ones added directly via FileBrowser or
fetch-archive-film.sh (which don't go through Radarr on their own).

Run it on the server after adding films:
    python3 /opt/homestream/scripts/import-library-to-radarr.py

It reads Radarr's API key from its config, lists every 'Title (Year)' folder,
adds any that Radarr doesn't track yet (matched to TMDB, no auto-search), and
rescans so the existing file gets linked. Idempotent — safe to re-run.

IMPORTANT: Radarr sees the library at the CONTAINER path /media/movies, not the
host path /srv/media/movies. This script stores the container path; getting that
wrong makes Radarr report 'root folder doesn't exist' and never link files.
"""
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

HOST_DIR = "/srv/media/movies"     # where we list folders on the host
CONT_DIR = "/media/movies"         # where Radarr sees them inside its container

sh = lambda c: subprocess.run(c, shell=True, capture_output=True, text=True).stdout.strip()
RKEY = sh("sudo grep -oP '(?<=<ApiKey>)[^<]+' /opt/homestream/config/radarr/config.xml")
RIP = sh("sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' radarr")
if not RKEY or not RIP:
    sys.exit("Could not read Radarr API key / container IP")
BASE = f"http://{RIP}:7878/api/v3"
H = {"X-Api-Key": RKEY, "Content-Type": "application/json"}


def req(path, method="GET", body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(BASE + path, data=data, headers=H, method=method)
    try:
        with urllib.request.urlopen(r, timeout=90) as resp:
            raw = resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]
    return 200, (json.loads(raw) if raw else None)


s, profiles = req("/qualityprofile")
prof_id = next((p["id"] for p in profiles if p["name"].lower() == "any"), profiles[0]["id"])
s, existing = req("/movie")
have_tmdb = {m["tmdbId"] for m in existing}

added = 0
for folder in sh(f"sudo ls -1 '{HOST_DIR}'").splitlines():
    m = re.match(r"^(.*)\((\d{4})\)\s*$", folder)
    if not m:
        print(f"[skip] {folder!r} is not 'Title (Year)'")
        continue
    title, year = m.group(1).strip(), int(m.group(2))
    s, results = req(f"/movie/lookup?{urllib.parse.urlencode({'term': f'{title} {year}'})}")
    if s != 200 or not results:
        print(f"[warn] no TMDB match for {title} ({year})")
        continue
    cand = next((r for r in results if r.get("year") == year), results[0])
    if cand["tmdbId"] in have_tmdb:
        continue
    body = {
        "title": cand["title"], "tmdbId": cand["tmdbId"], "year": cand["year"],
        "titleSlug": cand["titleSlug"], "images": cand.get("images", []),
        "qualityProfileId": prof_id, "monitored": True,
        "rootFolderPath": CONT_DIR, "path": f"{CONT_DIR}/{folder}",
        "addOptions": {"searchForMovie": False},
    }
    s, r = req("/movie", "POST", body=body)
    if s not in (200, 201):
        print(f"[warn] add failed {title}: {s} {r}")
        continue
    added += 1
    print(f"[ok] added {cand['title']} ({cand['year']})")

# Link existing files.
s, movies = req("/movie")
for mv in movies:
    if not mv["hasFile"]:
        req("/command", "POST", body={"name": "RescanMovie", "movieId": mv["id"]})
time.sleep(20)
s, movies = req("/movie")
withfile = sum(1 for m in movies if m["hasFile"])
print(f"\n[done] {added} added this run · Radarr now tracks {len(movies)} films, "
      f"{withfile} with a linked file.")
print("Next: Bazarr syncs from Radarr within ~1h (or trigger 'Sync with Radarr' "
      "in Bazarr) and fetches subtitles automatically.")
