#!/bin/bash

# Script to rename the app from ollama to ollama-gpu to avoid conflicts

set -e

echo "========================================="
echo "Renaming App to Ollama-GPU"
echo "========================================="

cd /mnt/nvme-pool-2T/macky-work/08-ollama-truenas

# New app name
OLD_NAME="ollama"
NEW_NAME="ollama-gpu"
NEW_TITLE="Ollama GPU Enhanced"

echo "Renaming from '$OLD_NAME' to '$NEW_NAME'..."

# Update app.yaml
sed -i "s/name: ollama/name: $NEW_NAME/g" ix-dev/community/$OLD_NAME/app.yaml
sed -i "s/title: \"Ollama\"/title: \"$NEW_TITLE\"/g" ix-dev/community/$OLD_NAME/app.yaml

# Update item.yaml
sed -i "s/name: ollama/name: $NEW_NAME/g" ix-dev/community/$OLD_NAME/item.yaml

# Update upgrade_info.json
sed -i "s/\"Ollama -/\"$NEW_TITLE -/g" ix-dev/community/$OLD_NAME/upgrade_info.json

# Update docker-compose.yaml container names
sed -i "s/container_name: ollama/container_name: $NEW_NAME/g" ix-dev/community/$OLD_NAME/docker-compose.yaml
sed -i "s/container_name: ollama-/container_name: ${NEW_NAME}-/g" ix-dev/community/$OLD_NAME/docker-compose.yaml

# Update questions.yaml display text
sed -i "s/\"Ollama /\"$NEW_TITLE /g" ix-dev/community/$OLD_NAME/questions.yaml

# Update README
sed -i "s/# Ollama TrueNAS/# $NEW_TITLE TrueNAS/g" ix-dev/community/$OLD_NAME/README.md

# Rename the directory
mv ix-dev/community/$OLD_NAME ix-dev/community/$NEW_NAME

echo "✓ App configuration files updated"

# Now install the renamed app
echo ""
echo "Installing renamed app to TrueNAS..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "Switching to root for installation..."
   sudo $0
   exit
fi

# Remove old installation
TRUENAS_APPS_DIR="/mnt/.ix-apps/truenas_catalog"
rm -rf ${TRUENAS_APPS_DIR}/community/$OLD_NAME
rm -rf ${TRUENAS_APPS_DIR}/community/${OLD_NAME}_backup*

# Install new version
APP_DIR="${TRUENAS_APPS_DIR}/community/${NEW_NAME}"
SOURCE_DIR="/mnt/nvme-pool-2T/macky-work/08-ollama-truenas/ix-dev/community/${NEW_NAME}"

echo "Copying to: $APP_DIR"
cp -r "$SOURCE_DIR" "$APP_DIR"

# Set permissions
chown -R root:root "$APP_DIR"
chmod -R 755 "$APP_DIR"
chmod 644 "$APP_DIR"/*.yaml
chmod 644 "$APP_DIR"/*.json 2>/dev/null || true

# Update catalog.json
cat > "${TRUENAS_APPS_DIR}/community/catalog.json" << EOF
{
  "apps": {
    "${NEW_NAME}": {
      "app_readme": "https://raw.githubusercontent.com/mackybeheshti/ollama-truenas/main/ix-dev/community/${NEW_NAME}/README.md",
      "categories": ["ai", "productivity"],
      "description": "Ollama with GPU acceleration, monitoring, and web UI - Enhanced version",
      "healthy": true,
      "healthy_error": null,
      "home": "https://github.com/mackybeheshti/ollama-truenas",
      "location": "/__w/catalog/catalog/community/${NEW_NAME}",
      "latest_version": "1.0.0",
      "latest_app_version": "0.3.14",
      "latest_human_version": "0.3.14_1.0.0",
      "name": "${NEW_NAME}",
      "recommended": true,
      "title": "${NEW_TITLE}",
      "sources": [
        "https://github.com/ollama/ollama",
        "https://github.com/mackybeheshti/ollama-truenas"
      ],
      "icon_url": "https://raw.githubusercontent.com/mackybeheshti/ollama-truenas/main/ix-dev/community/${NEW_NAME}/icon.png"
    }
  }
}
EOF

echo ""
echo "========================================="
echo "✓ App renamed to: $NEW_NAME"
echo "✓ Title: $NEW_TITLE"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Refresh the TrueNAS Apps catalog"
echo "2. Look for '$NEW_TITLE' in the Community section"
echo "3. It should be separate from the standard Ollama app"
