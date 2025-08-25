#!/bin/bash

# Script to mark the app as BETA/TEST version

echo "Marking app as BETA/TEST version..."

cd /mnt/nvme-pool-2T/macky-work/08-ollama-truenas

# Update local files
echo "Updating local files..."

# Update app.yaml
sed -i 's/title: "Ollama GPU Enhanced"/title: "Ollama GPU Enhanced (BETA - TESTING)"/g' ix-dev/community/ollama-gpu/app.yaml
sed -i 's/description: "Run Large Language Models locally with GPU acceleration"/description: "⚠️ BETA TEST VERSION - DO NOT USE IN PRODUCTION ⚠️ - Ollama with GPU acceleration"/g' ix-dev/community/ollama-gpu/app.yaml

# Add warning to README
cat > ix-dev/community/ollama-gpu/README.md << 'EOF'
# ⚠️ BETA TEST VERSION - DO NOT USE IN PRODUCTION ⚠️

# Ollama GPU Enhanced - TrueNAS Scale App

**WARNING: This is a BETA test version. It is currently under development and testing.**

**DO NOT INSTALL THIS FOR PRODUCTION USE**

## Testing Status
- 🔧 **Status**: Beta Testing
- ⚠️ **Stability**: Unstable
- 🐛 **Known Issues**: GPU detection may vary
- 👤 **For**: Developers and testers only

## If You Want to Test
Please report issues at: https://github.com/mackybeheshti/ollama-truenas/issues

## Features (In Testing)
- 🚀 Full NVIDIA GPU acceleration
- 🌐 Web UI for easy interaction
- 📊 Real-time GPU monitoring
- 🔄 GPU sharing with Plex/Immich
- 💾 Persistent model storage
- 🔒 Optional API authentication

## Requirements
- TrueNAS Scale 24.04+
- NVIDIA GPU with CUDA support
- Test environment (not production)
- Willingness to report bugs

## Support
- [GitHub Issues](https://github.com/mackybeheshti/ollama-truenas/issues)

## License
MIT - Test at your own risk
EOF

# Update questions.yaml to add warning
sed -i '1s/^/# ⚠️ BETA TEST VERSION - NOT FOR PRODUCTION USE ⚠️\n/' ix-dev/community/ollama-gpu/questions.yaml

# Add a warning group at the top of questions
cat > /tmp/warning_section.yaml << 'EOF'
groups:
  - name: "⚠️ WARNING - BETA VERSION ⚠️"
    description: "This is a BETA test version. Do not use in production!"
EOF

# Prepend warning to questions.yaml groups
grep -v "^groups:" ix-dev/community/ollama-gpu/questions.yaml > /tmp/questions_temp.yaml
cat /tmp/warning_section.yaml > ix-dev/community/ollama-gpu/questions.yaml
echo "" >> ix-dev/community/ollama-gpu/questions.yaml
cat /tmp/questions_temp.yaml >> ix-dev/community/ollama-gpu/questions.yaml
rm /tmp/warning_section.yaml /tmp/questions_temp.yaml

# Update upgrade_info.json
sed -i 's/"description": "Ollama - Run Large Language Models locally"/"description": "⚠️ BETA TEST - Ollama GPU Enhanced - NOT FOR PRODUCTION"/g' ix-dev/community/ollama-gpu/upgrade_info.json

# Now copy to TrueNAS directories
echo "Updating TrueNAS installation..."

# Copy to trains directory
sudo cp -r ix-dev/community/ollama-gpu /mnt/.ix-apps/truenas_catalog/trains/community/
sudo chown -R root:root /mnt/.ix-apps/truenas_catalog/trains/community/ollama-gpu
sudo chmod -R 755 /mnt/.ix-apps/truenas_catalog/trains/community/ollama-gpu

# Copy to ix-dev directory
sudo cp -r ix-dev/community/ollama-gpu /mnt/.ix-apps/truenas_catalog/ix-dev/community/
sudo chown -R root:root /mnt/.ix-apps/truenas_catalog/ix-dev/community/ollama-gpu

echo ""
echo "✅ App marked as BETA/TEST version"
echo ""
echo "The app now shows:"
echo "- Title: 'Ollama GPU Enhanced (BETA - TESTING)'"
echo "- Warning messages in description"
echo "- Beta warning in README"
echo "- Warning group in configuration"
echo ""
echo "Please refresh the TrueNAS catalog to see the changes."
