# Dev Container für Nexus Public Build

Dieser Dev Container stellt eine vollständige Build-Umgebung für Sonatype Nexus Repository OSS bereit.

## Enthaltene Tools

- **Java 17** (OpenJDK via Microsoft Dev Container)
- **Node.js 18**
- **Yarn 1.22.22** (global installiert)
- **Maven** (via Maven Wrapper im Nexus-Projekt)
- **Git**
- **GitHub CLI** (`gh`)
- **Docker-in-Docker** (für Docker-Image Builds)

## Automatische Konfiguration

Beim ersten Start des Containers werden automatisch:
- Yarn 1.22.22 installiert
- Das Build-Script ausführbar gemacht
- Maven und Yarn Caches als Volumes gemountet (für schnellere Builds)
- Port 8081 für Nexus weitergeleitet

## Verwendung

### Container starten

1. In VS Code die Command Palette öffnen (`Ctrl+Shift+P` / `Cmd+Shift+P`)
2. "Dev Containers: Reopen in Container" wählen
3. Warten bis der Container gebaut und konfiguriert ist

### Nexus bauen

```bash
# Schneller Build der neuesten Version
./build-local.sh

# Spezifische Version bauen
./build-local.sh release-3.84.1-01

# Oder manuell
cd nexus-public
./mvnw clean install -Ppublic -DskipTests
```

### GitHub Actions lokal testen

```bash
# GitHub CLI verwenden
gh workflow view
gh workflow run build-nexus.yml
```

### Docker Image bauen

```bash
# Nachdem der Build abgeschlossen ist
docker build -t nexus-oss:custom .
docker-compose up -d
```

## Performance-Optimierungen

- **Maven Cache**: Persistentes Volume für Maven-Dependencies
- **Yarn Cache**: Persistentes Volume für Yarn-Dependencies
- **Memory**: 4GB Heap für Maven-Builds via `MAVEN_OPTS`

## Volumes

Der Container verwendet folgende persistente Volumes:
- `nexus-build-maven-cache`: Maven Repository Cache (~/.m2)
- `nexus-build-yarn-cache`: Yarn Global Cache

Diese bleiben zwischen Container-Neustarts erhalten und beschleunigen Builds erheblich.

## VS Code Extensions

Automatisch installierte Extensions:
- Java Extension Pack
- Maven for Java
- Language Support for Java (Red Hat)
- XML Language Support
- GitHub Actions
- Docker

## Ports

- **8081**: Nexus Repository (falls lokal gestartet)

## Troubleshooting

### Out of Memory beim Build

Die Umgebungsvariable `MAVEN_OPTS` ist bereits auf 4GB gesetzt. Falls Sie mehr benötigen:

```bash
export MAVEN_OPTS="-Xmx6g -XX:+UseG1GC"
```

### Cache löschen

```bash
# Maven Cache
rm -rf ~/.m2/repository

# Yarn Cache
yarn cache clean
```

### Container neu bauen

```bash
# In VS Code Command Palette:
# "Dev Containers: Rebuild Container"
```
