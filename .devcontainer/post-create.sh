#!/bin/bash
set -e

echo "🚀 Nexus Public Build Environment Setup"
echo "========================================"

# Aktiviere Corepack für Yarn 4.x Unterstützung
echo "📦 Aktiviere Corepack für Yarn 4.x..."
corepack enable

# JAVA_HOME setzen
if [ -z "$JAVA_HOME" ]; then
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
    echo "export MAVEN_OPTS=\"-Xmx4g -XX:+UseG1GC\"" >> ~/.bashrc
    echo "✅ JAVA_HOME in ~/.bashrc gesetzt"
fi

# Verifiziere Installationen
echo ""
echo "✅ Installierte Versionen:"
echo "   Java: $(java -version 2>&1 | head -n 1)"
echo "   JAVA_HOME: $JAVA_HOME"
echo "   Node: $(node -v)"
echo "   NPM: $(npm -v)"
echo "   Corepack: $(corepack --version)"
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
