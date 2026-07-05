#!/usr/bin/env bash
# fetch-archive-film.sh — reliably add a public-domain film from the Internet
# Archive straight into the Jellyfin library over HTTPS.
#
# WHY THIS EXISTS: the optional *arr stack can *find* Internet-Archive titles, but
# archive.org distributes them as BitTorrent with per-item webseeds that often
# time out and ~zero real seeders, so torrents stall near 100%. Direct HTTP is
# the robust path for archive.org, so this is the recommended way to add a
# legal public-domain film. (Only use it for genuinely public-domain content.)
#
# Usage:
#   fetch-archive-film.sh <archive.org-identifier> "<Title>" <Year>
# Example:
#   fetch-archive-film.sh night_of_the_living_dead "Night of the Living Dead" 1968
#
# It picks the largest .mp4 in the item, saves it as
#   /srv/media/movies/<Title> (<Year>)/<Title> (<Year>).mp4
# fixes ownership, and triggers a Jellyfin library scan.
set -euo pipefail

ID="${1:?identifier required}"
TITLE="${2:?title required}"
YEAR="${3:?year required}"

MEDIA_ROOT="/srv/media/movies"
JELLYFIN_URL="https://watch.daniel-flix.duckdns.org"
# API key lives in the compose config; read it from the env or a token file.
JELLYFIN_TOKEN="${JELLYFIN_TOKEN:-$(cat /opt/homestream/.jellyfin-token 2>/dev/null || true)}"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

echo ">> Looking up files for archive.org item: $ID"
# Largest .mp4 (falls back to .mkv/.avi/.ogv) that is an original/derivative video.
FILE=$(curl -fsSL -A "$UA" "https://archive.org/metadata/$ID/files" \
  | python3 -c '
import json, sys
meta = json.load(sys.stdin)
files = meta.get("result", [])
if not files:
    sys.exit("Item has no files (moved/darkened identifier?)")

def size(f): return int(f.get("size", 0) or 0)

# Prefer a Direct-Play-friendly H.264 MP4 (no server-side transcoding needed on
# the GPU-less ARM box). Skip giant remuxes (.mkv/.m2ts multi-GB) and the tiny
# 512kb proxies. Sweet spot: 250 MB .. 3 GB h.264 mp4; largest such wins.
mp4 = [f for f in files if f.get("name","").lower().endswith(".mp4")]
h264 = [f for f in mp4
        if "h.264" in (f.get("format","").lower())
        and 250_000_000 <= size(f) <= 3_000_000_000]
pool = h264 or [f for f in mp4 if 100_000_000 <= size(f) <= 3_000_000_000] or mp4
if not pool:
    sys.exit("No suitable mp4 found in item")
print(max(pool, key=size)["name"])')

echo ">> Chosen file: $FILE"
EXT="${FILE##*.}"
DEST_DIR="$MEDIA_ROOT/$TITLE ($YEAR)"
DEST="$DEST_DIR/$TITLE ($YEAR).$EXT"

sudo mkdir -p "$DEST_DIR"
# URL-encode the path segment (spaces etc.) the way archive.org expects.
ENC_FILE=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$FILE")

echo ">> Downloading -> $DEST"
sudo curl -fL --retry 3 --retry-delay 5 -A "$UA" \
  -o "$DEST" "https://archive.org/download/$ID/$ENC_FILE"

sudo chown -R 1000:1000 "$DEST_DIR"
echo ">> Saved $(sudo du -h "$DEST" | cut -f1)"

if [ -n "$JELLYFIN_TOKEN" ]; then
  echo ">> Triggering Jellyfin library scan"
  curl -fsS -X POST -H "X-Emby-Token: $JELLYFIN_TOKEN" \
    "$JELLYFIN_URL/Library/Refresh" && echo " ok"
else
  echo ">> No Jellyfin token set — scan the library from the dashboard, or set"
  echo "   JELLYFIN_TOKEN / write it to /opt/homestream/.jellyfin-token"
fi
echo ">> Done: $TITLE ($YEAR)"
