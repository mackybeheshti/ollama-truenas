#!/bin/bash

echo "Verifying Ollama TrueNAS App Setup..."
echo "======================================="

# Check directory structure
echo "Checking directory structure..."
required_dirs=(
    "ix-dev/community/ollama"
    "ix-dev/community/ollama/metadata"
    "monitoring/prometheus"
    "monitoring/grafana"
    "docs"
    "tests"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✓ $dir exists"
    else
        echo "✗ $dir missing"
    fi
done

# Check files
echo ""
echo "Checking required files..."
required_files=(
    "README.md"
    "LICENSE"
    ".gitignore"
    "ix-dev/community/ollama/app.yaml"
    "ix-dev/community/ollama/questions.yaml"
    "ix-dev/community/ollama/docker-compose.yaml"
    "ix-dev/community/ollama/metadata/description.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

# Check permissions
echo ""
echo "Checking permissions..."
echo "Directory permissions (should be 755):"
stat -c "%a %n" ix-dev/community/ollama

echo "File permissions (should be 644):"
stat -c "%a %n" ix-dev/community/ollama/*.yaml

echo ""
echo "Verification complete!"
