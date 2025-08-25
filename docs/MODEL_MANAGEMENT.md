# Model Management Guide

## Overview

This guide covers model management for Ollama on TrueNAS, optimized for the Tesla P40's 24GB VRAM.

## Table of Contents
- [Model Storage](#model-storage)
- [Model Selection for P40](#model-selection-for-p40)
- [Downloading Models](#downloading-models)
- [Managing VRAM](#managing-vram)
- [Model Optimization](#model-optimization)
- [Automation Scripts](#automation-scripts)

## Model Storage

### Storage Requirements

| Model Size | Disk Space | VRAM Required | P40 Capacity |
|------------|------------|---------------|--------------|
| 3B params | ~2GB | 3-4GB | 6-8 models |
| 7B params | ~4GB | 6-8GB | 3 models |
| 13B params | ~8GB | 12-14GB | 1-2 models |
| 30B params | ~16GB | 20-22GB | 1 model |
| 70B params | ~40GB | 40GB+ | Requires quantization |

### Storage Configuration

```bash
# Recommended directory structure
/mnt/pool/ollama-models/
├── manifests/      # Model metadata
├── blobs/          # Model weights
└── backups/        # Model backups
```

## Model Selection for P40

### Recommended Models for 24GB VRAM

#### Tier 1: Best Performance (Run Multiple)
```bash
# Small, fast models - Can run 6+ simultaneously
ollama pull llama3.2:3b
ollama pull phi3:mini
ollama pull gemma2:2b
ollama pull qwen2.5:3b
```

#### Tier 2: Balanced (Run 2-3)
```bash
# Medium models - Good balance
ollama pull llama3.1:8b
ollama pull mistral:7b
ollama pull gemma2:9b
ollama pull deepseek-coder:6.7b
```

#### Tier 3: Large Models (Run 1)
```bash
# Large models - Maximum capability
ollama pull llama3.1:70b-instruct-q4_0  # Quantized
ollama pull mixtral:8x7b
ollama pull qwen2.5:32b
ollama pull command-r:35b
```

### P40-Specific Optimizations

```bash
# For P40, use these environment variables
export OLLAMA_NUM_GPU_LAYERS=99  # Offload all layers to GPU
export OLLAMA_GPU_MEMORY=23000   # Leave 1GB for system
export OLLAMA_KEEP_ALIVE=5m      # Unload after 5 minutes
```

## Downloading Models

### Via CLI

```bash
# Basic download
ollama pull llama3.2:3b

# Download specific version
ollama pull llama3.2:3b-instruct-fp16

# Download with progress
curl -X POST http://localhost:11434/api/pull \
  -d '{"name": "llama3.2:3b", "stream": true}'
```

### Via API

```python
# Python script for model management
import requests
import json

def download_model(model_name):
    url = "http://localhost:11434/api/pull"
    data = {"name": model_name, "stream": True}
    
    response = requests.post(url, json=data, stream=True)
    for line in response.iter_lines():
        if line:
            progress = json.loads(line)
            if 'status' in progress:
                print(f"{progress['status']}: {progress.get('progress', '')}")

# Download models
models = ["llama3.2:3b", "mistral:7b", "phi3:mini"]
for model in models:
    print(f"Downloading {model}...")
    download_model(model)
```

### Via Web UI

Access Open WebUI at `http://your-nas:8080`:
1. Navigate to Settings → Models
2. Click "Download Model"
3. Enter model name (e.g., `llama3.2:3b`)
4. Click Download

## Managing VRAM

### Monitor VRAM Usage

```bash
# Check current VRAM usage
nvidia-smi --query-gpu=memory.used,memory.free --format=csv

# Monitor per-process VRAM
nvidia-smi pmon -i 0

# Watch VRAM in real-time
watch -n 1 'nvidia-smi --query-gpu=memory.used --format=csv,noheader'
```

### VRAM Management Script

```bash
#!/bin/bash
# vram-manager.sh - Manage model loading based on VRAM

MAX_VRAM=23000  # MB (leaving 1GB free on P40)

get_vram_usage() {
    nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
}

list_loaded_models() {
    curl -s http://localhost:11434/api/tags | jq -r '.models[] | select(.size > 0) | .name'
}

unload_model() {
    local model=$1
    echo "Unloading model: $model"
    curl -X POST http://localhost:11434/api/generate \
      -d "{\"model\": \"$model\", \"keep_alive\": 0}"
}

check_vram_and_unload() {
    local current_vram=$(get_vram_usage)
    
    if [ $current_vram -gt $MAX_VRAM ]; then
        echo "VRAM usage high: ${current_vram}MB / ${MAX_VRAM}MB"
        
        # Unload least recently used model
        local oldest_model=$(list_loaded_models | tail -1)
        if [ ! -z "$oldest_model" ]; then
            unload_model "$oldest_model"
        fi
    fi
}

# Run continuously
while true; do
    check_vram_and_unload
    sleep 30
done
```

### Model Preloading

```bash
#!/bin/bash
# preload-models.sh - Preload models at startup

MODELS=(
    "llama3.2:3b"
    "mistral:7b"
    "phi3:mini"
)

for model in "${MODELS[@]}"; do
    echo "Preloading $model..."
    curl -X POST http://localhost:11434/api/generate \
      -d "{\"model\": \"$model\", \"prompt\": \"test\", \"keep_alive\": \"24h\"}"
    
    # Check VRAM after each load
    vram=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    echo "VRAM used: ${vram}MB"
    
    if [ $vram -gt 20000 ]; then
        echo "VRAM limit reached, stopping preload"
        break
    fi
done
```

## Model Optimization

### Quantization for Large Models

For 70B+ models on P40, use quantization:

```bash
# Download quantized versions
ollama pull llama3.1:70b-instruct-q4_0  # 4-bit quantization
ollama pull llama3.1:70b-instruct-q5_0  # 5-bit quantization
ollama pull llama3.1:70b-instruct-q8_0  # 8-bit quantization
```

### Quantization Impact

| Quantization | Model Size | VRAM Usage | Performance | Quality |
|--------------|------------|------------|-------------|---------|
| FP16 (full) | 100% | 100% | Fastest | Best |
| Q8_0 | 50% | 50% | Fast | Excellent |
| Q5_0 | 35% | 35% | Good | Very Good |
| Q4_0 | 25% | 25% | Moderate | Good |
| Q3_0 | 20% | 20% | Slower | Acceptable |

### Custom Model Configuration

Create custom modelfiles for P40 optimization:

```dockerfile
# Modelfile.p40
FROM llama3.2:3b

# P40 optimizations
PARAMETER num_gpu 99
PARAMETER num_thread 8
PARAMETER num_batch 512
PARAMETER context_length 4096
PARAMETER temperature 0.7

# System prompt
SYSTEM "You are a helpful assistant optimized for Tesla P40 GPU inference."
```

Build and use:
```bash
ollama create llama3.2-p40 -f Modelfile.p40
ollama run llama3.2-p40
```

## Automation Scripts

### Auto-Download Script

```bash
#!/bin/bash
# auto-download.sh - Download models based on VRAM availability

get_available_vram() {
    local total=24000
    local used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
    echo $((total - used))
}

download_if_space() {
    local model=$1
    local required_vram=$2
    local available=$(get_available_vram)
    
    if [ $available -gt $required_vram ]; then
        echo "Downloading $model (requires ${required_vram}MB, have ${available}MB)"
        ollama pull $model
        return 0
    else
        echo "Skipping $model (requires ${required_vram}MB, only ${available}MB available)"
        return 1
    fi
}

# Model list with VRAM requirements
declare -A models=(
    ["llama3.2:3b"]=3500
    ["mistral:7b"]=7500
    ["phi3:mini"]=2000
    ["gemma2:9b"]=9000
    ["qwen2.5:7b"]=7500
)

for model in "${!models[@]}"; do
    download_if_space "$model" "${models[$model]}"
    sleep 5
done
```

### Model Cleanup Script

```bash
#!/bin/bash
# cleanup-models.sh - Remove unused models

# List all downloaded models
all_models=$(ollama list | tail -n +2 | awk '{print $1}')

# Get last used time for each model
for model in $all_models; do
    last_used=$(ollama show $model --verbose 2>/dev/null | grep "Last used" | cut -d: -f2-)
    
    # If not used in 30 days, mark for deletion
    if [[ $(date -d "$last_used" +%s) -lt $(date -d "30 days ago" +%s) ]]; then
        echo "Removing old model: $model"
        ollama rm $model
    fi
done

# Clean up orphaned blobs
ollama prune
```

## Monitoring Models

### Prometheus Metrics

Add to your Prometheus configuration:

```yaml
- job_name: 'ollama_models'
  static_configs:
    - targets: ['localhost:11434']
  metrics_path: '/api/metrics'
  params:
    format: ['prometheus']
```

### Grafana Dashboard Queries

```promql
# Models loaded in memory
count(ollama_model_loaded)

# VRAM per model
ollama_model_vram_bytes / 1024 / 1024 / 1024

# Model request rate
rate(ollama_model_requests_total[5m])

# Average inference time
rate(ollama_inference_duration_seconds_sum[5m]) / 
rate(ollama_inference_duration_seconds_count[5m])
```

## Best Practices

1. **Regular Cleanup**: Remove unused models monthly
2. **VRAM Reserve**: Always keep 1-2GB free
3. **Model Versions**: Test quantized versions for large models
4. **Batch Downloads**: Download during off-peak hours
5. **Monitor Temperature**: P40 runs hot with continuous inference

## Troubleshooting

### Model Won't Load
```bash
# Check available VRAM
nvidia-smi --query-gpu=memory.free --format=csv

# Try unloading other models
ollama stop all

# Force unload
pkill -f ollama
```

### Slow Inference
```bash
# Check GPU utilization
nvidia-smi --query-gpu=utilization.gpu --format=csv

# Verify model is on GPU
ollama show model-name --verbose | grep GPU
```

### Out of Memory
```bash
# Emergency VRAM clear
sudo nvidia-smi --gpu-reset

# Reduce context length
export OLLAMA_NUM_CTX=2048
```

## Conclusion

Effective model management on the Tesla P40 requires balancing model size, performance, and VRAM usage. With 24GB VRAM, you can run impressive models, but careful management ensures optimal performance.
