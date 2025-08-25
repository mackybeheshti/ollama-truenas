# GPU Sharing Guide for Ollama with Plex and Immich

## Overview

This guide explains how to configure GPU sharing between Ollama, Plex, and Immich on TrueNAS Scale, specifically optimized for the NVIDIA Tesla P40.

## Table of Contents
- [Tesla P40 Considerations](#tesla-p40-considerations)
- [GPU Sharing Methods](#gpu-sharing-methods)
- [Configuration Steps](#configuration-steps)
- [Resource Allocation Strategy](#resource-allocation-strategy)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)

## Tesla P40 Considerations

The Tesla P40 has unique characteristics that affect GPU sharing:

### Strengths
- **24GB VRAM** - Excellent for running large models
- **High Compute Power** - 12 TFLOPS FP32
- **ECC Memory** - Reliable for production workloads

### Limitations
- **No NVENC/NVDEC** - Cannot do hardware video encoding/decoding
- **Passive Cooling** - Requires good airflow
- **No Graphics Output** - Compute only

### Important Note for Plex
Since the P40 lacks NVENC, Plex will **NOT** be able to use it for hardware transcoding. Plex transcoding will need to:
- Use CPU transcoding instead
- Or use a secondary GPU with NVENC support (GTX/RTX series)

## GPU Sharing Methods

### Method 1: Time-Slicing (Recommended)
Best for sharing between Ollama and Immich (both compute workloads).

```bash
# Enable GPU time-slicing
sudo nvidia-smi -i 0 --compute-mode=DEFAULT

# Configure time-slice duration
sudo nvidia-smi -i 0 --applications-clocks=877,1189
```

### Method 2: MIG (Multi-Instance GPU)
**Note**: P40 does NOT support MIG (requires Ampere or newer). This section is for users with A100/A30/A40.

### Method 3: Process Priority
Use process priority to ensure Ollama gets GPU resources when needed:

```yaml
# In docker-compose.yaml
services:
  ollama:
    environment:
      - CUDA_VISIBLE_DEVICES=0
      - CUDA_DEVICE_ORDER=PCI_BUS_ID
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              capabilities: [gpu]
              options:
                priority: 100  # Higher priority
  
  immich-machine-learning:
    environment:
      - CUDA_VISIBLE_DEVICES=0
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              capabilities: [gpu]
              options:
                priority: 50   # Lower priority
```

## Configuration Steps

### Step 1: Install NVIDIA Container Runtime

```bash
# Check if nvidia-container-runtime is installed
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# If not installed, install it:
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### Step 2: Configure Docker Daemon

Edit `/etc/docker/daemon.json`:

```json
{
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  },
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  }
}
```

### Step 3: Set GPU Persistence Mode

```bash
# Enable persistence mode (recommended for P40)
sudo nvidia-smi -pm 1

# Set power limit (P40 TDP is 250W)
sudo nvidia-smi -pl 250
```

### Step 4: Configure Memory Allocation

For the P40's 24GB VRAM, recommended allocation:

| Service | VRAM Allocation | Use Case |
|---------|----------------|-----------|
| Ollama | 16-20GB | Large language models |
| Immich | 2-4GB | Photo AI processing |
| Reserved | 2GB | System overhead |

### Step 5: TrueNAS App Configuration

In the Ollama app configuration:

```yaml
# questions.yaml settings
gpu_device: "0"
vram_limit: 20  # GB - Leave 4GB for Immich
enable_gpu: true
host_network: true  # Required for GPU sharing
```

## Resource Allocation Strategy

### Dynamic Allocation Script

Create `/usr/local/bin/gpu-manager.sh`:

```bash
#!/bin/bash

# GPU Manager for P40 Sharing
# This script manages GPU allocation between services

OLLAMA_MAX_VRAM=20480  # 20GB in MB
IMMICH_MAX_VRAM=4096   # 4GB in MB

check_gpu_usage() {
    nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits
}

check_ollama_running() {
    docker ps --format "{{.Names}}" | grep -q "ollama"
}

check_immich_running() {
    docker ps --format "{{.Names}}" | grep -q "immich"
}

manage_gpu_allocation() {
    local current_usage=$(check_gpu_usage)
    
    if check_ollama_running; then
        echo "Ollama is running - prioritizing LLM workloads"
        # Set Ollama container memory limit
        docker update --memory="20g" ollama
    fi
    
    if check_immich_running && [ $current_usage -lt 20000 ]; then
        echo "GPU has available memory - allowing Immich processing"
        docker update --memory="4g" immich-machine-learning
    fi
}

# Monitor and adjust every 30 seconds
while true; do
    manage_gpu_allocation
    sleep 30
done
```

Make it executable and run as a service:

```bash
sudo chmod +x /usr/local/bin/gpu-manager.sh

# Create systemd service
sudo cat > /etc/systemd/system/gpu-manager.service << EOF
[Unit]
Description=GPU Resource Manager for P40
After=docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/gpu-manager.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable gpu-manager
sudo systemctl start gpu-manager
```

## Monitoring and Troubleshooting

### Monitor GPU Usage

```bash
# Real-time GPU monitoring
watch -n 1 nvidia-smi

# Check which processes are using GPU
nvidia-smi pmon -i 0

# Detailed GPU metrics
nvidia-smi -q -d UTILIZATION,MEMORY,TEMPERATURE,POWER
```

### Check Container GPU Access

```bash
# Test Ollama GPU access
docker exec ollama nvidia-smi

# Test Immich GPU access
docker exec immich-machine-learning nvidia-smi
```

### Common Issues and Solutions

#### Issue: GPU Memory Allocation Errors
```bash
# Solution: Clear GPU memory
sudo nvidia-smi --gpu-reset -i 0
```

#### Issue: High GPU Temperature (P40 Passive Cooling)
```bash
# Check temperature
nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader

# If > 80°C, improve airflow or reduce load
# Set temperature limit
sudo nvidia-smi -pl 200  # Reduce power limit
```

#### Issue: Containers Can't Access GPU
```bash
# Verify nvidia-container-runtime
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# Check docker runtime
docker info | grep nvidia
```

### Grafana Dashboard Queries

Add these to your Grafana dashboard for GPU sharing monitoring:

```promql
# GPU Memory per Container
sum by (container_name) (
  container_gpu_memory_usage_bytes{container_name=~"ollama|immich.*"}
)

# GPU Utilization per Container  
rate(container_gpu_utilization_seconds_total{container_name=~"ollama|immich.*"}[5m])

# Available GPU Memory
DCGM_FI_DEV_FB_TOTAL - DCGM_FI_DEV_FB_USED
```

## Best Practices

1. **Priority Order**: Ollama > Immich > Other services
2. **Memory Buffer**: Always leave 2GB VRAM free
3. **Temperature Monitoring**: P40 critical temp is 83°C
4. **Unload Models**: Use `OLLAMA_KEEP_ALIVE=5m` to free VRAM
5. **Scheduled Processing**: Run Immich ML during off-hours

## Example Configurations

### Ollama Priority Configuration
```yaml
# Ollama gets GPU priority
environment:
  - NVIDIA_VISIBLE_DEVICES=0
  - CUDA_MPS_PIPE_DIRECTORY=/tmp/nvidia-mps
  - CUDA_MPS_LOG_DIRECTORY=/tmp/nvidia-log
  - OLLAMA_KEEP_ALIVE=5m
  - OLLAMA_MAX_VRAM=20000
```

### Immich Background Processing
```yaml
# Immich runs when GPU is available
environment:
  - NVIDIA_VISIBLE_DEVICES=0
  - MACHINE_LEARNING_GPU_ENABLED=true
  - MACHINE_LEARNING_GPU_MEMORY_LIMIT=4000
  - MACHINE_LEARNING_PRIORITY=low
```

## Testing GPU Sharing

Run this test script to verify GPU sharing is working:

```bash
#!/bin/bash
# test-gpu-sharing.sh

echo "Testing GPU Sharing Configuration"
echo "================================="

# Test 1: Check GPU visibility
echo "1. GPU Visibility Test"
nvidia-smi -L

# Test 2: Check Ollama GPU access
echo "2. Ollama GPU Access"
docker exec ollama nvidia-smi --query-gpu=name,memory.total --format=csv

# Test 3: Check Immich GPU access  
echo "3. Immich GPU Access"
docker exec immich-machine-learning nvidia-smi --query-gpu=name,memory.total --format=csv 2>/dev/null || echo "Immich not running"

# Test 4: Memory allocation
echo "4. Current VRAM Usage"
nvidia-smi --query-gpu=memory.used,memory.total --format=csv

# Test 5: Running processes
echo "5. GPU Processes"
nvidia-smi pmon -c 1

echo "Test complete!"
```

## Conclusion

With proper configuration, the Tesla P40 can effectively serve Ollama for LLM inference while sharing compute resources with Immich for photo AI processing. The lack of NVENC means Plex cannot use this GPU for transcoding, but the 24GB VRAM makes it excellent for large language models.

Remember to monitor temperature closely due to the P40's passive cooling design!
