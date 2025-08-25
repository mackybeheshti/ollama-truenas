#!/bin/bash

# GPU Detection Script for Ollama TrueNAS
# Detects GPU capabilities and recommends settings

echo "========================================="
echo "GPU Detection and Configuration Tool"
echo "========================================="
echo ""

# Check if nvidia-smi is available
if ! command -v nvidia-smi &> /dev/null; then
    echo "ERROR: nvidia-smi not found. Please install NVIDIA drivers."
    exit 1
fi

# Get GPU information
GPU_COUNT=$(nvidia-smi --query-gpu=count --format=csv,noheader | head -1)
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)
GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
GPU_COMPUTE=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -1)
GPU_DRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)

# Check for NVENC support
NVENC_SUPPORT="No"
if nvidia-smi --query-gpu=encoder.stats.sessionCount --format=csv,noheader 2>/dev/null | head -1 > /dev/null; then
    NVENC_SUPPORT="Yes"
fi

# Convert memory to GB
GPU_MEMORY_GB=$((GPU_MEMORY / 1024))

echo "=== GPU Information ==="
echo "GPU Model:         $GPU_NAME"
echo "GPU Count:         $GPU_COUNT"
echo "VRAM:             ${GPU_MEMORY_GB}GB (${GPU_MEMORY}MB)"
echo "Compute Capability: $GPU_COMPUTE"
echo "Driver Version:    $GPU_DRIVER"
echo "NVENC Support:     $NVENC_SUPPORT"
echo ""

echo "=== Recommended Settings ==="

# Determine GPU tier and recommendations
if [ $GPU_MEMORY -ge 20000 ]; then
    # 20GB+ VRAM (High-end)
    echo "GPU Tier:          HIGH-END (20GB+ VRAM)"
    echo "VRAM Limit:        $((GPU_MEMORY_GB - 2))GB"
    echo "Max Models:        3-4"
    echo "Recommended Models:"
    echo "  - llama3.1:70b-instruct-q4_0 (quantized 70B)"
    echo "  - mixtral:8x7b (mixture of experts)"
    echo "  - qwen2.5:32b (very capable)"
    echo "  - llama3.1:8b (can run multiple)"
    
elif [ $GPU_MEMORY -ge 10000 ]; then
    # 10-20GB VRAM (Mid-range)
    echo "GPU Tier:          MID-RANGE (10-20GB VRAM)"
    echo "VRAM Limit:        $((GPU_MEMORY_GB - 2))GB"
    echo "Max Models:        2-3"
    echo "Recommended Models:"
    echo "  - llama3.2:3b (fast, efficient)"
    echo "  - mistral:7b (balanced)"
    echo "  - codellama:7b (for coding)"
    echo "  - gemma2:9b (Google's model)"
    
elif [ $GPU_MEMORY -ge 6000 ]; then
    # 6-10GB VRAM (Entry-level)
    echo "GPU Tier:          ENTRY-LEVEL (6-10GB VRAM)"
    echo "VRAM Limit:        $((GPU_MEMORY_GB - 1))GB"
    echo "Max Models:        1-2"
    echo "Recommended Models:"
    echo "  - llama3.2:3b (best for this tier)"
    echo "  - phi3:mini (tiny but capable)"
    echo "  - mistral:7b-instruct-q4_0 (quantized)"
    
else
    # Less than 6GB VRAM
    echo "GPU Tier:          LOW-END (<6GB VRAM)"
    echo "VRAM Limit:        $((GPU_MEMORY_GB - 1))GB"
    echo "Max Models:        1"
    echo "Recommended Models:"
    echo "  - phi3:mini (2.7B parameters)"
    echo "  - llama3.2:1b (smallest Llama)"
    echo "  - tinyllama:1b (very small)"
fi

echo ""
echo "=== Configuration YAML ==="
echo "Add these to your TrueNAS configuration:"
echo ""
echo "gpu_device: \"0\""
echo "vram_limit: $((GPU_MEMORY_GB - 2))"
echo "enable_gpu: true"
echo "nvidia_driver_capabilities: \"compute,utility\""

if [ "$NVENC_SUPPORT" = "Yes" ]; then
    echo ""
    echo "=== Plex Transcoding ==="
    echo "✓ Your GPU supports NVENC hardware transcoding!"
    echo "This GPU can be shared between Ollama and Plex."
else
    echo ""
    echo "=== Plex Transcoding ==="
    echo "✗ Your GPU does NOT support NVENC (Tesla series?)"
    echo "Plex will need to use CPU transcoding."
fi

echo ""
echo "=== Docker Compose Environment ==="
echo "Add these environment variables:"
echo ""
echo "NVIDIA_VISIBLE_DEVICES=0"
echo "NVIDIA_DRIVER_CAPABILITIES=compute,utility"
echo "OLLAMA_GPU_MEMORY=$((GPU_MEMORY - 2048))"
echo "OLLAMA_NUM_GPU_LAYERS=99"

# Check CUDA compatibility
echo ""
echo "=== CUDA Compatibility ==="
COMPUTE_MAJOR=$(echo $GPU_COMPUTE | cut -d. -f1)
COMPUTE_MINOR=$(echo $GPU_COMPUTE | cut -d. -f2)

if [ "$COMPUTE_MAJOR" -ge 6 ]; then
    echo "✓ GPU supports modern CUDA features"
    echo "  Compute capability $GPU_COMPUTE is fully supported"
elif [ "$COMPUTE_MAJOR" -eq 5 ]; then
    echo "⚠ Older GPU detected (Maxwell architecture)"
    echo "  Some models may run slower"
else
    echo "✗ Very old GPU detected"
    echo "  May have compatibility issues with newer models"
fi

# Performance estimation
echo ""
echo "=== Performance Estimates ==="
echo "Based on $GPU_NAME:"

if [[ "$GPU_NAME" == *"4090"* ]] || [[ "$GPU_NAME" == *"4080"* ]]; then
    echo "- llama3.2:3b: ~100-120 tokens/sec"
    echo "- mistral:7b: ~60-80 tokens/sec"
    echo "- llama3.1:8b: ~50-70 tokens/sec"
elif [[ "$GPU_NAME" == *"3090"* ]] || [[ "$GPU_NAME" == *"3080"* ]]; then
    echo "- llama3.2:3b: ~70-90 tokens/sec"
    echo "- mistral:7b: ~40-50 tokens/sec"
    echo "- llama3.1:8b: ~35-45 tokens/sec"
elif [[ "$GPU_NAME" == *"3070"* ]] || [[ "$GPU_NAME" == *"3060"* ]]; then
    echo "- llama3.2:3b: ~45-60 tokens/sec"
    echo "- mistral:7b: ~25-35 tokens/sec"
    echo "- llama3.1:8b: ~20-30 tokens/sec"
elif [[ "$GPU_NAME" == *"P40"* ]] || [[ "$GPU_NAME" == *"V100"* ]]; then
    echo "- llama3.2:3b: ~45-50 tokens/sec"
    echo "- mistral:7b: ~30-35 tokens/sec"
    echo "- llama3.1:8b: ~25-30 tokens/sec"
else
    echo "- llama3.2:3b: ~30-50 tokens/sec (estimated)"
    echo "- mistral:7b: ~20-30 tokens/sec (estimated)"
    echo "- phi3:mini: ~60-80 tokens/sec (estimated)"
fi

# Test GPU in Docker
echo ""
echo "=== Docker GPU Test ==="
echo -n "Testing GPU access in Docker... "

if docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi > /dev/null 2>&1; then
    echo "✓ SUCCESS"
    echo "Docker can access your GPU!"
else
    echo "✗ FAILED"
    echo "Docker cannot access GPU. Please check:"
    echo "1. nvidia-container-toolkit is installed"
    echo "2. Docker daemon is configured correctly"
    echo "3. Run: sudo apt-get install nvidia-container-toolkit"
fi

echo ""
echo "========================================="
echo "Configuration complete!"
echo "Save these settings for your TrueNAS app configuration."
