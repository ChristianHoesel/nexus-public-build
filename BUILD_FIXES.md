# Nexus Build - Behobene Probleme

## Problem 1: Yarn Version Konflikt
**Fehler**: `This project's package.json defines "packageManager": "yarn@4.9.1". However the current global version of Yarn is 1.22.22.`

**Lösung**: 
- Corepack aktivieren: `corepack enable`
- Corepack bereitet automatisch Yarn 4.9.1 vor
- Das Build-Script wurde aktualisiert, um Corepack automatisch zu aktivieren

## Problem 2: JAVA_HOME nicht gesetzt
**Fehler**: `The JAVA_HOME environment variable is not defined correctly`

**Lösung**:
- JAVA_HOME wird automatisch gesetzt:
  ```bash
  export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
  ```
- Im Dev Container wird dies jetzt in ~/.bashrc gesetzt
- Das Build-Script setzt JAVA_HOME automatisch vor dem Build

## Build-Status

✅ **Erfolgreich gestartet!**

Der Build läuft aktuell und kompiliert die Module. Fortschritt:
- Modul 68 von 117 (ca. 58% fertig)
- Keine kritischen Fehler
- Nur Deprecation-Warnungen (normal)

## Geschätzte Dauer

- **Erster Build**: 15-30 Minuten (ohne Tests)
- **Nachfolgende Builds**: 5-10 Minuten (dank Maven Cache)

## Nächste Schritte

Wenn der Build abgeschlossen ist:

1. **Artefakte finden**:
   ```bash
   find nexus-public -name "nexus-*.tar.gz" -o -name "nexus-*.zip"
   ```

2. **Artefakte testen**:
   ```bash
   cd nexus-public/assemblies/nexus-base-template/target/
   tar -tzf nexus-base-template-*.tar.gz | head -20
   ```

3. **Docker Image bauen** (optional):
   ```bash
   # Artefakte in artifacts/ Verzeichnis kopieren
   mkdir -p artifacts
   cp nexus-public/assemblies/nexus-base-template/target/nexus-*.tar.gz artifacts/
   
   # Docker Image bauen
   docker build -t nexus-oss:3.84.1-01 .
   ```

## Überwachung

Build-Status prüfen:
```bash
# In einem neuen Terminal
ps aux | grep mvnw

# Letzte Ausgabe anzeigen
tail -f /tmp/build.log  # falls umgeleitet
```
