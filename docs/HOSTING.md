# Hosting reality check — where to run HomeStream

Your goal: **up to 2K, ~4 simultaneous viewers, no buffering, free.** Here's the
honest landscape after actually working the numbers.

## The bandwidth math (this part is easy and cheap)

| Quality | Bitrate/stream | 4 streams | Data for 2h film ×4 |
|---|---|---|---|
| 1080p | ~8 Mbps | 32 Mbps | ~29 GB |
| **1440p (2K)** | **~15 Mbps** | **60 Mbps** | **~54 GB** |
| 4K HDR | ~40 Mbps | 160 Mbps | ~144 GB |

At 2K, 4-way concurrent streaming needs ~60 Mbps sustained upload. Any real VPS
(1 Gbps uplink) laughs at that. Oracle's **10 TB/month** egress = **~370 hours**
of 4 people watching 2K at once. **Bandwidth is not your constraint.**

## The two real constraints

1. **Storage.** Movies are big (2K ≈ 4–8 GB each; a season of TV similar).
2. **Transcoding.** If a client can't play a file natively, the server must
   re-encode it live — CPU-heavy, and brutal without a GPU. The fix is *direct
   play* (right formats), not more hardware.

## Options ranked for your goal

### 🥇 Oracle Cloud Always Free — best truly-free option
- **Cost:** $0 forever (card for verification, never charged).
- **Specs (post-June-2026):** 2 ARM OCPU, 12 GB RAM, **200 GB** storage, 10 TB
  egress.
- **Streams:** 4× 2K **direct play** = fine. Transcoding = no (no GPU).
- **Catch:** 200 GB ≈ 10–30 films. Great for a curated library, not "everything."
- **Catch:** free ARM capacity can be hard to grab in busy regions; retry.

### 🥈 Cheap VPS + block storage — best "unlimited library"
- **Hetzner** CX22 (~€4/mo) or CAX ARM, plus a **Storage Box** (1 TB ~€3.9/mo,
  5 TB ~€12/mo) mounted over SMB/SSHFS. This is what most self-hosters actually
  run. ~€8–16/mo buys a large library with smooth 4× streaming.
- **Cost:** not free, but the only path to a big library.

### 🥉 Your own hardware at home — free if you have a spare PC
- An old desktop / mini-PC / Raspberry Pi 5 running this same compose file.
- **Storage:** as big as the disks you plug in (cheapest per TB by far).
- **Catch:** your *home upload* speed is now the limit. 4× 2K needs ~60 Mbps
  **upload** — many home connections don't have that. Check yours first.
- Add a free **Cloudflare Tunnel** or the Caddy setup here for remote access.

### ❌ What does NOT work (so you don't waste time)
- **GitHub Pages / Vercel / Netlify:** static hosting only — cannot run a media
  server or store video. (We *do* use GitHub Pages, but only for the portal page.)
- **Free "app platform" tiers** (Render/Railway/Fly free): no persistent
  multi-hundred-GB volumes, they sleep on idle, and streaming egress blows past
  free limits. Railway's Jellyfin template exists but you pay for usage.
- **"Free unlimited storage + streaming" hosts:** don't exist. If one advertises
  it, it's a trap (bandwidth caps, sudden bans, or it's a piracy front).

## Recommendation

Start on **Oracle Always Free** with a curated 2K library — it fully meets
"4 people, 2K, no buffering, $0." When you outgrow 200 GB, move the compose file
to a **Hetzner VPS + Storage Box** for a few euros a month. Nothing else in the
setup changes.
