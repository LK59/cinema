# ❎ Déploiement de Cross-Seed (In-Place Injection)

Ce document décrit la mise en place de `cross-seed` dans un environnement Dockerisé avec Sonarr, Radarr, Jackett et qBittorrent (derrière le VPN Gluetun).

L'objectif de cette configuration est l'**injection sur place (In-Place Injection)** : `cross-seed` ne crée aucun dossier, ne copie aucun fichier et ne génère aucun hardlink. Il se contente d'indiquer à qBittorrent d'utiliser les fichiers médias déjà existants.

---

## 🏗️ Architecture et Prérequis

* **qBittorrent** : Routé à travers un conteneur VPN (`gluetun:8080`).
* **Jackett** : Fournit les flux Torznab (`jackett:9117`).
* **Radarr / Sonarr** : Utilisés pour la correspondance précise des ID (IMDB/TMDB).
* **Pas de montage média** : Le conteneur `cross-seed` n'a pas besoin d'accéder aux dossiers de vidéos (`ex : /mnt/media/video`), seul qBittorrent gère les fichiers.

---

## 🐋 1. Fichier `docker-compose.yml`

Voici un compose exemple du service `cross-seed`. Puisqu'il n'interagit qu'avec les API des autres services, il ne nécessite que le montage de son propre dossier de configuration. Modifiez le réseau Docker et les chemins selon votre configuration.

```yaml
services:
  cross-seed:
      image: ghcr.io/cross-seed/cross-seed:latest
      container_name: cross-seed
      user: "1000:1000" # A changer selon votre utilisateur
      environment:
        - TZ=Europe/Paris
      volumes:
        - /votre/dossier/config/cross-seed-config:/config
      networks:
        - media_net
      restart: unless-stopped
      command: daemon

networks:
  media_net:
    external: true
```

---

## ⚙️ 2. Configuration (`config.js`)

Générez le fichier de configuration initial (en lançant le conteneur une première fois, il sera en erreur, c'est normal), puis modifiez uniquement les variables ci-dessous. dans le fichier : /votre/dossier/config/cross-seed-config/config.js.
Le fichier config.js sera préfait, ne créez pas de nouvelles lignes, modifiez les lignes existantes

> ⚠️ **Sécurité** : Remplacez les `VOTRE_API_KEY` et mots de passe par vos véritables identifiants.

### Les Connexions (API & Clients)

* **`torznab`** : Liez vos indexeurs configurés dans Jackett. (vous pouvez en supprimer ou en ajouter en fonction de vos indexeurs)

```javascript
torznab: [
    "http://jackett:9117/api/v2.0/indexers/INDEXER1/results/torznab/api?apikey=VOTRE_API_KEY_JACKETT",
    "http://jackett:9117/api/v2.0/indexers/INDEXER2/results/torznab/api?apikey=VOTRE_API_KEY_JACKETT",
    "http://jackett:9117/api/v2.0/indexers/INDEXER3/results/torznab/api?apikey=VOTRE_API_KEY_JACKETT"
],

```

* **`sonarr` & `radarr`** : Pour une correspondance parfaite basée sur les ID (et non juste le texte).

```javascript
sonarr: ["http://sonarr:8989/?apikey=VOTRE_API_KEY_SONARR"],
radarr: ["http://radarr:7878/?apikey=VOTRE_API_KEY_RADARR"],

```

* **`torrentClients`** : Connexion à qBittorrent via Gluetun. Pensez à encoder les caractères spéciaux de votre mot de passe (ex: `%40` pour `@`).

```javascript
torrentClients: ["qbittorrent:http://admin:VOTRE_MOT_DE_PASSE@gluetun:8080/"],

```

### La Stratégie de Correspondance (Match & Link)

* **`matchMode: "strict"`**
*Crucial.* Étant donné qu'il n'y a pas de dossier de liens physiques, les fichiers doivent correspondre à 100 % au bit près pour que l'injection sur place fonctionne.
* **`linkDirs: []`**
Tableau vide. Interdit à `cross-seed` de créer des hardlinks.
* **`action: "inject"`**
Envoie directement le fichier `.torrent` à qBittorrent.

### Prévention des boucles avec Sonarr/Radarr

Pour éviter que Radarr et Sonarr ne détectent les nouvelles injections comme des téléchargements terminés et bloquent leur file d'attente, il faut isoler les cross-seeds dans une catégorie invisible pour eux.

* **`duplicateCategories: true`**
Crée une catégorie dérivée (ex: `tv.cross-seed`).

### Économie d'API

* **`includeSingleEpisodes: false`**
Évite de gaspiller vos limites d'API (Search Limit) en cherchant de vieux épisodes à l'unité qui ont probablement été supprimés (trumped) des trackers au profit des "Season Packs". Par défaut ce réglage est sur false, si vous voulez cross-seeder des épisodes uniques, passez en `true`

---

## 🛠️ 3. Configuration dans qBittorrent

Pour que l'injection sur place fonctionne sans erreur :

1. Ouvrez l'interface Web de qBittorrent.
2. Faites un clic droit dans le panneau des catégories (à gauche) > **Ajouter une catégorie**.
3. Nom : `categorie_actuelle.cross-seed` (ex : movie.cross-seed - cross-seed est déjà supposé créer automatiquement les catégories).
4. **Chemin de sauvegarde (Save path) : LAISSER STRICTEMENT VIDE.** (Si vous créez manuellement la catégorie)
* *Si un chemin est renseigné, qBittorrent tentera de déplacer physiquement le fichier, ce qui cassera l'organisation de vos médias et le seed.*



---

## 🛫 4. Démarrage et Maintenance

1. Démarrez le conteneur : `docker-compose up -d cross-seed`


2. Laissez le démon tourner. Il scannera les flux RSS toutes les 10 minutes et fera une recherche approfondie quotidienne (limité à 400 requêtes pour protéger vos comptes trackers).

