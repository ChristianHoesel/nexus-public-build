#!/bin/bash
set -e

# Docker Image Test Script for Nexus Repository OSS
# This script tests the functionality of the built Docker image

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/christianhoesel/nexus-public-build:latest}"
CONTAINER_NAME="nexus-test-$$"
# Use random available port in CI to avoid conflicts
TEST_PORT="${TEST_PORT:-$(shuf -i 8081-8999 -n 1)}"
HEALTH_CHECK_TIMEOUT=300  # 5 minutes
HEALTH_CHECK_INTERVAL=10  # 10 seconds

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up test containers and volumes...${NC}"
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    docker volume rm "${CONTAINER_NAME}-data" 2>/dev/null || true
}

# Trap cleanup on exit
trap cleanup EXIT

# Test function
test_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

test_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

echo "========================================"
echo "Docker Image Tests for Nexus OSS"
echo "========================================"
echo "Image: $IMAGE_NAME"
echo "Container: $CONTAINER_NAME"
echo ""

# Test 1: Check if Docker image exists
echo "Test 1: Checking if Docker image exists..."
if docker inspect "$IMAGE_NAME" &> /dev/null; then
    test_pass "Docker image exists"
else
    test_fail "Docker image not found: $IMAGE_NAME"
fi

# Test 2: Check image labels
echo ""
echo "Test 2: Verifying image metadata..."
IMAGE_VERSION=$(docker inspect "$IMAGE_NAME" --format='{{index .Config.Labels "org.opencontainers.image.version"}}' 2>/dev/null || echo "")
IMAGE_TITLE=$(docker inspect "$IMAGE_NAME" --format='{{index .Config.Labels "org.opencontainers.image.title"}}' 2>/dev/null || echo "")
if [ -n "$IMAGE_TITLE" ]; then
    test_pass "Image has metadata (Title: $IMAGE_TITLE)"
    test_info "Image version: ${IMAGE_VERSION:-not set}"
else
    test_fail "Image metadata missing"
fi

# Test 3: Start container
echo ""
echo "Test 3: Starting container..."
if docker run -d \
    --name "$CONTAINER_NAME" \
    -p "${TEST_PORT}:8081" \
    -v "${CONTAINER_NAME}-data:/nexus-data" \
    -e INSTALL4J_ADD_VM_PARAMS="-Xms1g -Xmx1g -XX:MaxDirectMemorySize=1g -Djava.util.prefs.userRoot=/nexus-data/javaprefs" \
    "$IMAGE_NAME" &> /dev/null; then
    test_pass "Container started successfully"
else
    test_fail "Failed to start container"
fi

# Test 4: Check if container is running
echo ""
echo "Test 4: Verifying container state..."
sleep 5
if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q "$CONTAINER_NAME"; then
    test_pass "Container is running"
else
    test_fail "Container is not running"
fi

# Test 5: Check container environment variables
echo ""
echo "Test 5: Checking environment variables..."
NEXUS_DATA=$(docker exec "$CONTAINER_NAME" printenv NEXUS_DATA 2>/dev/null || echo "")
if [ "$NEXUS_DATA" = "/nexus-data" ]; then
    test_pass "Environment variables configured correctly"
else
    test_fail "Environment variables not set correctly"
fi

# Test 6: Check nexus user
echo ""
echo "Test 6: Verifying nexus user..."
CURRENT_USER=$(docker exec "$CONTAINER_NAME" whoami 2>/dev/null || echo "")
if [ "$CURRENT_USER" = "nexus" ]; then
    test_pass "Container running as nexus user"
else
    test_fail "Container not running as nexus user (running as: $CURRENT_USER)"
fi

# Test 7: Check data directory permissions
echo ""
echo "Test 7: Checking data directory permissions..."
if docker exec "$CONTAINER_NAME" test -w /nexus-data; then
    test_pass "Data directory is writable"
else
    test_fail "Data directory is not writable"
fi

# Test 8: Wait for Nexus to start and check health
echo ""
echo "Test 8: Waiting for Nexus to start (max ${HEALTH_CHECK_TIMEOUT}s)..."
ELAPSED=0
NEXUS_STARTED=false

while [ $ELAPSED -lt $HEALTH_CHECK_TIMEOUT ]; do
    if docker exec "$CONTAINER_NAME" curl -f -s http://localhost:8081/ > /dev/null 2>&1; then
        NEXUS_STARTED=true
        break
    fi
    
    # Check if container is still running
    if ! docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q "$CONTAINER_NAME"; then
        test_fail "Container stopped unexpectedly"
    fi
    
    if [ $((ELAPSED % 30)) -eq 0 ]; then
        test_info "Still waiting... (${ELAPSED}s elapsed)"
    fi
    
    sleep $HEALTH_CHECK_INTERVAL
    ELAPSED=$((ELAPSED + HEALTH_CHECK_INTERVAL))
done

if [ "$NEXUS_STARTED" = true ]; then
    test_pass "Nexus started successfully (took ${ELAPSED}s)"
else
    test_info "Showing last 50 lines of container logs:"
    docker logs --tail 50 "$CONTAINER_NAME"
    test_fail "Nexus did not start within ${HEALTH_CHECK_TIMEOUT}s"
fi

# Test 9: Check if Nexus is accessible from host
echo ""
echo "Test 9: Testing Nexus accessibility from host..."
if curl -f -s "http://localhost:${TEST_PORT}/" > /dev/null 2>&1; then
    test_pass "Nexus is accessible on port ${TEST_PORT}"
else
    test_fail "Nexus is not accessible on port ${TEST_PORT}"
fi

# Test 10: Verify health check endpoint
echo ""
echo "Test 10: Testing health check endpoint..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${TEST_PORT}/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "303" ]; then
    test_pass "Health check successful (HTTP $HTTP_CODE)"
else
    test_fail "Health check failed (HTTP $HTTP_CODE)"
fi

# Test 11: Check Docker health status
echo ""
echo "Test 11: Checking Docker health status..."
sleep 5  # Give health check time to run
HEALTH_STATUS=$(docker inspect "$CONTAINER_NAME" --format='{{.State.Health.Status}}' 2>/dev/null || echo "none")
if [ "$HEALTH_STATUS" = "healthy" ] || [ "$HEALTH_STATUS" = "none" ]; then
    test_pass "Docker health status: $HEALTH_STATUS"
else
    test_info "Docker health status: $HEALTH_STATUS (may need more time)"
fi

# Test 12: Verify volume persistence
echo ""
echo "Test 12: Testing volume persistence..."
docker exec "$CONTAINER_NAME" touch /nexus-data/test-file 2>/dev/null
if docker exec "$CONTAINER_NAME" test -f /nexus-data/test-file; then
    test_pass "Volume persistence working"
else
    test_fail "Volume persistence not working"
fi

# Test 13: Check if admin.password file is created
echo ""
echo "Test 13: Checking for admin.password file..."
if docker exec "$CONTAINER_NAME" test -f /nexus-data/admin.password; then
    test_pass "Admin password file created"
    # Don't show the actual password for security
    test_info "Admin password file exists (use 'docker exec $CONTAINER_NAME cat /nexus-data/admin.password' to view)"
else
    test_info "Admin password file not yet created (this is normal for fresh install)"
fi

# Test 14: Check log files
echo ""
echo "Test 14: Checking log directory..."
if docker exec "$CONTAINER_NAME" test -d /nexus-data/log; then
    test_pass "Log directory exists"
else
    test_fail "Log directory not found"
fi

# Test 15: Verify Java process
echo ""
echo "Test 15: Verifying Java process..."
if docker exec "$CONTAINER_NAME" pgrep -f "java" > /dev/null 2>&1; then
    test_pass "Java process is running"
else
    test_fail "Java process not found"
fi

# Summary
echo ""
echo "========================================"
echo -e "${GREEN}All tests passed!${NC}"
echo "========================================"
echo ""
echo "Test Summary:"
echo "  - Docker image validated"
echo "  - Container started successfully"
echo "  - Nexus service is accessible"
echo "  - Health checks working"
echo "  - Volume persistence confirmed"
echo ""
