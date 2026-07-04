#!/usr/bin/env bash
# HomeStream bootstrap — turns a fresh Ubuntu 22.04/24.04 box (Oracle Cloud ARM,
# Hetzner, any VPS, an old PC) into a running Jellyfin + Jellyseerr server.
#
# Usage on the server:
#   git clone https://github.com/danielzaiser91/homestream.git
#   cd homestream
#   cp .env.example .env && nano .env      # fill in domains + email
#   sudo bash scripts/bootstrap.sh
#
# Safe to re-run: every step is idempotent.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

echo "==> HomeStream bootstrap starting in $REPO_DIR"

if [[ ! -f .env ]]; then
  echo "!! .env not found. Run:  cp .env.example .env  then edit it, then re-run."
  exit 1
fi

# --- 1. Docker + compose plugin ---------------------------------------------
if ! command -v docker >/dev/null 2>&1; then
  echo "==> Installing Docker Engine + Compose plugin"
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
else
  echo "==> Docker already installed"
fi

# --- 2. Media directory ------------------------------------------------------
# shellcheck disable=SC1091
source .env
MEDIA_PATH="${MEDIA_PATH:-/srv/media}"
echo "==> Ensuring media library at $MEDIA_PATH"
mkdir -p "$MEDIA_PATH/movies" "$MEDIA_PATH/shows"
# Jellyfin container runs as uid/gid 1000 by default.
chown -R 1000:1000 "$MEDIA_PATH" || true

# --- 3. Firewall (host-level) ------------------------------------------------
# Oracle/Ubuntu images ship with restrictive iptables. Open 80/443 so Caddy can
# get certificates and serve. (You ALSO must open 80+443 in the Oracle Cloud
# "Security List / NSG" in the web console — see docs/DEPLOY.md.)
echo "==> Opening host firewall ports 80 and 443"
if command -v iptables >/dev/null 2>&1; then
  iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport 80 -j ACCEPT
  iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport 443 -j ACCEPT
  # Persist across reboots if netfilter-persistent is available.
  if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save || true
  else
    apt-get update -y && apt-get install -y iptables-persistent || true
    netfilter-persistent save || true
  fi
fi

# --- 4. Launch ---------------------------------------------------------------
echo "==> Pulling images and starting the stack"
docker compose pull
docker compose up -d

echo ""
echo "============================================================"
echo " HomeStream is up."
echo "   Watch (Jellyfin):   https://${WATCH_DOMAIN}"
echo "   Request (Jellyseerr): https://${REQUEST_DOMAIN}"
echo ""
echo " First run: certificates take ~30s. Then open the Jellyfin URL,"
echo " complete the setup wizard, and add libraries pointing at:"
echo "   /media/movies   and   /media/shows"
echo " Copy your media into ${MEDIA_PATH}/movies and ${MEDIA_PATH}/shows."
echo "============================================================"
