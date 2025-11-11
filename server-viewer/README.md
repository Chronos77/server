# Server Viewer

Interface web unifiée pour visualiser les logs des serveurs en temps réel et consulter les détails complets des mobs/NMs.

## Prérequis

- Node.js (version 14 ou supérieure)
- npm
- Accès à la base de données MariaDB/MySQL du serveur (pour la fonctionnalité mobs)

Installation sur Ubuntu/Debian:
```bash
sudo apt install nodejs npm
```

## Installation

```bash
npm install
```

## Configuration

Par défaut, le serveur utilise les paramètres suivants pour la base de données:
- Host: 127.0.0.1
- Port: 3306
- User: root
- Password: root
- Database: xidb

Pour modifier ces paramètres, éditez les variables `dbConfig` dans `server.js`.

## Utilisation

### Mode manuel

```bash
node server.js
```

Ou utilisez le script:
```bash
./start.sh
```

Puis ouvrez votre navigateur à l'adresse: http://localhost:5000

### Installation en tant que service systemd (recommandé)

Pour que le service démarre automatiquement au boot et reste actif en permanence:

```bash
sudo ./install-service.sh
```

Le script va:
- Installer les dépendances si nécessaire
- Créer le service systemd
- Activer le démarrage automatique
- Démarrer le service

#### Commandes de gestion du service

```bash
# Démarrer le service
sudo systemctl start server-viewer.service

# Arrêter le service
sudo systemctl stop server-viewer.service

# Redémarrer le service
sudo systemctl restart server-viewer.service

# Voir le statut
sudo systemctl status server-viewer.service

# Voir les logs du service
sudo journalctl -u server-viewer.service -f

# Désactiver le démarrage automatique
sudo systemctl disable server-viewer.service

# Réactiver le démarrage automatique
sudo systemctl enable server-viewer.service
```

## Fonctionnalités

### 📊 Logs Viewer

- Affichage en temps réel de 4 logs simultanément:
  - Map Server
  - Search Server
  - Connect Server
  - World Server
- Mise à jour automatique (configurable: 1s, 2s, 5s, 10s)
- Pause/Play pour arrêter/reprendre les mises à jour
- Effacement des logs affichés
- Coloration syntaxique selon le niveau de log (error, warn, info, debug)
- Interface responsive et moderne

### 👹 Mobs Viewer

- **Recherche par ID**: Entrez directement l'ID du mob (ex: 16781313)
- **Recherche par nom**: Tapez un nom partiel et utilisez l'auto-complétion
- **Vue détaillée**: Affichage complet de toutes les informations disponibles:
  - Informations générales (zone, pool, family, etc.)
  - Statistiques de base (HP, MP, niveaux, etc.)
  - Statistiques de combat (jobs, skills, comportement)
  - Attributs (STR, DEX, VIT, AGI, INT, MND, CHR)
  - Défenses (DEF, ATT, ACC, EVA)
  - Résistances élémentaires (Fire, Ice, Wind, Earth, Lightning, Water, Light, Dark)
  - Résistances aux status (Paralyze, Bind, Silence, etc.)
  - SDT (Shield Defense Type) pour tous les types de dégâts
  - Informations de spawn (position, respawn time, etc.)
  - Liste des drops avec taux de drop
  - Points de spawn multiples
  - Mods du mob et de la famille

## Configuration

- **Port**: Par défaut 5000, peut être changé via la variable d'environnement `PORT`
  ```bash
  PORT=8080 node server.js
  ```

## Notes

- Les logs affichés sont les 200 dernières lignes de chaque fichier
- Le service redémarre automatiquement en cas d'erreur (toutes les 5 secondes)
- Si la base de données n'est pas disponible, seule la fonctionnalité logs sera accessible
- L'interface utilise des onglets pour basculer entre les logs et les mobs
- Les données des mobs sont récupérées directement depuis la base de données en temps réel
