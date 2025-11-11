#!/bin/bash
# Script de démarrage pour le log viewer

cd "$(dirname "$0")"

echo "🚀 Démarrage du Log Viewer..."
echo ""

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ Node.js n'est pas installé"
    echo "   Installation: sudo apt install nodejs npm"
    exit 1
fi

# Vérifier si les dépendances sont installées
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
fi

# Démarrer le serveur
echo "✅ Serveur démarré sur http://localhost:5000"
echo "📝 Ouvrez votre navigateur pour voir les logs"
echo ""
node server.js

