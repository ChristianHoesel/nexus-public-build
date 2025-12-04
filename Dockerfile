FROM eclipse-temurin:17-jre-jammy

# Set Nexus version as build argument (passed from CI build)
ARG NEXUS_VERSION

# Nexus configuration
ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus \
    NEXUS_DATA=/nexus-data \
    NEXUS_CONTEXT='' \
    SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work \
    INSTALL4J_ADD_VM_PARAMS="-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs"

# Configure Java environment
ENV JAVA_HOME=/opt/java/openjdk \
    JAVA_OPTS="-XX:+UseG1GC -XX:+UseContainerSupport"

# Add labels with version information
LABEL org.opencontainers.image.title="Nexus Repository OSS" \
      org.opencontainers.image.description="Sonatype Nexus Repository OSS" \
      org.opencontainers.image.version="${NEXUS_VERSION}" \
      org.opencontainers.image.vendor="Sonatype" \
      org.opencontainers.image.source="https://github.com/ChristianHoesel/nexus-public-build"

# Install curl for health check
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Create nexus user and directories
RUN groupadd -r nexus -g 200 && \
    useradd -r -u 200 -g nexus -m -d ${NEXUS_DATA} -s /bin/bash nexus && \
    mkdir -p ${SONATYPE_DIR} ${NEXUS_DATA} && \
    chown -R nexus:nexus ${SONATYPE_DIR} ${NEXUS_DATA}

WORKDIR ${SONATYPE_DIR}

# Copy and extract Nexus distribution
COPY --chown=nexus:nexus nexus-*.tar.gz /tmp/nexus.tar.gz
RUN tar -xzf /tmp/nexus.tar.gz -C ${SONATYPE_DIR} && \
    mv ${SONATYPE_DIR}/nexus-* ${NEXUS_HOME} && \
    rm /tmp/nexus.tar.gz

# Configure Nexus to use the data directory
RUN sed -i "s|karaf.data=.*|karaf.data=${NEXUS_DATA}|g" ${NEXUS_HOME}/bin/nexus.vmoptions && \
    sed -i "s|java-library-path=.*|java-library-path=./lib/support|g" ${NEXUS_HOME}/bin/nexus.vmoptions

# Create necessary directories in NEXUS_DATA
RUN mkdir -p ${NEXUS_DATA}/etc ${NEXUS_DATA}/log ${NEXUS_DATA}/tmp && \
    chown -R nexus:nexus ${NEXUS_HOME} ${NEXUS_DATA}

# Expose Nexus port
EXPOSE 8081

# Set user to nexus
USER nexus

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=3 \
    CMD curl -f http://localhost:8081/ || exit 1

# Set working directory
WORKDIR ${NEXUS_HOME}

# Start Nexus
CMD ["bin/nexus", "run"]
