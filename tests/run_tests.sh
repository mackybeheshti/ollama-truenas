#!/bin/bash

# Ollama TrueNAS Test Suite
# This script runs all tests to verify the installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Configuration
OLLAMA_HOST="${OLLAMA_HOST:-localhost}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
WEB_UI_PORT="${WEB_UI_PORT:-8080}"
GRAFANA_PORT="${GRAFANA_PORT:-3000}"
TEST_MODEL="${TEST_MODEL:-llama3.2:3b}"

echo "========================================="
echo "Ollama TrueNAS Test Suite"
echo "========================================="
echo "Host: $OLLAMA_HOST:$OLLAMA_PORT"
echo "Date: $(date)"
echo ""

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -n "Testing $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to run optional test
run_optional_test() {
    local test_name=$1
    local test_command=$2
    
    echo -n "Testing $test_name (optional)... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${YELLOW}⊗ SKIPPED${NC}"
        ((TESTS_SKIPPED++))
        return 0
    fi
}

echo "=== System Requirements ==="

# Test 1: Check if Docker is installed
run_test "Docker installed" "docker --version"

# Test 2: Check if NVIDIA driver is installed
run_test "NVIDIA driver installed" "nvidia-smi"

# Test 3: Check if NVIDIA Container Runtime is installed
run_test "NVIDIA Container Runtime" "docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi"

# Test 4: Check if curl is installed
run_test "curl installed" "which curl"

# Test 5: Check if jq is installed (for JSON parsing)
run_optional_test "jq installed" "which jq"

echo ""
echo "=== Container Status ==="

# Test 6: Check if Ollama container is running
run_test "Ollama container running" "docker ps | grep -E 'ollama|ix-ollama-ollama'"

# Test 7: Check if Web UI container is running (optional)
run_optional_test "Web UI container running" "docker ps | grep -E 'webui|open-webui'"

# Test 8: Check if GPU exporter is running (optional)
run_optional_test "GPU exporter running" "docker ps | grep -E 'gpu-exporter|dcgm'"

echo ""
echo "=== Network Connectivity ==="

# Test 9: Check if Ollama port is open
run_test "Ollama port $OLLAMA_PORT open" "nc -zv $OLLAMA_HOST $OLLAMA_PORT"

# Test 10: Check if Web UI port is open
run_optional_test "Web UI port $WEB_UI_PORT open" "nc -zv $OLLAMA_HOST $WEB_UI_PORT"

# Test 11: Check if Grafana port is open
run_optional_test "Grafana port $GRAFANA_PORT open" "nc -zv $OLLAMA_HOST $GRAFANA_PORT"

echo ""
echo "=== API Tests ==="

# Test 12: Check Ollama API health
run_test "Ollama API responding" "curl -f http://$OLLAMA_HOST:$OLLAMA_PORT/"

# Test 13: Check Ollama API version
run_test "Ollama API version" "curl -f http://$OLLAMA_HOST:$OLLAMA_PORT/api/version"

# Test 14: List models
run_test "List models API" "curl -f http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags"

echo ""
echo "=== GPU Tests ==="

# Test 15: Check GPU visibility in container
if docker ps | grep -E 'ollama|ix-ollama-ollama' > /dev/null; then
    CONTAINER_NAME=$(docker ps --format "{{.Names}}" | grep -E 'ollama|ix-ollama-ollama' | head -1)
    run_test "GPU visible in container" "docker exec $CONTAINER_NAME nvidia-smi"
    
    # Test 16: Check GPU memory
    run_test "GPU memory available" "docker exec $CONTAINER_NAME nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits | awk '{if(\$1 > 1000) exit 0; else exit 1}'"
else
    echo -e "${YELLOW}⊗ Container tests skipped (container not running)${NC}"
    ((TESTS_SKIPPED+=2))
fi

echo ""
echo "=== Storage Tests ==="

# Test 17: Check if model directory exists and is writable
if [ -n "$MODELS_PATH" ]; then
    run_test "Models directory exists" "test -d $MODELS_PATH"
    run_test "Models directory writable" "test -w $MODELS_PATH"
else
    echo -e "${YELLOW}⊗ Storage tests skipped (MODELS_PATH not set)${NC}"
    ((TESTS_SKIPPED+=2))
fi

echo ""
echo "=== Model Tests ==="

# Test 19: Check if test model is available
echo -n "Checking for test model ($TEST_MODEL)... "
if curl -s http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags | grep -q "$TEST_MODEL"; then
    echo -e "${GREEN}✓ FOUND${NC}"
    ((TESTS_PASSED++))
    
    # Test 20: Run inference test
    echo -n "Testing model inference... "
    RESPONSE=$(curl -s -X POST http://$OLLAMA_HOST:$OLLAMA_PORT/api/generate \
        -d "{\"model\": \"$TEST_MODEL\", \"prompt\": \"Say 'test successful' and nothing else.\", \"stream\": false}" \
        2>/dev/null)
    
    if echo "$RESPONSE" | grep -q "successful"; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
    fi
else
    echo -e "${YELLOW}⊗ NOT FOUND${NC}"
    echo "  To download test model, run:"
    echo "  curl -X POST http://$OLLAMA_HOST:$OLLAMA_PORT/api/pull -d '{\"name\":\"$TEST_MODEL\"}'"
    ((TESTS_SKIPPED+=2))
fi

echo ""
echo "=== Performance Tests ==="

# Test 21: Check GPU utilization during inference
if curl -s http://$OLLAMA_HOST:$OLLAMA_PORT/api/tags | grep -q "$TEST_MODEL"; then
    echo -n "Testing GPU utilization... "
    
    # Start inference in background
    curl -s -X POST http://$OLLAMA_HOST:$OLLAMA_PORT/api/generate \
        -d "{\"model\": \"$TEST_MODEL\", \"prompt\": \"Write a long story about space exploration.\", \"stream\": false}" \
        > /dev/null 2>&1 &
    
    CURL_PID=$!
    sleep 2
    
    # Check GPU utilization
    if [ -n "$CONTAINER_NAME" ]; then
        GPU_UTIL=$(docker exec $CONTAINER_NAME nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
        
        if [ "$GPU_UTIL" -gt 0 ]; then
            echo -e "${GREEN}✓ GPU ACTIVE ($GPU_UTIL%)${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${YELLOW}⊗ GPU IDLE${NC}"
            ((TESTS_SKIPPED++))
        fi
    fi
    
    # Clean up background process
    kill $CURL_PID 2>/dev/null || true
    wait $CURL_PID 2>/dev/null || true
else
    echo -e "${YELLOW}⊗ Performance tests skipped (no model)${NC}"
    ((TESTS_SKIPPED++))
fi

echo ""
echo "========================================="
echo "Test Results Summary"
echo "========================================="
echo -e "Passed:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:  ${RED}$TESTS_FAILED${NC}"
echo -e "Skipped: ${YELLOW}$TESTS_SKIPPED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please check the configuration.${NC}"
    exit 1
fi
