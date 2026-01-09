#!/bin/bash
# Validation script for install-kubectl role
# Checks if kubectl is installed and working

set -euo pipefail

FAILED=0
ROLE_NAME="install-kubectl"
KUBECTL_PATH="${KUBECTL_PATH:-/usr/bin/kubectl}"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: kubectl binary exists
echo "Check 1: kubectl binary exists at ${KUBECTL_PATH}..."
if [[ ! -f "${KUBECTL_PATH}" ]]; then
    echo "  ❌ ERROR: kubectl not found at ${KUBECTL_PATH}"
    FAILED=1
else
    echo "  ✅ PASS: kubectl exists at ${KUBECTL_PATH}"
fi

# Check 2: kubectl is executable
echo "Check 2: kubectl is executable..."
if [[ ! -x "${KUBECTL_PATH}" ]]; then
    echo "  ❌ ERROR: kubectl is not executable"
    FAILED=1
else
    echo "  ✅ PASS: kubectl is executable"
fi

# Check 3: kubectl version command works
echo "Check 3: kubectl version command works..."
if ! "${KUBECTL_PATH}" version --client >/dev/null 2>&1; then
    echo "  ❌ ERROR: kubectl version command failed"
    FAILED=1
else
    KUBECTL_VERSION=$("${KUBECTL_PATH}" version --client --output=yaml 2>/dev/null | grep -E "^(major|minor|gitVersion)" | head -1 || echo "unknown")
    echo "  ✅ PASS: kubectl version command works (${KUBECTL_VERSION})"
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
