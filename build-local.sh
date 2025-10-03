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
    
    # JAVA_HOME setzen falls nicht gesetzt
    if [ -z "$JAVA_HOME" ]; then
        export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
        echo "✅ JAVA_HOME gesetzt: $JAVA_HOME"
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
    
    # Corepack aktivieren (für Yarn 4.x)
    if ! command -v corepack &> /dev/null; then
        echo "⚠️  Corepack nicht gefunden."
    else
        echo "✅ Aktiviere Corepack für Yarn 4.x..."
        corepack enable 2>/dev/null || true
    fi
    
    YARN_VERSION=$(yarn --version 2>/dev/null || echo "nicht installiert")
    echo "✅ Yarn $YARN_VERSION gefunden"
    
    echo ""
}

# Nexus Repository klonen oder aktualisieren
clone_or_update() {
    if [ -d "$NEXUS_DIR" ] && [ -d "$NEXUS_DIR/.git" ]; then
        echo "📁 Nexus Repository existiert bereits, aktualisiere..."
        cd "$NEXUS_DIR"
        git fetch origin
        git checkout "$VERSION"
        git pull origin "$VERSION" || true
        cd ..
    elif [ -d "$NEXUS_DIR" ] && [ ! -d "$NEXUS_DIR/.git" ]; then
        echo "📁 Nexus Repository existiert bereits (ohne .git)..."
        echo "ℹ️  Überspringe Git-Operationen"
    else
        echo "📥 Clone Nexus Repository..."
        git clone --depth 1 --branch "$VERSION" https://github.com/sonatype/nexus-public.git "$NEXUS_DIR"
        
        # .gitignore und .git im nexus-public Verzeichnis löschen
        if [ -f "$NEXUS_DIR/.gitignore" ]; then
            echo "🗑️  Entferne nexus-public/.gitignore..."
            rm "$NEXUS_DIR/.gitignore"
        fi
        
        if [ -d "$NEXUS_DIR/.git" ]; then
            echo "🗑️  Entferne nexus-public/.git Verzeichnis..."
            rm -rf "$NEXUS_DIR/.git"
        fi
    fi
    
    echo ""
}

# Dependencies installieren
install_dependencies() {
    echo "📦 Installiere Dependencies..."
    cd "$NEXUS_DIR"
    
    # Corepack für Yarn 4.x aktivieren
    corepack enable 2>/dev/null || true
    
    # Yarn 4.x über Corepack bereitstellen
    if [ -f "package.json" ] && grep -q '"packageManager"' package.json; then
        echo "ℹ️  Projekt verwendet packageManager field - Corepack wird Yarn 4.x verwenden"
    fi
    
    # Yarn installieren
    yarn install 2>&1 | grep -v "YN0060\|YN0002\|YN0086" || true
    
    # UI-Komponenten vorab bauen (für workspace:-Referenzen)
    echo "🔨 Baue UI-Komponenten vor Maven-Build..."
    cd components/nexus-ui-plugin
    yarn build 2>&1 | grep -v "YN0000" || true
    cd ../..
    
    echo ""
    cd ..
}

# Build durchführen
build_nexus() {
    echo "🔨 Starte Build..."
    cd "$NEXUS_DIR"
    
    # JAVA_HOME sicherstellen
    if [ -z "$JAVA_HOME" ]; then
        export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    fi
    
    # Maven Optionen für Performance
    export MAVEN_OPTS="-Xmx4g -XX:+UseG1GC"
    
    echo "Führe schnellen Build ohne Tests durch..."
    ./mvnw clean install -Ppublic -DskipTests -Dmaven.javadoc.skip=true -ntp
    
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
