#!/bin/bash
# Validation script for install-ops-agent-logging role
# Checks if Google Cloud Ops Agent is installed and configured correctly

set -euo pipefail

FAILED=0
ROLE_NAME="install-ops-agent-logging"
OPS_AGENT_CONFIG_PATH="${OPS_AGENT_CONFIG_PATH:-/etc/google-cloud-ops-agent/config.yaml}"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: Ops Agent package is installed
echo "Check 1: Google Cloud Ops Agent package is installed..."
if ! rpm -q google-cloud-ops-agent >/dev/null 2>&1; then
    echo "  ❌ ERROR: google-cloud-ops-agent package is not installed"
    FAILED=1
else
    OPS_AGENT_VER=$(rpm -q google-cloud-ops-agent)
    echo "  ✅ PASS: Ops Agent package is installed (${OPS_AGENT_VER})"
fi

# Check 2: Ops Agent service is running (CRITICAL CHECK)
echo "Check 2: Ops Agent service is running..."
if systemctl is-active --quiet google-cloud-ops-agent; then
    echo "  ✅ PASS: Ops Agent service is running"
else
    echo "  ❌ ERROR: Ops Agent service is not running"
    FAILED=1
fi

# Check 3: Ops Agent config file exists (CRITICAL CHECK)
echo "Check 3: Ops Agent config file exists..."
if [[ -f "${OPS_AGENT_CONFIG_PATH}" ]]; then
    echo "  ✅ PASS: Ops Agent config file exists"
else
    echo "  ❌ ERROR: Ops Agent config file not found"
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
