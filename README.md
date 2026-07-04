# HomeStream / HomeFlix 🎬

Two things in one repo:

1. **HomeFlix** — a live, Netflix-style streaming **web app** you can open and
   watch right now: billboard, genre rows, click-to-play player, search. Runs
   fully static on GitHub Pages, streaming a catalog of verified public-domain
   films. **▶ Watch: https://danielzaiser91.github.io/homestream/**
2. **HomeStream** — a free, self-hosted media-server stack (**Jellyfin** +
   **Jellyseerr** + **Caddy**) for *your own* library, deployable to a free
   Oracle Cloud ARM box, tuned to stream **2K to ~4 people at once**.
   Guide: [/about.html](https://danielzaiser91.github.io/homestream/about.html).

---

## Why this stack (July 2026)

| Choice | Reason |
|---|---|
| **Jellyfin**, not Plex | Plex now paywalls remote streaming *and* hardware transcoding, and its lifetime pass jumped to **$749.99**. Jellyfin is free forever, open source, nothing phones home. |
| **Jellyseerr** | Netflix-style discovery UI so non-technical users can browse and request titles instead of touching the server. |
| **Caddy** | Automatic Let's Encrypt HTTPS with a 6-line config. |
| **Direct-play design** | The free ARM tier has no GPU. Keep files in client-friendly formats (H.264/HEVC MP4/MKV) and no transcoding is needed even at 2K — smooth for 4 concurrent streams. |

## The honest limits (read before you deploy)

- **Free streaming works. Free *unlimited storage* does not.** Oracle's Always
  Free tier gives an always-on VM with 10 TB/month egress (≈370 hours of 4
  simultaneous 2K streams) but only **200 GB storage** (~10–30 movies at 2K).
  A bigger library means paid storage (a Hetzner Storage Box + VPS, ~€5–15/mo,
  is the realistic "unlimited" answer). See [docs/HOSTING.md](docs/HOSTING.md).
- **This repo does not download copyrighted content.** It is the server + UI +
  hosting only. Point it at media you own or acquire legally (your own DVD/Blu-ray
  rips, public-domain films, DRM-free purchases). See [docs/LEGAL.md](docs/LEGAL.md).

## Quick start

```bash
# On a fresh Ubuntu 22.04/24.04 server (Oracle ARM, Hetzner, old PC…):
git clone https://github.com/danielzaiser91/homestream.git
cd homestream
cp .env.example .env      # set your two domains + email + media path
nano .env
sudo bash scripts/bootstrap.sh
```

Then open `https://watch.<yourdomain>`, finish the Jellyfin wizard, add
libraries pointing at `/media/movies` and `/media/shows`, and drop your files
into the media folder. Full walkthrough: [docs/DEPLOY.md](docs/DEPLOY.md).

## Repo layout

```
docs/index.html        HomeFlix — the live Netflix-style streaming app
docs/catalog.json      36 verified public-domain films the app streams
docs/version.json      version marker for the auto-update watcher
docs/about.html        HomeStream self-host portal (the deploy guide, styled)
docker-compose.yml     Jellyfin + Jellyseerr + Caddy (self-host)
docker-compose.arr.yml OPTIONAL *arr automation overlay (read docs/arr-stack.md)
Caddyfile              reverse proxy + auto-HTTPS
.env.example           config template (copy to .env)
scripts/bootstrap.sh   one-command setup for a fresh Ubuntu box
scripts/release.sh     stamp + push a new HomeFlix version (triggers auto-update)
docs/DEPLOY.md         Oracle Cloud Always Free step-by-step
docs/HOSTING.md        honest host comparison + bandwidth math
docs/arr-stack.md      what the *arr stack is, and what was left out (& why)
docs/LEGAL.md          what content is legitimate to add
```
