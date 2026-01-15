#!/bin/bash
# Validation script for install-Home role
# Checks if home base directory is properly configured

set -euo pipefail

FAILED=0
ROLE_NAME="install-Home"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: Home base directory exists
echo "Check 1: Home base directory exists..."
if [[ ! -d /home ]]; then
    echo "  ❌ ERROR: /home directory not found"
    FAILED=1
else
    echo "  ✅ PASS: /home directory exists"
fi

# Check 2: Home directory permissions
echo "Check 2: Home directory permissions..."
if [[ -d /home ]]; then
    PERMS=$(stat -c "%a" /home 2>/dev/null || stat -f "%OLp" /home 2>/dev/null || echo "unknown")
    if [[ "$PERMS" == "755" ]] || [[ "$PERMS" == "0755" ]]; then
        echo "  ✅ PASS: /home has correct permissions (755)"
    else
        echo "  ⚠️  WARN: /home permissions are ${PERMS} (expected 755)"
    fi
fi

# Check 3: Home directory ownership
echo "Check 3: Home directory ownership..."
if [[ -d /home ]]; then
    OWNER=$(stat -c "%U" /home 2>/dev/null || stat -f "%Su" /home 2>/dev/null || echo "unknown")
    if [[ "$OWNER" == "root" ]]; then
        echo "  ✅ PASS: /home is owned by root"
    else
        echo "  ⚠️  WARN: /home is owned by ${OWNER} (expected root)"
    fi
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
