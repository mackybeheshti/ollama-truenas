# Ollama - Run Large Language Models Locally

## Overview

Ollama is a powerful platform for running large language models (LLMs) locally on your TrueNAS server with full GPU acceleration support. This app is specifically optimized for NVIDIA GPUs, including the Tesla P40, and provides a complete ecosystem for AI inference.

## Key Features

### 🚀 GPU Acceleration
- **Full NVIDIA Support**: Optimized for Tesla P40, RTX series, and other CUDA-capable GPUs
- **Multi-GPU Support**: Scale across multiple GPUs for larger models
- **Smart VRAM Management**: Automatic model loading/unloading based on usage
- **GPU Sharing**: Compatible with Plex transcoding and Immich photo processing

### 🤖 Model Management
- **Easy Model Downloads**: One-click download from Ollama's model library
- **Multiple Models**: Run multiple models simultaneously (within VRAM limits)
- **Automatic Preloading**: Configure default models to download on first install
- **Model Persistence**: All models stored persistently across updates

### 📊 Monitoring & Management
- **Web UI**: Beautiful interface for model management
- **GPU Metrics**: Real-time GPU utilization, VRAM usage, and temperature
- **Prometheus Integration**: Export metrics for advanced monitoring
- **Grafana Dashboards**: Pre-configured visualizations for all metrics

### 🔌 API & Integration
- **REST API**: Full Ollama API compatibility
- **CORS Support**: Easy integration with web applications
- **Authentication**: Optional API key protection
- **Network Flexibility**: Host networking mode for GPU sharing

## Supported Models

This app supports all Ollama models, including:

- **Llama 3.2** (1B, 3B, 11B, 90B)
- **Qwen 2.5** (0.5B to 72B)
- **Mistral** (7B)
- **Mixtral** (8x7B, 8x22B)
- **Phi-3** (mini, medium)
- **CodeLlama** (7B, 13B, 34B, 70B)
- **Gemma 2** (2B, 9B, 27B)
- **DeepSeek Coder** (1.3B to 33B)
- And many more!

## Tesla P40 Optimization

This app is specially optimized for the NVIDIA Tesla P40:

- **24GB VRAM**: Run large models up to 70B parameters
- **Pascal Architecture**: Full compute capability 6.1 support
- **No NVENC**: Documentation covers P40's lack of video encoding
- **Thermal Management**: Temperature monitoring for passive cooling

### Performance Benchmarks (P40)

| Model | Speed | VRAM | Concurrent |
|-------|-------|------|------------|
| Llama 3.2 3B | 45-50 tok/s | 3.5GB | 6 models |
| Mistral 7B | 30-35 tok/s | 7.5GB | 3 models |
| Llama 2 13B | 18-22 tok/s | 13GB | 1 model |
| Mixtral 8x7B | 8-12 tok/s | 23GB | 1 model |

## Use Cases

### Development
- Code generation and review
- Documentation writing
- Debugging assistance
- API development

### Content Creation
- Blog post writing
- Creative storytelling
- Translation
- Summarization

### Data Analysis
- Text analysis
- Sentiment analysis
- Information extraction
- Report generation

### Education
- Tutoring and explanations
- Question answering
- Language learning
- Research assistance

## Requirements

- **TrueNAS Scale**: Version 25.04 (Dragonfish) or newer
- **GPU**: NVIDIA GPU with CUDA support
- **VRAM**: Minimum 6GB (24GB recommended for large models)
- **RAM**: 16GB minimum (32GB recommended)
- **Storage**: 50GB+ for models
- **Network**: Gigabit Ethernet recommended

## Quick Start

1. Install from TrueNAS Apps catalog
2. Configure GPU device and storage paths
3. Enable desired features (Web UI, monitoring)
4. Access the API at `http://your-nas:11434`
5. Open Web UI at `http://your-nas:8080`

## Support

- **Documentation**: Full guides for setup and optimization
- **GPU Sharing**: Instructions for Plex/Immich compatibility
- **Troubleshooting**: Common issues and solutions
- **Community**: Active support via GitHub

## Privacy & Security

- **100% Local**: All processing happens on your hardware
- **No Internet Required**: Models run completely offline
- **Data Privacy**: Your data never leaves your server
- **API Security**: Optional authentication protection

Start running powerful AI models on your own hardware today!
