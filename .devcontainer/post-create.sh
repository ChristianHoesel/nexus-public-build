#!/bin/bash
set -e

echo "🚀 Nexus Public Build Environment Setup"
echo "========================================"

# Enable Corepack for Yarn 4.x support
echo "📦 Enabling Corepack for Yarn 4.x..."
corepack enable

# Set JAVA_HOME
if [ -z "$JAVA_HOME" ]; then
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
    echo "export MAVEN_OPTS=\"-Xmx4g -XX:+UseG1GC\"" >> ~/.bashrc
    echo "✅ JAVA_HOME set in ~/.bashrc"
fi

# Verify installations
echo ""
echo "✅ Installed versions:"
echo "   Java: $(java -version 2>&1 | head -n 1)"
echo "   JAVA_HOME: $JAVA_HOME"
echo "   Node: $(node -v)"
echo "   NPM: $(npm -v)"
echo "   Corepack: $(corepack --version)"
echo "   Maven: $(mvn -v | head -n 1)"
echo "   Git: $(git --version)"

# Make build script executable
echo ""
echo "🔧 Setting permissions..."
chmod +x build-local.sh

# Configure Git (if not already configured)
if ! git config --global user.name > /dev/null 2>&1; then
    echo ""
    echo "ℹ️  Git configuration not found."
    echo "   You can set this later with the following commands:"
    echo "   git config --global user.name 'Your Name'"
    echo "   git config --global user.email 'your.email@example.com'"
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "🎯 Next steps:"
echo "   1. Run build: ./build-local.sh release-3.84.1-01"
echo "   2. Or test directly in GitHub Actions"
echo "   3. Build Docker image (optional)"
echo ""
