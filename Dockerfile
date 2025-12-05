FROM eclipse-temurin:17-jre-jammy

# Set Nexus version as build argument (passed from CI build)
ARG NEXUS_VERSION

# Nexus configuration - NEXUS_DATA must be defined first as it's used in other variables
ENV NEXUS_DATA=/nexus-data
ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus \
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
    ls -la ${NEXUS_HOME}/bin/ 2>/dev/null || echo "WARNING: bin directory not found!"

# Verify and configure Nexus vmoptions
RUN VMOPTIONS_FILE="${NEXUS_HOME}/bin/nexus.vmoptions" && \
    if [ ! -f "$VMOPTIONS_FILE" ]; then \
      echo "========================================" && \
      echo "ERROR: nexus.vmoptions not found at expected path:" && \
      echo "  $VMOPTIONS_FILE" && \
      echo "========================================" && \
      echo "Actual directory structure:" && \
      echo "--- ${NEXUS_HOME} ---" && \
      ls -la ${NEXUS_HOME}/ && \
      echo "--- Looking for .vmoptions files ---" && \
      find ${NEXUS_HOME} -name "*.vmoptions" -type f 2>/dev/null && \
      echo "--- Looking for bin directories ---" && \
      find ${NEXUS_HOME} -type d -name "bin" 2>/dev/null && \
      echo "========================================" && \
      echo "Please check the structure of your nexus-*.tar.gz file." && \
      echo "Expected: nexus-<version>/bin/nexus.vmoptions" && \
      echo "========================================" && \
      exit 1; \
    fi && \
    echo "Found nexus.vmoptions at: $VMOPTIONS_FILE" && \
    sed -i "s|karaf.data=.*|karaf.data=${NEXUS_DATA}|g" "$VMOPTIONS_FILE" && \
    sed -i "s|java-library-path=.*|java-library-path=./lib/support|g" "$VMOPTIONS_FILE"

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
