#!/bin/bash
# Quick script to fix permissions after creating new files

echo "Fixing permissions for new files..."

# Fix group ownership
sudo chgrp -R ollama-dev .

# Fix directory permissions
find . -type d -exec sudo chmod 775 {} \;

# Fix file permissions
find . -type f -exec sudo chmod 664 {} \;

# Fix script permissions
find . -name "*.sh" -type f -exec sudo chmod 775 {} \;

# Fix TrueNAS app directory
if [ -d "ix-dev/community/ollama" ]; then
    sudo chown -R apps:apps ix-dev/community/ollama
    sudo setfacl -R -m g:ollama-dev:rwx ix-dev/community/ollama
fi

echo "Permissions fixed!"
