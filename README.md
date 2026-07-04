# HomeStream 🎬

A free, self-hosted media server you actually own — **Jellyfin** for playback,
**Jellyseerr** for a friendly "browse & request" UI, and **Caddy** for
automatic HTTPS. Deployable to a free Oracle Cloud ARM box or any cheap VPS,
tuned to stream up to **2K to ~4 people at once** without buffering.

**Live portal & deploy guide:** https://danielzaiser91.github.io/homestream/

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
docker-compose.yml   Jellyfin + Jellyseerr + Caddy
Caddyfile            reverse proxy + auto-HTTPS
.env.example         config template (copy to .env)
scripts/bootstrap.sh one-command setup for a fresh Ubuntu box
docs/DEPLOY.md       Oracle Cloud Always Free step-by-step
docs/HOSTING.md      honest host comparison + bandwidth math
docs/LEGAL.md        what content is legitimate to add
docs/index.html      the GitHub Pages portal
```
