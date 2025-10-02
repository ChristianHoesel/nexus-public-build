#!/bin/bash
set -e

# Lokales Build-Script für Nexus OSS
# Verwendung: ./build-local.sh [version]

VERSION=${1:-"release-3.84.1-01"}
NEXUS_DIR="nexus-public"

echo "========================================"
echo "Nexus OSS Local Build Script"
echo "========================================"
echo "Version: $VERSION"
echo ""

# Prüfe Voraussetzungen
check_requirements() {
    echo "Prüfe Build-Voraussetzungen..."
    
    # Java Version prüfen
    if ! command -v java &> /dev/null; then
        echo "❌ Java nicht gefunden. Bitte installieren Sie Java 17."
        exit 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    if [ "$JAVA_VERSION" != "17" ]; then
        echo "⚠️  Warnung: Java $JAVA_VERSION gefunden, aber Java 17 wird empfohlen."
        read -p "Trotzdem fortfahren? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "✅ Java 17 gefunden"
    fi
    
    # Node.js prüfen
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js nicht gefunden. Bitte installieren Sie Node.js 18+."
        exit 1
    fi
    echo "✅ Node.js $(node -v) gefunden"
    
    # Yarn prüfen/installieren
    if ! command -v yarn &> /dev/null; then
        echo "⚠️  Yarn nicht gefunden. Installiere Yarn 1.22..."
        npm install -g yarn@1.22.22
    fi
    
    YARN_VERSION=$(yarn --version)
    echo "✅ Yarn $YARN_VERSION gefunden"
    
    echo ""
}

# Nexus Repository klonen oder aktualisieren
clone_or_update() {
    if [ -d "$NEXUS_DIR" ]; then
        echo "📁 Nexus Repository existiert bereits, aktualisiere..."
        cd "$NEXUS_DIR"
        git fetch origin
        git checkout "$VERSION"
        git pull origin "$VERSION" || true
        cd ..
    else
        echo "📥 Clone Nexus Repository..."
        git clone --depth 1 --branch "$VERSION" https://github.com/sonatype/nexus-public.git "$NEXUS_DIR"
    fi
    echo ""
}

# Dependencies installieren
install_dependencies() {
    echo "📦 Installiere Dependencies..."
    cd "$NEXUS_DIR"
    
    # Yarn installieren
    yarn install --frozen-lockfile 2>/dev/null || yarn install
    
    echo ""
}

# Build durchführen
build_nexus() {
    echo "🔨 Starte Build..."
    cd "$NEXUS_DIR"
    
    # Maven Optionen für Performance
    export MAVEN_OPTS="-Xmx4g -XX:+UseG1GC"
    
    # Frage ob Tests durchgeführt werden sollen
    echo "Build-Optionen:"
    echo "1) Schneller Build ohne Tests (empfohlen)"
    echo "2) Vollständiger Build mit Tests"
    read -p "Auswahl (1/2): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[2]$ ]]; then
        echo "Führe vollständigen Build mit Tests durch..."
        ./mvnw clean install -Ppublic
    else
        echo "Führe schnellen Build ohne Tests durch..."
        ./mvnw clean install -Ppublic -DskipTests -Dmaven.javadoc.skip=true
    fi
    
    echo ""
}

# Artefakte finden und anzeigen
find_artifacts() {
    echo "📦 Suche nach Build-Artefakten..."
    cd "$NEXUS_DIR"
    
    ARTIFACTS=$(find . -name "nexus-*.tar.gz" -o -name "nexus-*.zip" 2>/dev/null)
    
    if [ -z "$ARTIFACTS" ]; then
        echo "❌ Keine Artefakte gefunden!"
        exit 1
    fi
    
    echo "✅ Gefundene Artefakte:"
    echo "$ARTIFACTS" | while read -r artifact; do
        SIZE=$(du -h "$artifact" | cut -f1)
        echo "  - $artifact ($SIZE)"
    done
    
    echo ""
    echo "🎉 Build erfolgreich abgeschlossen!"
    echo ""
    echo "Die Artefakte können Sie nun verwenden für:"
    echo "  - Direkte Installation"
    echo "  - Docker Image Build"
    echo "  - Distribution"
}

# Hauptablauf
main() {
    check_requirements
    clone_or_update
    install_dependencies
    build_nexus
    find_artifacts
}

# Script ausführen
main
