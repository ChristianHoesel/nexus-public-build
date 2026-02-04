#!/bin/bash
set -e

# Local build script for Nexus OSS
# Usage: ./build-local.sh [version]

VERSION=${1:-"release-3.89.0-09"}
NEXUS_DIR="nexus-public"
PROJECT_VERSION=""

echo "========================================"
echo "Nexus OSS Local Build Script"
echo "========================================"
echo "Version: $VERSION"
echo ""

# Check requirements
check_requirements() {
    echo "Checking build requirements..."

    rm -rf nexus-public/
    
    # Check Java version
    if ! command -v java &> /dev/null; then
        echo "❌ Java not found. Please install Java 21."
        exit 1
    fi
    
    # Set JAVA_HOME if not set
    if [ -z "$JAVA_HOME" ]; then
        export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
        echo "✅ JAVA_HOME set: $JAVA_HOME"
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    if [ "$JAVA_VERSION" != "21" ]; then
        echo "⚠️  Warning: Java $JAVA_VERSION found, but Java 21 is recommended."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "✅ Java 21 found"
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js not found. Please install Node.js 18+."
        exit 1
    fi
    echo "✅ Node.js $(node -v) found"
    
    # Enable Corepack (for Yarn 4.x)
    if ! command -v corepack &> /dev/null; then
        echo "⚠️  Corepack not found."
    else
        echo "✅ Enabling Corepack for Yarn 4.x..."
        corepack enable 2>/dev/null || true
        corepack prepare yarn@4.9.1 --activate 2>/dev/null || true
    fi

    YARN_VERSION=$(yarn --version 2>/dev/null || echo "not installed")
    echo "✅ Yarn $YARN_VERSION found"
    
    echo ""
}

# Clone or update Nexus repository
clone_or_update() {
    if [ -d "$NEXUS_DIR" ] && [ -d "$NEXUS_DIR/.git" ]; then
        echo "📁 Nexus repository already exists, updating..."
        cd "$NEXUS_DIR"
        git fetch origin
        git checkout "$VERSION"
        git pull origin "$VERSION" || true
        cd ..
    elif [ -d "$NEXUS_DIR" ] && [ ! -d "$NEXUS_DIR/.git" ]; then
        echo "📁 Nexus repository already exists (without .git)..."
        echo "ℹ️  Skipping Git operations"
    else
        echo "📥 Cloning Nexus repository..."
        git clone --depth 1 --branch "$VERSION" https://github.com/sonatype/nexus-public.git "$NEXUS_DIR"
        
        # Delete .gitignore and .git in nexus-public directory
        if [ -f "$NEXUS_DIR/.gitignore" ]; then
            echo "🗑️  Removing nexus-public/.gitignore..."
            rm "$NEXUS_DIR/.gitignore"
        fi
        
        if [ -d "$NEXUS_DIR/.git" ]; then
            echo "🗑️  Removing nexus-public/.git directory..."
            rm -rf "$NEXUS_DIR/.git"
        fi
    fi
    
    if [ -f "$NEXUS_DIR/pom.xml" ]; then
        PROJECT_VERSION=$(grep '<version>' "$NEXUS_DIR/pom.xml" | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | sed -n '2p')
        PROJECT_VERSION=${PROJECT_VERSION:-custom}
        echo "📌 Detected project version: $PROJECT_VERSION"
    else
        PROJECT_VERSION="custom"
        echo "⚠️  Could not determine project version, using placeholder '$PROJECT_VERSION'"
    fi

    echo ""
}

# Install dependencies
install_dependencies() {
    echo "📦 Installing dependencies in workspace root..."
    cd "$NEXUS_DIR"
    
    # Enable Corepack for Yarn 4.x
    corepack enable 2>/dev/null || true
    corepack prepare yarn@4.9.1 --activate 2>/dev/null || true

    # Run Yarn in node_modules mode (project expects classic structure)
    yarn config set nodeLinker node-modules

    # Install dependencies with the Yarn defined in the repository
    yarn install
    
    echo ""
    cd ..
}

# Build frontend components
build_frontend() {
    echo "🎨 Building frontend components..."
    cd "$NEXUS_DIR"
    
    yarn workspaces foreach --all --topological-dev run build-all
    
    echo ""
    cd ..
}

# Build Nexus
build_nexus() {
    echo "🔨 Starting Maven build (skipping frontend steps)..."
    cd "$NEXUS_DIR"
    
    # Ensure JAVA_HOME
    if [ -z "$JAVA_HOME" ]; then
        export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    fi
    
    # Maven options for performance
    export MAVEN_OPTS="-Xmx4g -XX:+UseG1GC"
    
    echo "Running fast build without tests..."
    ./mvnw install -Ppublic -DskipTests -Dmaven.javadoc.skip=true -ntp -Dskip.installyarn -Dskip.yarn
    
    echo ""
    cd ..
}

package_distribution() {
    echo "📦 Packaging Nexus distribution..."
    local assembly_dir="$NEXUS_DIR/assemblies/nexus-repository-core/target/assembly"
    if [ ! -d "$assembly_dir" ]; then
        echo "❌ Assembly directory not found: $assembly_dir"
        return
    fi

    local target_dir="$NEXUS_DIR/assemblies/nexus-repository-core/target"
    local base_name="nexus-${PROJECT_VERSION}"

    # Create etc directory if it doesn't exist and add default nexus.properties with nexus.edition=CORE
    mkdir -p "$assembly_dir/etc"
    cat > "$assembly_dir/etc/nexus.properties" << 'EOF'
# Default Nexus properties
# This file sets default configuration values for Nexus Repository
# You can override these settings by creating a nexus.properties file
# in your NEXUS_DATA/etc directory (e.g., /nexus-data/etc/nexus.properties)

# Set the Nexus edition to CORE (required for OSS version)
nexus.edition=CORE
EOF

    # Create bin directory if it doesn't exist and add nexus-env.sh to set INSTALL4J_ADD_VM_PARAMS
    mkdir -p "$assembly_dir/bin"
    cat > "$assembly_dir/bin/nexus-env.sh" << 'EOF'
#!/bin/bash
# Nexus environment configuration
# This script sets the INSTALL4J_ADD_VM_PARAMS environment variable with default values
# Source this script before starting Nexus or add it to your shell profile
# You can also set INSTALL4J_ADD_VM_PARAMS manually to override these defaults

# Only set if not already defined
if [ -z "$INSTALL4J_ADD_VM_PARAMS" ]; then
  export INSTALL4J_ADD_VM_PARAMS="-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=${NEXUS_DATA:-./sonatype-work/nexus3}/javaprefs -Dnexus.edition=CORE"
  echo "INSTALL4J_ADD_VM_PARAMS set to: $INSTALL4J_ADD_VM_PARAMS"
else
  echo "INSTALL4J_ADD_VM_PARAMS already set to: $INSTALL4J_ADD_VM_PARAMS"
fi
EOF
    chmod +x "$assembly_dir/bin/nexus-env.sh"

    echo "  • Creating ${base_name}-unix.tar.gz"
    tar -czf "$target_dir/${base_name}-unix.tar.gz" -C "$assembly_dir" .

    echo "  • Creating ${base_name}.zip"
    (cd "$assembly_dir" && zip -qry "$target_dir/${base_name}.zip" .)

    echo ""
}

# Find and display artifacts
find_artifacts() {
    echo "📦 Searching for build artifacts..."
    cd "$NEXUS_DIR"
    
    ARTIFACTS=$(find . -name "nexus-*.tar.gz" -o -name "nexus-*.zip" 2>/dev/null)
    
    if [ -z "$ARTIFACTS" ]; then
        echo "❌ No artifacts found!"
        exit 1
    fi
    
    echo "✅ Found artifacts:"
    echo "$ARTIFACTS" | while read -r artifact; do
        SIZE=$(du -h "$artifact" | cut -f1)
        echo "  - $artifact ($SIZE)"
    done
    
    echo ""
    echo "🎉 Build completed successfully!"
    echo ""
    echo "You can now use the artifacts for:"
    echo "  - Direct installation"
    echo "  - Docker image build"
    echo "  - Distribution"
}

# Main flow
main() {
    check_requirements
    clone_or_update
    install_dependencies
    build_frontend
    build_nexus
    package_distribution
    find_artifacts
}

# Execute script
main
