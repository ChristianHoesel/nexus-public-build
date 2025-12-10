# Dev Container for Nexus Public Build

This dev container provides a complete build environment for Sonatype Nexus Repository OSS.

## Included Tools

- **Java 21** (OpenJDK via Microsoft Dev Container)
- **Node.js 18**
- **Yarn 1.22.22** (installed globally)
- **Maven** (via Maven Wrapper in Nexus project)
- **Git**
- **GitHub CLI** (`gh`)
- **Docker-in-Docker** (for Docker image builds)

## Automatic Configuration

On first start of the container:
- Yarn 1.22.22 is installed
- The build script is made executable
- Maven and Yarn caches are mounted as volumes (for faster builds)
- Port 8081 is forwarded for Nexus

## Usage

### Starting the Container

1. Open the Command Palette in VS Code (`Ctrl+Shift+P` / `Cmd+Shift+P`)
2. Select "Dev Containers: Reopen in Container"
3. Wait for the container to be built and configured

### Building Nexus

```bash
# Quick build of the latest version
./build-local.sh

# Build specific version
./build-local.sh release-3.84.1-01

# Or manually
cd nexus-public
./mvnw clean install -Ppublic -DskipTests
```

### Testing GitHub Actions locally

```bash
# Use GitHub CLI
gh workflow view
gh workflow run build-nexus.yml
```

### Building Docker Image

```bash
# After the build is complete
docker build -t nexus-oss:custom .
docker-compose up -d
```

## Performance Optimizations

- **Maven Cache**: Persistent volume for Maven dependencies
- **Yarn Cache**: Persistent volume for Yarn dependencies
- **Memory**: 4GB heap for Maven builds via `MAVEN_OPTS`

## Volumes

The container uses the following persistent volumes:
- `nexus-build-maven-cache`: Maven Repository Cache (~/.m2)
- `nexus-build-yarn-cache`: Yarn Global Cache

These persist between container restarts and significantly speed up builds.

## VS Code Extensions

Automatically installed extensions:
- Java Extension Pack
- Maven for Java
- Language Support for Java (Red Hat)
- XML Language Support
- GitHub Actions
- Docker

## Ports

- **8081**: Nexus Repository (if started locally)

## Troubleshooting

### Yarn Version Error

If you see an error like "packageManager: yarn@4.9.1":

```bash
corepack enable
cd nexus-public
yarn install
```

The build script now automatically enables Corepack.

### JAVA_HOME not set

If Maven complains about JAVA_HOME:

```bash
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
./build-local.sh
```

The build script now automatically sets JAVA_HOME.

### Out of Memory during Build

The `MAVEN_OPTS` environment variable is already set to 4GB. If you need more:

```bash
export MAVEN_OPTS="-Xmx6g -XX:+UseG1GC"
```

### Clear Cache

```bash
# Maven Cache
rm -rf ~/.m2/repository

# Yarn Cache
yarn cache clean
```

### Rebuild Container

```bash
# In VS Code Command Palette:
# "Dev Containers: Rebuild Container"
```
