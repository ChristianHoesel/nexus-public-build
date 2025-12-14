# Nexus Public Build Repository

This repository serves as a build wrapper for [Sonatype Nexus Repository OSS](https://github.com/sonatype/nexus-public).

## Problem

The official Nexus Public Repository has some challenges:
- A separate branch is created for each version (e.g., `release-3.86.0-08`)
- The `main` branch is only sporadically updated (last update: February 2025)
- Releases are maintained as separate branches and tags, not as continuous development in the main branch
- The build requires a specific setup (Java 21, Yarn 1.22 & Maven profile "public")
- Build documentation is incomplete and requires knowledge of Maven profiles

## Solution

This repository automates the build process with GitHub Actions and creates usable artifacts:
- **Build artifacts**: `.tar.gz` and `.zip` distributions
- **Docker images**: Automatically built and published to GitHub Container Registry

## Quick Start with Docker

The fastest way to run Nexus OSS is using the pre-built Docker image:

```bash
docker pull ghcr.io/christianhoesel/nexus-public-build:latest
docker run -d -p 8081:8081 -v nexus-data:/nexus-data ghcr.io/christianhoesel/nexus-public-build:latest
```

Access Nexus at http://localhost:8081

For detailed Docker usage, configuration, and troubleshooting, see [DOCKER.md](DOCKER.md).

## Usage

### Manual Build via GitHub Actions

1. Go to the "Actions" tab in this repository
2. Select the workflow "Build Nexus OSS"
3. Click on "Run workflow"
4. Enter the desired Nexus version (e.g., `release-3.87.1-01`)
5. Built artifacts can be found under "Artifacts" after the build completes

### Available Versions

Find Nexus versions here:
- **Branches**: https://github.com/sonatype/nexus-public/branches/all
- **Releases/Tags**: https://github.com/sonatype/nexus-public/releases

Current examples (as of December 2025):
- `release-3.87.1-01` (latest)
- `release-3.86.0-08`  


**Note**: Branch names correspond to release tags. Use the branch name for the build.

### Local Build

If you want to build locally:

```bash
# Simply use the build script
chmod +x build-local.sh
./build-local.sh release-3.87.1-01
```

The build script automatically performs the following steps:
1. Clones the Nexus Public Repository
2. Enables Corepack and configures Yarn 4 with `nodeLinker: node-modules`
3. Installs all dependencies with Yarn 4
4. Builds all frontend components with `yarn workspaces foreach run build-all`
5. Switches to Yarn 1.22.22 for Maven compatibility
6. Runs Maven build with `-Ppublic -Dskip.installyarn -Dskip.yarn -DskipTests`
7. Creates `.tar.gz` and `.zip` distributions

The finished artifacts can then be found in the workspace root:
- `nexus-*-unix.tar.gz` (~133 MB)
- `nexus-*-unix.zip`

## Build Requirements

- **Java**: OpenJDK 21 (Temurin recommended)
- **Node.js**: Version 18 or higher
- **Corepack**: For Yarn 4 (activate with `corepack enable`)
- **Yarn**: Version 4.9.1 for frontend build, version 1.22.22 for Maven (automatically managed by build script)
- **Maven**: Provided via Maven Wrapper (`./mvnw`)
- **RAM**: At least 4 GB for the build process
- **Disk**: ~2 GB for dependencies and build artifacts

## Build Process Details

The build uses a two-phase strategy:

**Phase 1: Frontend Build with Yarn 4**
- Yarn 4.9.1 is activated via Corepack
- `nodeLinker: node-modules` for rspack compatibility
- Dependencies are installed with `yarn install --no-immutable`
- Frontend components are built with `yarn workspaces foreach run build-all`

**Phase 2: Maven Build with Yarn 1**
- Switch to Yarn 1.22.22 (via `npm install -g yarn@1.22.22`)
- Maven build with `-Ppublic` profile
- Flags `-Dskip.installyarn -Dskip.yarn` skip redundant Yarn steps
- `-DskipTests` speeds up the build (tests optional)

## Automatic Builds

The GitHub Actions workflow automatically runs builds:
- **On Push**: To the main branch  
- **Manual**: Via workflow_dispatch with version selection

Weekly automatic builds are currently disabled (can be enabled via cron schedule).

## Artifacts

After a successful build, the following artifacts are provided:

### Build Artifacts
- `nexus-*.tar.gz` - Unix/Linux distribution
- `nexus-*.zip` - Windows distribution

Artifacts are kept for 30 days.

### Docker Images

Docker images are automatically built and published to the GitHub Container Registry:
- **Registry**: `ghcr.io/christianhoesel/nexus-public-build`
- **Tags**: 
  - `latest` - Latest build from main branch
  - `<version>` - Specific Nexus version (e.g., `3.86.0-08`)
  - `<branch>-<sha>` - Branch-specific builds

```bash
# Pull latest version
docker pull ghcr.io/christianhoesel/nexus-public-build:latest

# Pull specific version
docker pull ghcr.io/christianhoesel/nexus-public-build:3.87.1-01
```

See [DOCKER.md](DOCKER.md) for complete Docker usage documentation.

### Docker Image Testing

Automated tests verify the functionality of Docker images:
- **Test Script**: `test-docker-image.sh` - Comprehensive test suite for Docker images
- **GitHub Actions**: Tests run automatically after each Docker image build
- **Test Coverage**:
  - Container startup and health checks
  - Nexus service accessibility
  - Volume persistence
  - Environment variable configuration
  - User permissions and security

To run tests locally:
```bash
chmod +x test-docker-image.sh
IMAGE_NAME=ghcr.io/christianhoesel/nexus-public-build:latest ./test-docker-image.sh
```

### Maven Profile "public"

The Maven profile `-Ppublic` is **required** for the OSS build. It activates the necessary modules and configurations for the public version of Nexus Repository.

## License

Nexus Repository OSS is licensed under the Eclipse Public License.
This build repository is MIT licensed.

## Resources

- [Nexus Repository Documentation](https://help.sonatype.com/repomanager3)
- [Nexus Public GitHub](https://github.com/sonatype/nexus-public)
- [Community Forum](https://community.sonatype.com/)