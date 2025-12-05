FROM eclipse-temurin:17-jre-jammy

# Set Nexus version as build argument (passed from CI build)
ARG NEXUS_VERSION

# Nexus configuration - NEXUS_DATA must be defined first as it's used in other variables
ENV NEXUS_DATA=/nexus-data
ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus \
    NEXUS_CONTEXT='' \
    SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work

# JVM configuration via INSTALL4J_ADD_VM_PARAMS (required for Nexus 3.78+)
# Note: Since Nexus 3.78, nexus.vmoptions is no longer used in Docker containers
# See: https://help.sonatype.com/en/configuring-the-runtime-environment.html
# Note: Nexus expects data in ${SONATYPE_WORK}/nexus3, we symlink it to ${NEXUS_DATA}
ENV INSTALL4J_ADD_VM_PARAMS="-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m \
    -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs"

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
    # Debug: Show what was extracted
    echo "=== Contents of ${SONATYPE_DIR} after extraction ===" && \
    ls -la ${SONATYPE_DIR}/ && \
    # Try to find and rename the nexus directory
    EXTRACTED_DIR=$(ls -d ${SONATYPE_DIR}/nexus-* 2>/dev/null | head -n 1) && \
    if [ -n "$EXTRACTED_DIR" ]; then \
      echo "Found extracted directory: $EXTRACTED_DIR" && \
      mv "$EXTRACTED_DIR" ${NEXUS_HOME}; \
    else \
      echo "ERROR: No nexus-* directory found after extraction!" && \
      echo "=== Full directory tree ===" && \
      find ${SONATYPE_DIR} -type d && \
      exit 1; \
    fi && \
    rm /tmp/nexus.tar.gz && \
    # Verify expected structure exists
    echo "=== Verifying Nexus directory structure ===" && \
    echo "Contents of ${NEXUS_HOME}:" && \
    ls -la ${NEXUS_HOME}/ && \
    echo "Contents of ${NEXUS_HOME}/bin (if exists):" && \
    ls -la ${NEXUS_HOME}/bin/ 2>/dev/null || echo "Note: bin directory not found (expected for Nexus 3.78+)" && \
    # Create necessary directories in NEXUS_DATA
    mkdir -p ${NEXUS_DATA}/etc ${NEXUS_DATA}/log ${NEXUS_DATA}/tmp && \
    # Create sonatype-work directory and symlink nexus3 -> NEXUS_DATA (as in official image)
    mkdir -p ${SONATYPE_WORK} && \
    ln -s ${NEXUS_DATA} ${SONATYPE_WORK}/nexus3 && \
    # Ensure files and directories have correct permissions (execute bit on dirs and bin scripts)
    # - set read+execute for directories and read for files where appropriate
    chmod -R a+rX ${NEXUS_HOME} || true && \
    # ensure scripts in bin are executable if present
    if [ -d "${NEXUS_HOME}/bin" ]; then find ${NEXUS_HOME}/bin -type f -exec chmod a+x {} \; || true; fi && \
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
