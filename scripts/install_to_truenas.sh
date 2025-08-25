#!/bin/bash

# Script to install Ollama app to TrueNAS Scale
# This script copies the app to the TrueNAS applications directory

set -e

echo "========================================="
echo "Ollama TrueNAS App Installer"
echo "========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "This script must be run as root or with sudo"
   exit 1
fi

# Configuration
SOURCE_DIR="/mnt/nvme-pool-2T/macky-work/08-ollama-truenas"
TRUENAS_APPS_DIR="/mnt/.ix-apps/truenas_catalog"
COMMUNITY_TRAIN="${TRUENAS_APPS_DIR}/community"
APP_NAME="ollama"
APP_DIR="${COMMUNITY_TRAIN}/${APP_NAME}"

echo "Source: $SOURCE_DIR"
echo "Destination: $APP_DIR"
echo ""

# Check if source exists
if [ ! -d "$SOURCE_DIR/ix-dev/community/ollama" ]; then
    echo "ERROR: Source directory not found!"
    echo "Expected: $SOURCE_DIR/ix-dev/community/ollama"
    exit 1
fi

# Create community train if it doesn't exist
if [ ! -d "$COMMUNITY_TRAIN" ]; then
    echo "Creating community train directory..."
    mkdir -p "$COMMUNITY_TRAIN"
fi

# Backup existing app if it exists
if [ -d "$APP_DIR" ]; then
    echo "Backing up existing app..."
    BACKUP_DIR="${APP_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    mv "$APP_DIR" "$BACKUP_DIR"
    echo "Backup saved to: $BACKUP_DIR"
fi

# Copy app to TrueNAS directory
echo "Installing Ollama app..."
cp -r "$SOURCE_DIR/ix-dev/community/ollama" "$APP_DIR"

# Set proper permissions
echo "Setting permissions..."
chown -R root:root "$APP_DIR"
chmod -R 755 "$APP_DIR"
chmod 644 "$APP_DIR"/*.yaml
chmod 644 "$APP_DIR"/*.json 2>/dev/null || true
chmod 644 "$APP_DIR"/metadata/* 2>/dev/null || true

# Create catalog.json if needed
echo "Creating catalog entry..."
cat > "${COMMUNITY_TRAIN}/catalog.json" << 'EOF'
{
  "apps": {
    "ollama": {
      "app_readme": "https://raw.githubusercontent.com/mackybeheshti/ollama-truenas/main/ix-dev/community/ollama/README.md",
      "categories": ["ai", "productivity"],
      "description": "Run Large Language Models locally with GPU acceleration",
      "healthy": true,
      "healthy_error": null,
      "home": "https://ollama.ai",
      "location": "/__w/catalog/catalog/community/ollama",
      "latest_version": "1.0.0",
      "latest_app_version": "0.3.14",
      "latest_human_version": "0.3.14_1.0.0",
      "name": "ollama",
      "recommended": false,
      "title": "Ollama",
      "sources": [
        "https://github.com/ollama/ollama",
        "https://github.com/mackybeheshti/ollama-truenas"
      ],
      "icon_url": "https://raw.githubusercontent.com/mackybeheshti/ollama-truenas/main/ix-dev/community/ollama/icon.png"
    }
  }
}
EOF

# Refresh TrueNAS apps catalog
echo "Refreshing TrueNAS apps catalog..."
# Try to refresh using midclt if available
if command -v midclt &> /dev/null; then
    midclt call catalog.sync_all
    echo "✓ Catalog refreshed via midclt"
elif command -v cli &> /dev/null; then
    cli -c "app catalog_sync_all"
    echo "✓ Catalog refreshed via cli"
else
    echo "⚠ Could not refresh catalog automatically"
    echo "Please refresh manually in TrueNAS web UI:"
    echo "Apps → Manage Catalogs → Refresh"
fi

echo ""
echo "========================================="
echo "✓ Installation Complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Go to TrueNAS web UI"
echo "2. Navigate to Apps → Available Applications"
echo "3. Look for 'Ollama' in the Community train"
echo "4. Click Install and configure"
echo ""
echo "If you don't see the app:"
echo "1. Go to Apps → Manage Catalogs"
echo "2. Click Refresh"
echo "3. Check the Community train"
echo ""
echo "For manual installation from this directory:"
echo "cd $SOURCE_DIR"
echo "docker-compose -f ix-dev/community/ollama/docker-compose.yaml up -d"
