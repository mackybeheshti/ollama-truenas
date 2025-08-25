#!/bin/bash

# Ollama Model Benchmark Script
# Tests performance of different models on your GPU

set -e

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-localhost}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OUTPUT_FILE="benchmark_results_$(date +%Y%m%d_%H%M%S).txt"

# Test prompts
SHORT_PROMPT="What is 2+2?"
MEDIUM_PROMPT="Explain quantum computing in simple terms."
LONG_PROMPT="Write a detailed 500-word essay about the impact of artificial intelligence on modern society, covering both positive and negative aspects."

echo "========================================="
echo "Ollama Model Benchmark"
echo "========================================="
echo "Host: $OLLAMA_HOST:$OLLAMA_PORT"
echo "Date: $(date)"
echo "Results will be saved to: $OUTPUT_FILE"
echo ""

# Function to test model
benchmark_model() {
    local model=$1
    local prompt=$2
    local prompt_type=$3
    
    echo "  Testing $prompt_type prompt..."
    
    # Record start time
    start_time=$(date +%s.%N)
    
    # Run inference
    response=$(curl -s -X POST http://$OLLAMA_HOST:$OLLAMA_PORT/api/generate \
        -d "{\"model\": \"$model\", \"prompt\": \"$prompt\", \"stream\": false}" \
        2>/dev/null)
    
    # Record end time
    end_time=$(date +%s.%N)
    
    # Calculate duration
    duration=$(echo "$end_time - $start_time" | bc)
    
    # Extract token counts if available
    if command -v jq &> /dev/null; then
        total_duration=$(echo "$response" | jq -r '.total_duration // 0' | awk '{print $1/1000000000}')
        load_duration=$(echo "$response" | jq -r '.load_duration // 0' | awk '{print $1/1000000000}')
        eval_count=$(echo "$response" | jq -r '.eval_count // 0')
        eval_duration=$(echo "$response" | jq -r '.eval_duration // 0' | awk '{print $1/1000000000}')
        
        if [ "$eval_count" -gt 0 ] && [ "$eval_duration" != "0" ]; then
            tokens_per_sec=$(echo "scale=2; $eval_count / $eval_duration" | bc)
        else
            tokens_per_sec="N/A"
        fi
    else
        total_duration=$duration
        tokens_per_sec="N/A (install jq for detailed stats)"
    fi
    
    echo "    Duration: ${duration}s"
    echo "    Tokens/sec: $tokens_per_sec"
    
    # Save to file
    echo "$model,$prompt_type,$duration,$tokens_per_sec,$eval_count" >> $OUTPUT_FILE
}

# Function to check if model exists
model_exists() {
    local model=$1
    curl -s http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags | grep -q "\"$model\""
}

# Function to get GPU stats
get_gpu_stats() {
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=name,memory.used,memory.total,temperature.gpu,power.draw --format=csv,noheader
    else
        echo "GPU monitoring not available"
    fi
}

# Write header to results file
echo "Model,Prompt Type,Duration (s),Tokens/sec,Token Count" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Get initial GPU stats
echo "=== GPU Status ==="
get_gpu_stats
echo ""

# List available models
echo "=== Available Models ==="
available_models=$(curl -s http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags | jq -r '.models[].name' 2>/dev/null || echo "")

if [ -z "$available_models" ]; then
    echo "No models found. Please download some models first:"
    echo "  curl -X POST http://$OLLAMA_HOST:$OLLAMA_PORT/api/pull -d '{\"name\":\"llama3.2:3b\"}'"
    exit 1
fi

echo "Found models:"
echo "$available_models" | while read -r model; do
    echo "  - $model"
done
echo ""

# Benchmark each model
echo "=== Running Benchmarks ==="
echo "$available_models" | while read -r model; do
    if [ -z "$model" ]; then
        continue
    fi
    
    echo "Benchmarking: $model"
    
    # Pre-load model
    echo "  Loading model..."
    curl -s -X POST http://$OLLAMA_HOST:$OLLAMA_PORT/api/generate \
        -d "{\"model\": \"$model\", \"prompt\": \"test\", \"stream\": false}" \
        > /dev/null 2>&1
    
    # Run benchmarks
    benchmark_model "$model" "$SHORT_PROMPT" "short"
    benchmark_model "$model" "$MEDIUM_PROMPT" "medium"
    benchmark_model "$model" "$LONG_PROMPT" "long"
    
    # Get GPU stats after model
    echo "  GPU Status:"
    gpu_stats=$(get_gpu_stats)
    echo "    $gpu_stats"
    echo ""
    
    # Unload model to free VRAM
    curl -s -X POST http://$OLLAMA_HOST:$OLLAMA_PORT/api/generate \
        -d "{\"model\": \"$model\", \"keep_alive\": 0}" \
        > /dev/null 2>&1
    
    sleep 2
done

echo "=== Benchmark Complete ==="
echo ""
echo "Results saved to: $OUTPUT_FILE"
echo ""
echo "=== Summary ==="

if command -v column &> /dev/null; then
    echo ""
    column -t -s',' $OUTPUT_FILE
else
    cat $OUTPUT_FILE
fi

# Generate recommendations
echo ""
echo "=== Recommendations ==="

# Analyze results
if command -v awk &> /dev/null; then
    fastest_model=$(awk -F',' 'NR>2 && $4 != "N/A" {print $1, $4}' $OUTPUT_FILE | sort -k2 -nr | head -1)
    if [ ! -z "$fastest_model" ]; then
        echo "Fastest model: $fastest_model tokens/sec"
    fi
fi

echo ""
echo "For real-time chat: Use models with >30 tokens/sec"
echo "For quality: Use larger models even if slower"
echo "For coding: Use specialized models like codellama"
echo ""
echo "Benchmark complete!"
