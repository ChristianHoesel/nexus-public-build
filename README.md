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
```

Das Build-Script führt automatisch folgende Schritte aus:
1. Klont das Nexus Public Repository
2. Aktiviert Corepack und konfiguriert Yarn 4 mit `nodeLinker: node-modules`
3. Installiert alle Dependencies mit Yarn 4
4. Baut alle Frontend-Komponenten mit `yarn workspaces foreach run build-all`
5. Wechselt zu Yarn 1.22.22 für Maven-Kompatibilität
6. Führt Maven Build mit `-Ppublic -Dskip.installyarn -Dskip.yarn -DskipTests` aus
7. Erstellt `.tar.gz` und `.zip` Distributionen

Die fertigen Artefakte finden Sie dann im Workspace-Root:
- `nexus-*-unix.tar.gz` (~133 MB)
- `nexus-*-unix.zip`

## Build-Anforderungen

- **Java**: OpenJDK 17 (Temurin empfohlen)
- **Node.js**: Version 18 oder höher
- **Corepack**: Für Yarn 4 (mit `corepack enable` aktivieren)
- **Yarn**: Version 4.9.1 für Frontend-Build, Version 1.22.22 für Maven (automatisch vom Build-Script verwaltet)
- **Maven**: Wird über Maven Wrapper (`./mvnw`) bereitgestellt
- **RAM**: Mindestens 4 GB für den Build-Prozess
- **Disk**: ~2 GB für Dependencies und Build-Artefakte

## Build-Prozess Details

Der Build verwendet eine Zwei-Phasen-Strategie:

**Phase 1: Frontend-Build mit Yarn 4**
- Yarn 4.9.1 wird über Corepack aktiviert
- `nodeLinker: node-modules` für rspack-Kompatibilität
- Dependencies werden mit `yarn install --no-immutable` installiert
- Frontend-Komponenten werden mit `yarn workspaces foreach run build-all` gebaut

**Phase 2: Maven-Build mit Yarn 1**
- Wechsel zu Yarn 1.22.22 (via `npm install -g yarn@1.22.22`)
- Maven-Build mit `-Ppublic` Profil
- Flags `-Dskip.installyarn -Dskip.yarn` überspringen redundante Yarn-Schritte
- `-DskipTests` beschleunigt den Build (Tests optional)

## Automatische Builds

Der GitHub Actions Workflow führt automatisch Builds durch:
- **Bei Push**: Auf den main Branch  
- **Manuell**: Über workflow_dispatch mit Versionsauswahl

Wöchentliche automatische Builds sind derzeit deaktiviert (können via cron-Schedule aktiviert werden).

## Artefakte

Nach erfolgreichem Build werden folgende Artefakte bereitgestellt:
- `nexus-*.tar.gz` - Unix/Linux Distribution
- `nexus-*.zip` - Windows Distribution

Artefakte werden 30 Tage lang aufbewahrt.

### Maven Profil "public"

Das Maven-Profil `-Ppublic` ist **erforderlich** für den OSS-Build. Es aktiviert die notwendigen Module und Konfigurationen für die öffentliche Version von Nexus Repository.

## Lizenz

Nexus Repository OSS ist unter der Eclipse Public License lizenziert.
Dieses Build-Repository ist MIT-lizenziert.

## Ressourcen

- [Nexus Repository Dokumentation](https://help.sonatype.com/repomanager3)
- [Nexus Public GitHub](https://github.com/sonatype/nexus-public)
- [Community Forum](https://community.sonatype.com/)