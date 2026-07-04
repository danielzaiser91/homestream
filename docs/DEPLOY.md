# Deploying HomeStream on Oracle Cloud Always Free

This is the fully-free path: an always-on ARM VM that streams to ~4 people.
Budget ~45 minutes for a first-timer. Steps that MUST happen in the Oracle web
console (I can't do these for you — they need your account) are marked ⚙️.

---

## 0. What you'll end up with

- A Jellyfin server at `https://watch.<yourdomain>`
- A request/discovery UI at `https://request.<yourdomain>`
- Automatic HTTPS, restarts on reboot, ~200 GB for media.

## 1. ⚙️ Create the Oracle account & VM

1. Sign up at <https://www.oracle.com/cloud/free/>. It requires a credit card
   for identity verification but the Always Free resources are never charged.
2. **Create a VM instance:**
   - Shape: **VM.Standard.A1.Flex** (ARM Ampere). Always-Free budget as of
     June 2026 is **2 OCPU / 12 GB RAM** — set it to that.
   - Image: **Canonical Ubuntu 24.04**.
   - Boot volume: bump to **200 GB** (the free max) so you have room for media.
   - Download the SSH keypair when prompted.
   > Tip: free ARM capacity is often "out of capacity" in popular regions.
   > Pick a less-busy home region, or retry — a small script can help but the
   > console will eventually succeed.

## 2. ⚙️ Open the firewall (Security List)

Oracle blocks everything but SSH by default, in TWO places:

- **Cloud side:** VCN → your subnet → Security List → add **Ingress Rules**:
  - Source `0.0.0.0/0`, TCP, dest port **80**
  - Source `0.0.0.0/0`, TCP, dest port **443**
- **Host side:** handled automatically by `scripts/bootstrap.sh` (iptables).

## 3. Point a domain at the VM

Auto-HTTPS needs DNS names, not a bare IP. Free option:

1. Go to <https://www.duckdns.org>, sign in, create a subdomain e.g.
   `mystream` → gives `mystream.duckdns.org`.
2. Set its IP to your VM's **public IP** (shown on the instance page).
3. You'll use two names in `.env`:
   - `WATCH_DOMAIN=watch.mystream.duckdns.org`
   - `REQUEST_DOMAIN=request.mystream.duckdns.org`

   DuckDNS wildcard: point `*.mystream.duckdns.org` at the IP, or just create a
   second DuckDNS subdomain. (If you own a real domain, add two A records
   instead — cleaner.)

## 4. Install & launch

SSH in, then:

```bash
ssh -i /path/to/key ubuntu@<VM_PUBLIC_IP>

sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/danielzaiser91/homestream.git
cd homestream
cp .env.example .env
nano .env          # set the two domains, ACME_EMAIL, TZ, MEDIA_PATH=/srv/media
sudo bash scripts/bootstrap.sh
```

The script installs Docker, opens host ports, and starts the stack. Certs
appear ~30 seconds after the domains resolve.

## 5. First-run setup

1. Open `https://watch.mystream.duckdns.org` → Jellyfin wizard.
2. Create your admin user.
3. Add libraries:
   - **Movies** → folder `/media/movies`
   - **Shows** → folder `/media/shows`
4. Open `https://request.mystream.duckdns.org` → Jellyseerr wizard → connect it
   to your Jellyfin server (use the internal URL `http://jellyfin:8096`) and
   sign in with your Jellyfin admin account.

## 6. Add media

Copy files into the library (from your PC):

```bash
# movies: one folder per film
scp -i key "Big Buck Bunny (2008).mkv" \
    ubuntu@<IP>:/srv/media/movies/"Big Buck Bunny (2008)"/

# or mount a bigger disk / rclone from cloud storage for larger libraries
```

Jellyfin auto-scans and fetches artwork. Done.

## 7. Add up to 4 viewers

In Jellyfin → Dashboard → Users → add a user per person. They watch in any
browser or the free Jellyfin app (Android/iOS/Android TV/Fire TV/webOS). Tell
their apps to **prefer direct play** so the ARM box just serves bytes — that's
what keeps 4× 2K smooth with no GPU.

---

### Streaming smoothly at 2K for 4 people — the rules

- **Direct play only.** Encode/keep media as **H.264 or HEVC in MP4/MKV** with
  **AAC or AC3** audio. Then no CPU transcoding happens.
- Keep per-file bitrate ≲ 15–20 Mbps at 1440p. 4 × 15 Mbps = 60 Mbps egress,
  well within Oracle's headroom and the 10 TB/month cap.
- If a client forces a transcode (unusual codec/subtitles), the 2-OCPU ARM will
  struggle — fix the file or the client setting rather than the server.
