FROM eclipse-temurin:17-jre-jammy

# Nexus Version als Build Argument
ARG NEXUS_VERSION=3.84.1-01

# Metadata
LABEL maintainer="your-email@example.com"
LABEL description="Custom built Nexus Repository OSS"
LABEL version="${NEXUS_VERSION}"

# Nexus User und Verzeichnisse
RUN groupadd -r nexus && \
    useradd -r -g nexus -d /opt/nexus -s /bin/bash nexus && \
    mkdir -p /opt/nexus /opt/sonatype-work && \
    chown -R nexus:nexus /opt/nexus /opt/sonatype-work

# Nexus Artefakt kopieren
# Voraussetzung: Das tar.gz muss im Build-Context vorhanden sein
COPY --chown=nexus:nexus artifacts/nexus-*.tar.gz /tmp/

# Nexus installieren
RUN cd /tmp && \
    tar -xzf nexus-*.tar.gz -C /opt && \
    rm nexus-*.tar.gz && \
    cd /opt && \
    mv nexus-* nexus-app && \
    ln -s /opt/nexus-app /opt/nexus/nexus && \
    chown -R nexus:nexus /opt/nexus-app /opt/sonatype-work

# Konfiguration
ENV NEXUS_HOME=/opt/nexus/nexus \
    NEXUS_DATA=/opt/sonatype-work \
    NEXUS_CONTEXT="" \
    SONATYPE_WORK=/opt/sonatype-work \
    INSTALL4J_ADD_VM_PARAMS="-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=/opt/sonatype-work/javaprefs"

# Ports
EXPOSE 8081

# Volume für persistente Daten
VOLUME /opt/sonatype-work

# Wechsel zu nexus User
USER nexus
WORKDIR /opt/nexus/nexus

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8081/ || exit 1

# Startkommando
CMD ["bin/nexus", "run"]
