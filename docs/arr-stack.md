# The *arr stack — what it is, what I left out, and how it works

This explains the "ultimate Plex stack" from the Reddit/GitHub links you started
with: the **\*arr** automation suite. Read this alongside
[docker-compose.arr.yml](../docker-compose.arr.yml).

## TL;DR on the legal line

The *arr apps are **legal, open-source software** for managing a media library.
What they're famous for is different: pointed at piracy indexers, they turn
"I want to watch movie X" into "X is downloaded, renamed, subtitled, and in my
library" with no further clicks. **Downloading copyrighted movies/TV you don't
own is infringement in most countries.** I built the media server, the request
UI, and the hosting — I did **not** wire up automated acquisition of copyrighted
content, and this overlay ships disabled. If you enable it, the indexers and
content you choose — and the legal consequences — are yours.

## The pieces and how they connect

```
        you pick a title
   ┌────────────────────────────┐
   │  Jellyseerr  (request UI)   │   "I want Interstellar"
   └───────────────┬────────────┘
                   ▼
   ┌────────────────────────────┐   Radarr = movies, Sonarr = TV.
   │  Radarr / Sonarr           │   Decides WHAT to fetch & at what quality,
   │  (library managers)        │   then asks Prowlarr to search.
   └───────┬─────────────┬──────┘
           ▼             ▼
   ┌───────────────┐   ┌────────────────────────────┐
   │  Prowlarr     │   │  Download client            │
   │ (indexer hub) │   │  qBittorrent (torrents) or  │
   │ searches all  │   │  SABnzbd/NZBGet (usenet)    │
   │ your indexers │──▶│  actually downloads the file│
   └───────────────┘   └───────────────┬────────────┘
                                       ▼
   ┌────────────────────────────────────────────────┐
   │ Radarr/Sonarr import: move + rename into /media │
   │ Bazarr: fetch subtitles                         │
   └───────────────────────┬────────────────────────┘
                           ▼
                 ┌───────────────────┐
                 │  Jellyfin serves  │  you watch
                 └───────────────────┘
```

| Component | Role |
|---|---|
| **Prowlarr** | Indexer manager. You add your indexers/trackers in ONE place; it syncs them to Radarr & Sonarr. (Older setups used *Jackett* for this.) |
| **Radarr** | Movie brain. Maintains a wanted-list, searches via Prowlarr, picks a release by your quality rules, hands it to the download client, then imports/renames it. |
| **Sonarr** | Same as Radarr but for TV — season/episode aware, and keeps monitoring shows for new episodes. |
| **Download client** | Does the actual transfer. **qBittorrent** (torrents) or **SABnzbd/NZBGet** (usenet). |
| **Bazarr** | Downloads subtitles for whatever Radarr/Sonarr imported. |
| **Jellyseerr** | The friendly request UI (already in the main stack). Feeds requests to Radarr/Sonarr. |
| **Jellyfin/Plex** | Serves and plays the finished library (already in the main stack). |
| *(optional)* **gluetun** | A VPN container; torrent clients are often routed through it. |
| *(optional)* **FlareSolverr** | Solves Cloudflare challenges some indexers put up. |
| *(optional)* **Recyclarr / TRaSH guides** | Community quality/naming profiles for Radarr/Sonarr. |

## What I already built vs. what I left out

**Already in HomeStream (legit):** Jellyfin (server), Jellyseerr (request UI),
Caddy (HTTPS), hosting. Jellyseerr is *half* of the automation — the "I want X"
front end — it just isn't connected to any auto-downloader.

**Deliberately not implemented:** Prowlarr, Radarr, Sonarr, the download client,
and Bazarr — i.e. everything that finds and downloads the actual video files.
The [docker-compose.arr.yml](../docker-compose.arr.yml) overlay contains these
apps (they're legal images) but no indexers and nothing enabled by default.

## How you'd make it work (the mechanism, format-agnostic)

If you run these — for a **legal** library (Linux ISOs, public-domain films,
Creative-Commons media, or content you own and are re-fetching) — the wiring is
the same regardless of source:

1. **Start the overlay:**
   `docker compose -f docker-compose.yml -f docker-compose.arr.yml up -d`
2. **Set a shared layout** so imports are instant hardlinks, not slow copies:
   keep downloads and the library under one mount (the TRaSH-guides `/data`
   layout: `/data/torrents` + `/data/media`). Adjust the volumes accordingly.
3. **Download client:** open qBittorrent, set its completed-downloads folder,
   set a strong admin password.
4. **Prowlarr:** add your indexers here. Add Radarr and Sonarr as "apps" so
   Prowlarr pushes indexers to them. *This is the step where legality is
   decided — which indexers you add.* Legal examples: an internal/public-domain
   tracker, a Linux-distro tracker, a usenet provider for legal content.
5. **Radarr/Sonarr:** add the download client, set root folders
   (`/media/movies`, `/media/shows`), pick quality profiles.
6. **Jellyseerr:** connect it to Radarr/Sonarr so a request auto-triggers a
   search (Settings → Services).
7. **Bazarr:** point it at the same root folders for subtitles.
8. **Jellyfin:** it already watches `/media`, so finished items just appear.

That's the whole loop: **request → search → download → import → subtitle →
watch**, hands-off.

## If you want a *large legal* library instead

There is no free-and-legal shortcut to "every movie ever," but real options:
rip discs you own (MakeMKV + HandBrake into H.264/HEVC MP4/MKV), buy DRM-free,
or pull from the big public-domain sources (Internet Archive, Blender open
movies). Radarr/Sonarr can still organize *those* for you — that's a genuinely
legitimate use of the exact same tools.
