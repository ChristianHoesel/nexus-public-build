#!/bin/bash
set -e

echo "🚀 Nexus Public Build Environment Setup"
echo "========================================"

# Installiere Yarn 1.22.22 (falls nicht vorhanden)
if ! command -v yarn &> /dev/null || [ "$(yarn --version)" != "1.22.22" ]; then
    echo "📦 Installiere Yarn 1.22.22..."
    npm install -g yarn@1.22.22
else
    echo "✅ Yarn 1.22.22 bereits installiert"
fi

# Verifiziere Installationen
echo ""
echo "✅ Installierte Versionen:"
echo "   Java: $(java -version 2>&1 | head -n 1)"
echo "   Node: $(node -v)"
echo "   NPM: $(npm -v)"
echo "   Yarn: $(yarn --version)"
echo "   Maven: $(mvn -v | head -n 1)"
echo "   Git: $(git --version)"

# Mache Build-Script ausführbar
echo ""
echo "🔧 Setze Berechtigungen..."
chmod +x build-local.sh

# Konfiguriere Git (falls noch nicht konfiguriert)
if ! git config --global user.name > /dev/null 2>&1; then
    echo ""
    echo "ℹ️  Git-Konfiguration nicht gefunden."
    echo "   Sie können diese später mit folgenden Befehlen setzen:"
    echo "   git config --global user.name 'Ihr Name'"
    echo "   git config --global user.email 'ihre.email@example.com'"
fi

echo ""
echo "✨ Setup abgeschlossen!"
echo ""
echo "🎯 Nächste Schritte:"
echo "   1. Build durchführen: ./build-local.sh release-3.84.1-01"
echo "   2. Oder direkt in GitHub Actions testen"
echo "   3. Docker Image bauen (optional)"
echo ""
