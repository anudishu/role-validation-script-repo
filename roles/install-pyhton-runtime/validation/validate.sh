#!/bin/bash
# Validation script for install-pyhton-runtime role
# Checks if Python runtime is properly installed and working

set -euo pipefail

FAILED=0
ROLE_NAME="install-pyhton-runtime"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: Python 3 is installed
echo "Check 1: Python 3 is installed..."
if ! command -v python3 >/dev/null 2>&1; then
    echo "  ❌ ERROR: python3 command not found"
    FAILED=1
else
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo "  ✅ PASS: Python 3 is installed (${PYTHON_VERSION})"
fi

# Check 2: pip is available
echo "Check 2: pip is available..."
if ! command -v pip3 >/dev/null 2>&1 && ! python3 -m pip --version >/dev/null 2>&1; then
    echo "  ❌ ERROR: pip3 not found"
    FAILED=1
else
    if command -v pip3 >/dev/null 2>&1; then
        PIP_VERSION=$(pip3 --version 2>&1 | head -1)
        echo "  ✅ PASS: pip3 is available (${PIP_VERSION})"
    else
        PIP_VERSION=$(python3 -m pip --version 2>&1 | head -1)
        echo "  ✅ PASS: pip is available via python3 -m pip (${PIP_VERSION})"
    fi
fi

# Check 3: Python can execute code
echo "Check 3: Python can execute code..."
if ! python3 -c "import sys; print(f'Python {sys.version}')" >/dev/null 2>&1; then
    echo "  ❌ ERROR: Python cannot execute code"
    FAILED=1
else
    PYTHON_INFO=$(python3 -c "import sys; print(f'Python {sys.version.split()[0]}')" 2>&1)
    echo "  ✅ PASS: Python can execute code (${PYTHON_INFO})"
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
