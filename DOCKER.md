# Docker Usage Guide for Nexus Repository OSS

This repository automatically builds Docker images of Sonatype Nexus Repository OSS and publishes them to the GitHub Container Registry.

## Quick Start

### Pull and Run the Image

```bash
# Pull the latest image
docker pull ghcr.io/christianhoesel/nexus-public-build:latest

# Run Nexus
docker run -d -p 8081:8081 --name nexus \
  -v nexus-data:/nexus-data \
  ghcr.io/christianhoesel/nexus-public-build:latest
```

### Using Docker Compose

```bash
# Start Nexus with docker-compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop Nexus
docker-compose down
```

## Accessing Nexus

After starting the container, Nexus will be available at:
- **URL**: http://localhost:8081
- **Default credentials**: 
  - Username: `admin`
  - Password: Located in `/nexus-data/admin.password` inside the container

To retrieve the initial admin password:
```bash
docker exec nexus cat /nexus-data/admin.password
```

## Environment Variables

The Docker image supports the following environment variables:

### JVM Configuration

- **INSTALL4J_ADD_VM_PARAMS**: JVM parameters for Nexus
  - Default: `-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=/nexus-data/javaprefs -Dnexus.edition=CORE`
  - Example: `-Xms4g -Xmx4g -XX:MaxDirectMemorySize=4g -Dnexus.edition=CORE`

### Nexus Configuration

- **NEXUS_CONTEXT**: Context path for Nexus (empty for root, `/nexus` for /nexus path)
  - Default: `` (empty, runs on root path)
  - Example: `NEXUS_CONTEXT=/nexus`

- **NEXUS_DATA**: Data directory path
  - Default: `/nexus-data`
  - This should typically not be changed

## Volume Mounts

### Data Persistence

The most important volume to persist is `/nexus-data`, which contains:
- Repository data
- Configuration
- Logs
- Plugins
- Admin password

Example with named volume:
```bash
docker run -d -p 8081:8081 \
  -v nexus-data:/nexus-data \
  ghcr.io/christianhoesel/nexus-public-build:latest
```

Example with host directory:
```bash
docker run -d -p 8081:8081 \
  -v /path/to/nexus-data:/nexus-data \
  ghcr.io/christianhoesel/nexus-public-build:latest
```

## Resource Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 4 GB (2.7 GB allocated to JVM by default)
- **Disk**: 10 GB minimum (depends on repository usage)

### Recommended Production Settings
- **CPU**: 4+ cores
- **RAM**: 8 GB (adjust JVM settings accordingly)
- **Disk**: 50 GB+ (depends on repository size)

### Adjusting Memory

To allocate more memory (e.g., 4 GB):

```bash
docker run -d -p 8081:8081 \
  -v nexus-data:/nexus-data \
  -e INSTALL4J_ADD_VM_PARAMS="-Xms4g -Xmx4g -XX:MaxDirectMemorySize=4g -Djava.util.prefs.userRoot=/nexus-data/javaprefs -Dnexus.edition=CORE" \
  ghcr.io/christianhoesel/nexus-public-build:latest
```

Or in docker-compose.yml:
```yaml
environment:
  - INSTALL4J_ADD_VM_PARAMS=-Xms4g -Xmx4g -XX:MaxDirectMemorySize=4g -Djava.util.prefs.userRoot=/nexus-data/javaprefs -Dnexus.edition=CORE
```

## Available Tags

- `latest`: Latest build from the main branch
- `<version>`: Specific Nexus version (e.g., `3.88.0-08`)
- `<branch>-<sha>`: Branch-specific builds with commit SHA

Example:
```bash
docker pull ghcr.io/christianhoesel/nexus-public-build:3.88.0-08
```

## Health Check

The Docker image includes a built-in health check that:
- Runs every 30 seconds
- Has a 180-second startup grace period
- Checks if Nexus is responding on port 8081

Check container health:
```bash
docker ps
# or
docker inspect nexus | grep -A 10 Health
```

## Networking

### Port Mapping

Nexus uses port 8081 by default. To use a different host port:

```bash
docker run -d -p 9000:8081 \
  -v nexus-data:/nexus-data \
  ghcr.io/christianhoesel/nexus-public-build:latest
```

Access at: http://localhost:9000

### Reverse Proxy

For production use, it's recommended to use a reverse proxy (nginx, Apache, Traefik) with HTTPS.

Example nginx configuration:
```nginx
server {
    listen 80;
    server_name nexus.example.com;
    
    location / {
        proxy_pass http://localhost:8081/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Backup and Restore

### Backup

To backup Nexus data:

```bash
# Stop the container
docker stop nexus

# Backup the data volume
docker run --rm \
  -v nexus-data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/nexus-backup-$(date +%Y%m%d).tar.gz /data

# Start the container
docker start nexus
```

### Restore

To restore from backup:

```bash
# Stop the container
docker stop nexus

# Restore the data
docker run --rm \
  -v nexus-data:/data \
  -v $(pwd):/backup \
  ubuntu bash -c "cd /data && tar xzf /backup/nexus-backup-YYYYMMDD.tar.gz --strip 1"

# Start the container
docker start nexus
```

## Troubleshooting

### Container won't start

1. Check logs:
   ```bash
   docker logs nexus
   ```

2. Verify volume permissions:
   ```bash
   docker run --rm -v nexus-data:/data ubuntu ls -la /data
   ```

3. Check available memory:
   ```bash
   docker stats nexus
   ```

### Nexus is slow or unresponsive

1. Increase memory allocation (see "Adjusting Memory" section)
2. Check available disk space
3. Review logs for errors

### Cannot access Nexus UI

1. Verify container is running:
   ```bash
   docker ps | grep nexus
   ```

2. Check if port is accessible:
   ```bash
   curl http://localhost:8081
   ```

3. Verify firewall settings

### Reset Admin Password

If you've lost the admin password:

```bash
# Stop Nexus
docker stop nexus

# Remove the admin.password file
docker run --rm -v nexus-data:/data ubuntu rm /data/admin.password

# Start Nexus - a new password will be generated
docker start nexus

# Retrieve new password
docker exec nexus cat /nexus-data/admin.password
```

## Building the Image Locally

If you want to build the Docker image yourself:

```bash
# Build Nexus first
./build-local.sh release-3.88.0-08

# Find the built artifact
TARBALL=$(find nexus-public -name "nexus-*.tar.gz" | head -n 1)

# Copy it to the root
cp "$TARBALL" ./nexus-custom.tar.gz

# Build Docker image
docker build -t nexus-oss:custom .

# Run your custom image
docker run -d -p 8081:8081 -v nexus-data:/nexus-data nexus-oss:custom
```

## Security Considerations

1. **Change default password**: Always change the default admin password immediately after first login
2. **Use HTTPS**: Configure a reverse proxy with SSL/TLS for production
3. **Regular updates**: Keep Nexus updated to the latest version
4. **Backup regularly**: Implement automated backup solutions
5. **Network security**: Use firewall rules to restrict access
6. **Volume permissions**: Ensure proper file permissions on mounted volumes

## Additional Resources

- [Nexus Repository Documentation](https://help.sonatype.com/repomanager3)
- [Sonatype Community](https://community.sonatype.com/)
- [GitHub Repository](https://github.com/ChristianHoesel/nexus-public-build)

## Support

For issues related to:
- **This Docker image**: Open an issue in this repository
- **Nexus OSS itself**: Visit the [Sonatype Community](https://community.sonatype.com/)
