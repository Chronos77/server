#!/bin/bash

# Script d'installation du service systemd pour server-viewer

SERVICE_NAME="server-viewer.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="/home/ubuntu/projects/server/server-viewer"

# Vérifier les permissions root
if [ $EUID != 0 ]; then
    echo "⚠️  Permissions root requises, démarrage avec sudo..."
    chmod +x "$0"
    exec sudo -E "$0" "$@"
fi

echo "📦 Installation du service systemd pour Server Viewer..."
echo ""

# Vérifier si le service existe déjà
if [ -e "$SERVICE_FILE" ]; then
    echo "⚠️  Le service existe déjà!"
    if [ -t 0 ]; then
        read -p "Voulez-vous le réinstaller? (o/N): " -r
        if [[ ! $REPLY =~ ^[Oo]$ ]]; then
            echo "❌ Installation annulée"
            exit 1
        fi
    else
        echo "⚠️  Mode non-interactif: réinstallation automatique..."
    fi
    systemctl stop $SERVICE_NAME 2>/dev/null || true
    systemctl disable $SERVICE_NAME 2>/dev/null || true
fi

# Vérifier que le répertoire existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Erreur: Le répertoire $PROJECT_DIR n'existe pas"
    exit 1
fi

# Vérifier que Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ Erreur: Node.js n'est pas installé"
    echo "   Installation: sudo apt install nodejs npm"
    exit 1
fi

# Installer les dépendances Node.js si nécessaire
echo "📦 Vérification des dépendances Node.js..."
cd "$PROJECT_DIR"
if [ ! -d "node_modules" ]; then
    echo "   Installation des dépendances npm..."
    npm install --silent || {
        echo "❌ Erreur lors de l'installation des dépendances"
        exit 1
    }
fi

# Trouver le chemin de Node.js
NODE_PATH=$(which node)
if [ -z "$NODE_PATH" ]; then
    echo "❌ Erreur: Impossible de trouver Node.js"
    exit 1
fi

# Créer le fichier de service
echo "📝 Création du fichier de service..."
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Server Viewer - Interface web unifiée pour visualiser les logs et les mobs/NMs
After=network.target
Wants=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
User=ubuntu
Group=ubuntu
WorkingDirectory=$PROJECT_DIR
Environment="PATH=/usr/bin:/usr/local/bin"
ExecStart=$NODE_PATH $PROJECT_DIR/server.js
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Définir les permissions
chmod 644 "$SERVICE_FILE"

# Recharger systemd
echo "🔄 Rechargement de systemd..."
systemctl daemon-reload

# Activer le service pour le démarrage automatique
echo "✅ Activation du service au démarrage..."
systemctl enable $SERVICE_NAME

echo ""
echo "✅ Service installé avec succès!"
echo ""
echo "📋 Commandes utiles:"
echo "   Démarrage:     sudo systemctl start $SERVICE_NAME"
echo "   Arrêt:         sudo systemctl stop $SERVICE_NAME"
echo "   Redémarrage:   sudo systemctl restart $SERVICE_NAME"
echo "   Statut:        sudo systemctl status $SERVICE_NAME"
echo "   Logs:          sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "🚀 Le service démarrera automatiquement au prochain reboot."
read -p "Voulez-vous démarrer le service maintenant? (O/n): " -r
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    systemctl start $SERVICE_NAME
    sleep 2
    systemctl status $SERVICE_NAME --no-pager
    echo ""
    echo "🌐 Interface disponible sur: http://localhost:5000"
fi

