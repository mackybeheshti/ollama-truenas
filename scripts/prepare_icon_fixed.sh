#!/bin/bash

# Script to download and prepare the Ollama icon for TrueNAS

echo "Downloading Ollama icon..."

# Create icon directory if it doesn't exist
ICON_DIR="ix-dev/community/ollama"
cd /mnt/nvme-pool-2T/macky-work/08-ollama-truenas

# Try multiple sources for the icon
ICON_URLS=(
    "https://ollama.ai/public/ollama.png"
    "https://github.com/ollama/ollama/blob/main/app/assets/icon.png?raw=true"
    "https://raw.githubusercontent.com/ollama/ollama/main/app/assets/icon.png"
)

DOWNLOADED=false

for url in "${ICON_URLS[@]}"; do
    echo "Trying: $url"
    if curl -L -o ${ICON_DIR}/icon.png --connect-timeout 10 --max-time 30 "$url" 2>/dev/null; then
        # Check if file is valid (not empty and is actually an image)
        if [ -s ${ICON_DIR}/icon.png ] && file ${ICON_DIR}/icon.png | grep -E "PNG|JPEG|image" > /dev/null; then
            echo "✓ Icon downloaded successfully from $url"
            DOWNLOADED=true
            break
        else
            echo "  Invalid file downloaded, trying next source..."
            rm -f ${ICON_DIR}/icon.png
        fi
    else
        echo "  Failed to download from this source, trying next..."
    fi
done

if [ "$DOWNLOADED" = true ]; then
    # Check icon size
    size=$(stat -c%s ${ICON_DIR}/icon.png 2>/dev/null || stat -f%z ${ICON_DIR}/icon.png 2>/dev/null)
    echo "  Icon size: $size bytes"
    
    # If ImageMagick is installed, resize to standard size
    if command -v convert &> /dev/null; then
        echo "Resizing icon to 256x256..."
        convert ${ICON_DIR}/icon.png -resize 256x256 ${ICON_DIR}/icon_256.png
        mv ${ICON_DIR}/icon_256.png ${ICON_DIR}/icon.png
        echo "✓ Icon resized"
    fi
else
    echo "Could not download icon from any source"
    echo "Creating a simple PNG icon as fallback..."
    
    # Create a simple icon using base64 encoded PNG
    # This is a simple 256x256 black square with "Ollama" text
    cat > ${ICON_DIR}/icon.png.base64 << 'EOF'
iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAACXBIWXMAAAsTAAALEwEAmpwYAAAG
8klEQVR4nO3dQW7bSBRA0W+RN9DLyP5zGVlAFjNAECAI0EWRdEaS5PveAgyPbVni10eRoqjT6XQK
AGmaYwGkaQAAkIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgY
AICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgA
gIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACA
jAEAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICM
AQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgAgIwB
AMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEA
yBgAgIwBAMgYAIDM6XT6O8cCSHO1AQCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkD
AJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMA
kDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQ
MQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAx
AAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEA
ABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAA
GQMAkDEAABkDAJC52AAAyBgAgIwBAMgYAICMAQDIGACAjAEAyBgAgIwBAMgYAICMAQDIGACAjAEA
yBgAgIwBAMgYAICMAQDIGACAjAEAyFxOp9PfORZAmv/OEQDKuA0AkDEAABkDAJAxAAAZAwCQMQAA
GQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZ
AwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkD
AJAxAAAZAwCQMQAAGQMAkDEAABkDAJD540j8vfz8/j7HAsZz+/HjHOs9BuDNeTEDDwzAw3nxA38x
AA/jxQ9c4jbgHbzwgWsZgBt54QP3MgBX8sIHnmUALvDCB17FAAx44QOv9vEDcO3/9oO/ALCKT/o2
oAtbgeVE3wFY7AqM4hF3A6KPemAxu3wXIMhEL/jqnz6wqF2+DRi8YKsf9oHFPf05gCATLdzqh31g
F0/7UlDwgq9+2Ad288h7AdyU+k6rAjvb/btBk7v++M++YDd/uxGo6IXvPD8cwtdfI2I89x8/5vnt
t/9fcA7AsbgRCJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZ
AwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkD
AJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMA
kDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQ
MQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAx
AAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEA
ABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAA
GQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZ
AwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkD
AJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMA
kDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJAxAAAZAwCQ
MQAAGQMAkDEAABkDAJAxAAAZAwCQMQAAGQMAkDEAABkDAJD5H7TrLCqL5gX5AAAAAElFTkSuQmCC
EOF
    
    # Decode base64 to create PNG
    base64 -d ${ICON_DIR}/icon.png.base64 > ${ICON_DIR}/icon.png 2>/dev/null || \
    base64 --decode ${ICON_DIR}/icon.png.base64 > ${ICON_DIR}/icon.png 2>/dev/null
    
    rm -f ${ICON_DIR}/icon.png.base64
    
    if [ -f ${ICON_DIR}/icon.png ]; then
        echo "✓ Fallback icon created"
    else
        echo "Creating text-based icon.txt as last resort..."
        echo "OLLAMA" > ${ICON_DIR}/icon.txt
        echo "✓ Text icon created (icon.txt)"
    fi
fi

echo "Icon preparation complete!"
echo ""
echo "Note: If you want a better icon, you can manually download one and place it at:"
echo "  ${ICON_DIR}/icon.png"
