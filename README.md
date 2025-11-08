# Nexus Public Build Rep3.

Dieses Repository dient als Build-Wrapper für [Sonatype Nexus Repository OSS](https://github.com/sonatype/nexus-public).

## Problem

Das offizielle Nexus Public Repository hat einige Herausforderungen:
- Für jede Version wird ein separater Branch erstellt (z.B. `release-3.86.0-08`)
- Der `main` Branch wird nur sporadisch aktualisiert (letztes Update: Februar 2025)
- Releases werden als separate Branches und Tags gepflegt, nicht als kontinuierliche Entwicklung im main Branch
- Der Build benötigt ein spezifisches Setup (Java 17, Yarn 1.22 & Maven Profil "public")
- Die Build-Dokumentation ist unvollständig und erfordert Kenntnisse über Maven-Profile

## Lösung

Dieses Repository automatisiert den Build-Prozess mit GitHub Actions und erstellt verwendbare Artefakte.

## Verwendung

### Manueller Build über GitHub Actions

1. Gehen Sie zum Tab "Actions" in diesem Repository
2. Wählen Sie den Workflow "Build Nexus OSS"
3. Klicken Sie auf "Run workflow"
4. Geben Sie die gewünschte Nexus-Version ein (z.B. `release-3.86.0-08`)
5. Die gebauten Artefakte finden Sie unter "Artifacts" nach Abschluss des Builds

### Verfügbare Versionen

Nexus-Versionen finden Sie hier:
- **Branches**: https://github.com/sonatype/nexus-public/branches/all
- **Releases/Tags**: https://github.com/sonatype/nexus-public/releases

Aktuelle Beispiele (Stand November 2025):
- `release-3.86.0-08` (neueste)
- `release-3.85.0-03`  


**Hinweis**: Die Branch-Namen entsprechen den Release-Tags. Verwenden Sie den Branch-Namen für den Build.

### Lokaler Build

Falls Sie lokal bauen möchten:

```bash
# Einfach das Build-Script verwenden
chmod +x build-local.sh
./build-local.sh release-3.86.0-08

# Oder manuell:
git clone https://github.com/sonatype/nexus-public.git
cd nexus-public
git checkout release-3.86.0-08

# Java 17 sicherstellen
java -version

# Yarn 1.22 installieren
npm install -g yarn@1.22.22

# Dependencies installieren
yarn install

# Build durchführen mit "public" Profil (ohne Tests für schnelleren Build)
./mvnw clean install -Ppublic -DskipTests

# Mit Tests
./mvnw clean install -Ppublic

# Die fertigen Artefakte finden Sie dann in:
# assemblies/nexus-base-template/target/nexus-base-template-*.tar.gz
```

## Build-Anforderungen

- **Java**: OpenJDK 17 (Temurin empfohlen)
- **Node.js**: Version 18 oder höher
- **Yarn**: Version 1.22.x (für initiale Installation)
- **Maven**: Wird über Maven Wrapper bereitgestellt
- **RAM**: Mindestens 4 GB für den Build-Prozess

### Dev Container (Empfohlen)

Dieses Repository enthält einen vollständig konfigurierten Dev Container:

```bash
# In VS Code:
# 1. Install "Dev Containers" Extension
# 2. Cmd/Ctrl+Shift+P → "Dev Containers: Reopen in Container"
# 3. Warten bis Setup abgeschlossen ist
# 4. ./build-local.sh ausführen
```

Der Dev Container enthält alle notwendigen Tools und Konfigurationen.

## Automatische Builds

Der Workflow führt automatisch folgende Builds durch:
- **Wöchentlich**: Jeden Montag um 2 Uhr UTC
- **Bei Push**: Auf den main Branch
- **Manuell**: Über workflow_dispatch

## Artefakte

Nach erfolgreichem Build werden folgende Artefakte bereitgestellt:
- `nexus-*.tar.gz` - Unix/Linux Distribution
- `nexus-*.zip` - Windows Distribution

Artefakte werden 30 Tage lang aufbewahrt.

## Docker Image (Optional)

Sie können die gebauten Artefakte verwenden, um ein eigenes Docker-Image zu erstellen:

```bash
# 1. Artefakte aus GitHub Actions herunterladen und in artifacts/ ablegen
# 2. Docker Image bauen
docker build -t nexus-oss:custom .

# Oder mit docker-compose
docker-compose up -d
```

## Häufige Probleme

### Out of Memory beim Build

Erhöhen Sie den Heap-Speicher:
```bash
export MAVEN_OPTS="-Xmx4g -XX:+UseG1GC"
./mvnw clean install -Ppublic
```

### Yarn Version Konflikte

Das Projekt könnte sowohl Yarn 1.x als auch Yarn 4.x benötigen. Der Workflow handhabt dies automatisch.

### Tests schlagen fehl

Verwenden Sie `-DskipTests` für einen schnelleren Build ohne Tests:
```bash
./mvnw clean install -Ppublic -DskipTests
```

### Maven Profil "public"

Das Maven-Profil `-Ppublic` ist **erforderlich** für den OSS-Build. Es aktiviert die notwendigen Module und Konfigurationen für die öffentliche Version von Nexus Repository.

## Alternativen

Falls Sie keinen eigenen Build durchführen möchten:

1. **Offizielle Releases**: https://help.sonatype.com/repomanager3/product-information/download
2. **Docker Images**: `docker pull sonatype/nexus3`
3. **Helm Charts**: Für Kubernetes-Deployments

## Warum kein Pull Request?

Sie haben Recht - Pull Requests ans Haupt-Repository bringen wenig:
- Sonatype verwendet einen internen Entwicklungsprozess
- Die öffentlichen Branches sind nur Snapshots von Releases
- Contributions werden über andere Kanäle koordiniert

## Lizenz

Nexus Repository OSS ist unter der Eclipse Public License lizenziert.
Dieses Build-Repository ist MIT-lizenziert.

## Ressourcen

- [Nexus Repository Dokumentation](https://help.sonatype.com/repomanager3)
- [Nexus Public GitHub](https://github.com/sonatype/nexus-public)
- [Community Forum](https://community.sonatype.com/)