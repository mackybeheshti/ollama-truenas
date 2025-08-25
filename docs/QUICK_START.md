# Quick Start Guide - Ollama TrueNAS

## 🚀 5-Minute Setup

### Prerequisites
- TrueNAS Scale 24.04+ (Dragonfish or newer)
- Any NVIDIA GPU (RTX 3060 or better recommended)
- 32GB+ storage for models
- 16GB+ RAM

### Step 1: Install the App

#### Via TrueNAS Web UI:
1. Go to **Apps** → **Available Applications**
2. Click **Discover Apps** → Search "Ollama"
3. Click **Install**

#### Via Command Line:
```bash
cd /mnt/your-pool/
git clone https://github.com/yourusername/ollama-truenas.git
cd ollama-truenas
sudo ./setup.sh
```

### Step 2: Configure (TrueNAS GUI)

**Essential Settings:**
| Setting | Recommended Value | Notes |
|---------|------------------|-------|
| **GPU Device** | `0` | First GPU (use `nvidia-smi -L` to check) |
| **API Port** | `11434` | Default Ollama port |
| **Web UI Port** | `8080` | Open WebUI interface |
| **Enable GPU** | `☑️ Yes` | Required for acceleration |
| **Models Path** | `/mnt/pool/ollama-models` | Your storage pool |
| **Config Path** | `/mnt/pool/ollama-config` | Configuration storage |

**GPU-Specific Settings:**

For **RTX 3060/3070** (12GB VRAM):
- VRAM Limit: `10` GB
- Max Loaded Models: `2`

For **RTX 3090/4090** (24GB VRAM):
- VRAM Limit: `20` GB  
- Max Loaded Models: `3`

For **RTX 4070/4080** (12-16GB VRAM):
- VRAM Limit: `14` GB
- Max Loaded Models: `2`

### Step 3: Start the App

1. Click **Save** in TrueNAS
2. Wait for container to start (1-2 minutes)
3. Check status in Apps → Installed Applications

### Step 4: Verify Installation

```bash
# Check if GPU is detected
docker exec ix-ollama-ollama nvidia-smi

# Test Ollama API
curl http://your-nas-ip:11434/api/tags

# Should return: {"models":[]}
```

### Step 5: Download Your First Model

#### Option A: Via Terminal
```bash
# Small, fast model (3.8GB) - Good for testing
curl -X POST http://your-nas-ip:11434/api/pull \
  -d '{"name":"llama3.2:3b"}'

# Medium model (4.1GB) - Balanced
curl -X POST http://your-nas-ip:11434/api/pull \
  -d '{"name":"mistral:7b"}'
```

#### Option B: Via Web UI
1. Open http://your-nas-ip:8080
2. Go to Settings → Models
3. Type model name: `llama3.2:3b`
4. Click Download

### Step 6: Test Your First Query

```bash
# Via API
curl -X POST http://your-nas-ip:11434/api/generate \
  -d '{
    "model": "llama3.2:3b",
    "prompt": "Why is the sky blue?",
    "stream": false
  }'
```

Or open Web UI: http://your-nas-ip:8080 and start chatting!

## 📊 Monitoring (Optional)

### Access Dashboards
- **Grafana**: http://your-nas-ip:3000 (admin/admin)
- **Prometheus**: http://your-nas-ip:9090

### Check GPU Usage
```bash
# Real-time GPU monitoring
watch -n 1 'docker exec ix-ollama-ollama nvidia-smi'
```

## 🎯 Model Recommendations by GPU

### 8GB VRAM (RTX 3060 Ti, 3070, 4060)
```bash
# Best models for 8GB
ollama pull llama3.2:3b      # Fast, efficient
ollama pull phi3:mini         # Tiny but capable
ollama pull mistral:7b-q4_0   # Quantized 7B model
```

### 12GB VRAM (RTX 3060, 4070)
```bash
# Best models for 12GB
ollama pull llama3.2:3b       # Keep loaded
ollama pull mistral:7b        # Full quality
ollama pull codellama:7b      # For coding
```

### 16GB VRAM (RTX 4080, 4070 Ti)
```bash
# Best models for 16GB
ollama pull llama3.1:8b       # Latest Llama
ollama pull mixtral:8x7b-q4_0 # Quantized mixture
ollama pull qwen2.5:14b       # Powerful model
```

### 24GB VRAM (RTX 3090, 4090, Tesla P40)
```bash
# Best models for 24GB
ollama pull llama3.1:70b-q4_0  # Large quantized
ollama pull mixtral:8x7b       # Full mixture model
ollama pull qwen2.5:32b        # Very capable
```

## 🔧 Common Issues & Fixes

### GPU Not Detected
```bash
# Check NVIDIA driver
nvidia-smi

# Restart container
docker restart ix-ollama-ollama

# Check container logs
docker logs ix-ollama-ollama
```

### Out of Memory (OOM)
```bash
# Unload all models
curl -X POST http://your-nas-ip:11434/api/generate \
  -d '{"model": "llama3.2:3b", "keep_alive": 0}'

# Reduce VRAM limit in TrueNAS GUI
# Apps → Ollama → Edit → GPU Configuration → VRAM Limit
```

### Slow Performance
```bash
# Check if model is using GPU
docker exec ix-ollama-ollama nvidia-smi

# Should show ollama process using GPU
# If not, restart the container
```

### Cannot Access Web UI
```bash
# Check if port is open
netstat -an | grep 8080

# Check container status
docker ps | grep webui

# Restart Web UI
docker restart ix-ollama-webui
```

## 🎮 Quick Commands Cheat Sheet

```bash
# List models
curl http://your-nas-ip:11434/api/tags

# Pull a model
curl -X POST http://your-nas-ip:11434/api/pull -d '{"name":"MODEL_NAME"}'

# Delete a model
curl -X DELETE http://your-nas-ip:11434/api/delete -d '{"name":"MODEL_NAME"}'

# Check GPU usage
docker exec ix-ollama-ollama nvidia-smi

# View logs
docker logs -f ix-ollama-ollama

# Restart everything
docker restart ix-ollama-ollama ix-ollama-webui
```

## 🌐 API Integration Examples

### Python
```python
import requests

response = requests.post('http://your-nas-ip:11434/api/generate',
    json={
        "model": "llama3.2:3b",
        "prompt": "Hello, how are you?",
        "stream": False
    })
print(response.json()['response'])
```

### JavaScript
```javascript
const response = await fetch('http://your-nas-ip:11434/api/generate', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
        model: 'llama3.2:3b',
        prompt: 'Hello, how are you?',
        stream: false
    })
});
const data = await response.json();
console.log(data.response);
```

### curl
```bash
curl -X POST http://your-nas-ip:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:3b", "prompt": "Hello!", "stream": false}'
```

## 📚 Next Steps

1. **Explore Models**: Try different models from [ollama.ai/library](https://ollama.ai/library)
2. **Set Up Monitoring**: Enable Grafana for GPU metrics
3. **Configure GPU Sharing**: See [GPU_SHARING.md](GPU_SHARING.md)
4. **Optimize Models**: See [MODEL_MANAGEMENT.md](MODEL_MANAGEMENT.md)
5. **Join Community**: [GitHub Discussions](https://github.com/yourusername/ollama-truenas/discussions)

## 🆘 Getting Help

- **Logs**: `docker logs ix-ollama-ollama`
- **GPU Issues**: Check [GPU_SHARING.md](GPU_SHARING.md)
- **Model Issues**: Check [MODEL_MANAGEMENT.md](MODEL_MANAGEMENT.md)
- **GitHub Issues**: [Report bugs](https://github.com/yourusername/ollama-truenas/issues)

---

**Ready to go!** Your Ollama server is now running on TrueNAS with GPU acceleration. Start with a small model like `llama3.2:3b` to test everything is working.
