# 🎬 Self-Hosted Cinema Stack

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![WireGuard](https://img.shields.io/badge/wireguard-881798?style=for-the-badge&logo=wireguard&logoColor=white)](https://www.wireguard.com/)
[![Jellyfin](https://img.shields.io/badge/jellyfin-%2300A4DC.svg?style=for-the-badge&logo=Jellyfin&logoColor=white)](https://jellyfin.org/)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://www.kernel.org/)
[![Radarr](https://img.shields.io/badge/radarr-%23CCAA2B.svg?style=for-the-badge&logo=radarr&logoColor=white)](https://radarr.video/)
[![Sonarr](https://img.shields.io/badge/sonarr-%2389C5CF.svg?style=for-the-badge&logo=sonarr&logoColor=white)](https://sonarr.tv/)
[![qBittorrent](https://img.shields.io/badge/qBittorrent-%232D72D9.svg?style=for-the-badge&logo=qbittorrent&logoColor=white)](https://www.qbittorrent.org/)
[![Gluetun](https://img.shields.io/badge/Gluetun-%231E232E.svg?style=for-the-badge)](https://github.com/qdm12/gluetun)
[![Jackett](https://img.shields.io/badge/Jackett-%231E232E.svg?style=for-the-badge)](https://github.com/Jackett/Jackett)
[![Cross-Seed](https://img.shields.io/badge/Cross--Seed-%232A2A2A.svg?style=for-the-badge)](https://www.cross-seed.org/)

Ce dépôt contient l'Infrastructure as Code (IaC) de mon serveur média personnel automatisé. Il regroupe la configuration complète de ma stack P2P, de mes outils de gestion (*Arrs*) et de mon serveur de streaming, le tout optimisé et sécurisé via Docker.

Le but de cette infrastructure est d'offrir une expérience de type "Netflix privé" (via Jellyseerr et Jellyfin) tout en maintenant un ratio P2P parfait grâce à une automatisation du cross-seeding, sans aucune duplication de fichiers.

---

## 🌟 Fonctionnalités Clés (Key Features)

* 🛡️ **VPN Killswitch Absolu :** Le client torrent (qBittorrent) ne possède aucune interface réseau propre. Il est entièrement greffé sur le conteneur VPN (Gluetun via WireGuard). Si le VPN tombe, les flux sont coupés instantanément, les fuites d'IP sont bloquées.
* ♻️ **Cross-Seeding & Zéro Duplication :** Automatisation avec `cross-seed` configuré en "Injection sur place" (*In-place injection*). Le système seed automatiquement sur plusieurs trackers privés en utilisant un seul et unique fichier physique.
* 🚀 **Transcodage GPU & RAM :** Jellyfin est configuré pour utiliser l'accélération matérielle Intel (`/dev/dri`) et transcode directement dans la mémoire vive (`/dev/shm`), préservant ainsi la durée de vie des disques SSD/HDD.
* 🔒 **Cloisonnement Réseau :** Tous les conteneurs communiquent de manière isolée sur un réseau Docker interne (`media_net`).

---

## 🛑 Sécurité & Reverse Proxy (Prérequis)

**Avertissement :** Vous remarquerez que la directive `ports:` est absente de la totalité des services dans les fichiers `docker-compose.yml`. **C'est un choix de design.**

Pour des raisons de sécurité, aucun port web n'est exposé directement sur la machine hôte. Tous les services communiquent entre eux via le réseau interne `media_net`. Pour accéder aux interfaces Web (Radarr, Jellyfin, qBittorrent, etc.) depuis l'extérieur, **vous devez placer cette stack derrière un Reverse Proxy** (comme Traefik, Nginx Proxy Manager, ou un tunnel Cloudflare) connecté à ce même réseau `media_net`.

---

## 🔌 Récapitulatif des Ports Internes

Voici le tableau de routage à utiliser dans votre Reverse Proxy pour pointer vers les bons services au sein du réseau Docker :

| Service | Conteneur cible | Port interne | Description |
| :--- | :--- | :--- | :--- |
| **Jellyseerr** | `jellyseerr` | `5055` | Interface web des requêtes utilisateurs |
| **Jellyfin** | `jellyfin` | `8096` | Lecteur média et administration |
| **Sonarr** | `sonarr` | `8989` | Gestionnaire de Séries TV |
| **Radarr** | `radarr` | `7878` | Gestionnaire de Films |
| **Bazarr** | `bazarr` | `6767` | Gestionnaire de Sous-titres |
| **Jackett** | `jackett` | `9117` | API Torznab & Indexeurs |
| **qBittorrent** | `qbittorrent` | `8080` | Client Torrent WebUI (via Gluetun) |
| **Cross-seed** | `cross-seed` | `2468` | API du daemon de cross-seeding |
| **FlareSolverr** | `flaresolverr` | `8191` | *Contournement Cloudflare (Usage interne uniquement)* |

---

## 📂 Architecture du Dépôt

L'infrastructure est divisée en 3 stacks distinctes pour faciliter la maintenance :

1.  **`01-vpn-torrent/`** : Le tunnel WireGuard et qBittorrent.
2.  **`02-media-backend/`** : Le cerveau de l'opération (Arrs, Jackett, Bazarr...).
3.  **`03-streaming/`** : La diffusion et les requêtes (Jellyfin, Jellyseerr).
4.  **`cross-seed/`** : Optionnel : permet d'optimiser vos uploads en seedant les mêmes fichiers sur plusieurs sources différentes

Vous trouverez les différentes stacks dans les dossiers, notamment les docker-compose pour déployer cette infrastructure.
Les guides seront ajoutés plus tard pour vous guider dans le déploiement spécifique de chaque élément.
