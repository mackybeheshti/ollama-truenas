#!/bin/bash

# Fix Permissions Script for Ollama TrueNAS Project
# This script sets up proper permissions for multiple users to work on the project

set -e

echo "========================================="
echo "Fixing Permissions for Ollama TrueNAS App"
echo "========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "This script must be run as root or with sudo"
   exit 1
fi

PROJECT_DIR="/mnt/nvme-pool-2T/macky-work/08-ollama-truenas"
ADMIN_USER="admin"
MACKY_USER="macky"
APPS_USER="apps"
HOME_USERS_GROUP="home-users"

echo "Project Directory: $PROJECT_DIR"
echo "Users: $ADMIN_USER, $MACKY_USER"
echo ""

# Navigate to project directory
cd "$PROJECT_DIR"

echo "Step 1: Creating a shared group for the project..."
# Check if ollama-dev group exists, if not create it
if ! getent group ollama-dev > /dev/null 2>&1; then
    groupadd ollama-dev
    echo "✓ Created ollama-dev group"
else
    echo "✓ ollama-dev group already exists"
fi

echo ""
echo "Step 2: Adding users to the ollama-dev group..."
usermod -a -G ollama-dev "$ADMIN_USER"
usermod -a -G ollama-dev "$MACKY_USER"
echo "✓ Added $ADMIN_USER to ollama-dev group"
echo "✓ Added $MACKY_USER to ollama-dev group"

echo ""
echo "Step 3: Setting ownership for development files..."
# Set the main project files to be owned by admin but group ollama-dev
chown -R ${ADMIN_USER}:ollama-dev .

echo ""
echo "Step 4: Setting permissions for collaborative work..."
# Set directory permissions - 775 allows group write
find . -type d -exec chmod 775 {} \;

# Set file permissions - 664 allows group write  
find . -type f -exec chmod 664 {} \;

# Make scripts executable
find . -name "*.sh" -type f -exec chmod 775 {} \;

echo ""
echo "Step 5: Setting special permissions for TrueNAS app directory..."
# The ix-dev/community/ollama directory needs special handling for TrueNAS
if [ -d "ix-dev/community/ollama" ]; then
    # TrueNAS expects apps:apps ownership for the actual app
    chown -R ${APPS_USER}:${APPS_USER} ix-dev/community/ollama
    
    # But we'll use ACLs to grant access to our development group
    # Enable ACL if not already enabled
    setfacl -R -m g:ollama-dev:rwx ix-dev/community/ollama
    setfacl -R -d -m g:ollama-dev:rwx ix-dev/community/ollama
    
    echo "✓ Set TrueNAS app directory ownership to apps:apps"
    echo "✓ Added ACL for ollama-dev group to access TrueNAS app directory"
fi

echo ""
echo "Step 6: Setting sticky bit on directories for group collaboration..."
# Set sticky bit on directories so new files inherit group
find . -type d -exec chmod g+s {} \;

echo ""
echo "Step 7: Creating a working directory for temporary files..."
if [ ! -d "working" ]; then
    mkdir -p working
fi
chown ${ADMIN_USER}:ollama-dev working
chmod 775 working
chmod g+s working

echo ""
echo "Step 8: Setting up Git for shared repository (if .git exists)..."
if [ -d ".git" ]; then
    # Make git repository shared
    git config core.sharedRepository group
    chmod -R g+rwX .git
    chown -R ${ADMIN_USER}:ollama-dev .git
    echo "✓ Configured git for group collaboration"
fi

echo ""
echo "Step 9: Creating helper scripts for users..."

# Create a script for users to fix permissions after creating new files
cat > fix_my_permissions.sh << 'EOF'
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
EOF

chmod 775 fix_my_permissions.sh
chown ${ADMIN_USER}:ollama-dev fix_my_permissions.sh

echo ""
echo "Step 10: Verifying permissions..."

echo ""
echo "Main project directory:"
ls -ld .

echo ""
echo "TrueNAS app directory:"
ls -ld ix-dev/community/ollama

echo ""
echo "Sample file permissions:"
ls -l README.md

echo ""
echo "ACL permissions on TrueNAS directory:"
getfacl ix-dev/community/ollama | head -15

echo ""
echo "========================================="
echo "✓ Permission Setup Complete!"
echo "========================================="
echo ""
echo "IMPORTANT NOTES:"
echo "1. Both 'admin' and 'macky' users now have full read/write access"
echo "2. Users need to log out and back in for group changes to take effect"
echo "3. New files created should inherit the correct group permissions"
echo "4. Run './fix_my_permissions.sh' if permissions get out of sync"
echo ""
echo "To verify user groups after re-login:"
echo "  id admin"
echo "  id macky"
echo ""
echo "The ollama-dev group members are:"
getent group ollama-dev
echo ""
echo "You may need to run: newgrp ollama-dev"
echo "to activate the group in your current session"
