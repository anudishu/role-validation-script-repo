#!/bin/bash
# Validation script for install-docker-config role
# Checks if Docker wrapper and Docker service are properly installed and working

set -euo pipefail

FAILED=0
ROLE_NAME="install-docker-config"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: Docker wrapper file exists
echo "Check 1: Docker wrapper file exists..."
if [[ ! -f /usr/local/bin/docker-wrapper.py ]]; then
    echo "  ❌ ERROR: docker-wrapper.py not found at /usr/local/bin/docker-wrapper.py"
    FAILED=1
else
    echo "  ✅ PASS: docker-wrapper.py exists"
fi

# Check 2: Docker wrapper is executable
echo "Check 2: Docker wrapper is executable..."
if [[ ! -x /usr/local/bin/docker-wrapper.py ]]; then
    echo "  ❌ ERROR: docker-wrapper.py is not executable"
    FAILED=1
else
    echo "  ✅ PASS: docker-wrapper.py is executable"
fi

# Check 3: Docker service is running (CRITICAL CHECK)
echo "Check 3: Docker service is running..."
if systemctl is-active --quiet docker; then
    echo "  ✅ PASS: Docker service is running"
else
    echo "  ❌ ERROR: Docker service is not running"
    FAILED=1
fi

# Check 4: Docker command works (CRITICAL CHECK)
echo "Check 4: Docker command works..."
if command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version 2>&1)
    echo "  ✅ PASS: Docker command works (${DOCKER_VERSION})"
else
    echo "  ❌ ERROR: Docker command not working"
    FAILED=1
fi

# Final result
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ VALIDATION PASSED: All checks passed for ${ROLE_NAME}"
    exit 0
else
    echo "❌ VALIDATION FAILED: One or more checks failed for ${ROLE_NAME}"
    exit 1
fi
