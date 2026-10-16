#!/usr/bin/env bash
# One-time bootstrap: creates the external Docker network/volumes and links .env into each stack.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "→ .env created from .env.example: fill it in, then run ./setup.sh again."
  exit 1
fi

docker network inspect media_net >/dev/null 2>&1 || docker network create media_net

for v in gluetun_data qbittorrent_config radarr_config sonarr_config jackett_config \
         bazarr_config flaresolverr_config jellyseerr_config jellyfin_config; do
  docker volume inspect "$v" >/dev/null 2>&1 || docker volume create "$v" >/dev/null
done

# docker compose reads .env from each stack's folder
for d in 01-vpn-torrent 02-media-backend 03-streaming cross-seed; do
  ln -sfn ../.env "$d/.env"
done

echo "✓ Network and volumes ready. Start in order:"
echo "  docker compose -f 01-vpn-torrent/docker-compose.yml up -d"
echo "  docker compose -f 02-media-backend/docker-compose.yml up -d"
echo "  docker compose -f 03-streaming/docker-compose.yml up -d"
echo "  docker compose -f cross-seed/docker-compose.yml up -d   # optional"
