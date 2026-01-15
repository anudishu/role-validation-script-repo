#!/bin/bash
# Validation script for install-home-dir role
# Checks if user home directories are properly created

set -euo pipefail

FAILED=0
ROLE_NAME="install-home-dir"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: user1 home directory exists
echo "Check 1: User 'user1' home directory exists..."
if [[ ! -d /home/user1 ]]; then
    echo "  ❌ ERROR: /home/user1 directory not found"
    FAILED=1
else
    echo "  ✅ PASS: /home/user1 directory exists"
fi

# Check 2: user2 home directory exists
echo "Check 2: User 'user2' home directory exists..."
if [[ ! -d /home/user2 ]]; then
    echo "  ❌ ERROR: /home/user2 directory not found"
    FAILED=1
else
    echo "  ✅ PASS: /home/user2 directory exists"
fi

# Check 3: user1 home directory ownership
echo "Check 3: User 'user1' home directory ownership..."
if [[ -d /home/user1 ]]; then
    OWNER=$(stat -c "%U" /home/user1 2>/dev/null || stat -f "%Su" /home/user1 2>/dev/null || echo "unknown")
    if [[ "$OWNER" == "user1" ]]; then
        echo "  ✅ PASS: /home/user1 is owned by user1"
    else
        echo "  ❌ ERROR: /home/user1 is owned by ${OWNER} (expected user1)"
        FAILED=1
    fi
fi

# Check 4: user2 home directory ownership
echo "Check 4: User 'user2' home directory ownership..."
if [[ -d /home/user2 ]]; then
    OWNER=$(stat -c "%U" /home/user2 2>/dev/null || stat -f "%Su" /home/user2 2>/dev/null || echo "unknown")
    if [[ "$OWNER" == "user2" ]]; then
        echo "  ✅ PASS: /home/user2 is owned by user2"
    else
        echo "  ❌ ERROR: /home/user2 is owned by ${OWNER} (expected user2)"
        FAILED=1
    fi
fi

# Check 5: user1 exists
echo "Check 5: User 'user1' exists..."
if ! id user1 >/dev/null 2>&1; then
    echo "  ❌ ERROR: User 'user1' not found"
    FAILED=1
else
    echo "  ✅ PASS: User 'user1' exists"
fi

# Check 6: user2 exists
echo "Check 6: User 'user2' exists..."
if ! id user2 >/dev/null 2>&1; then
    echo "  ❌ ERROR: User 'user2' not found"
    FAILED=1
else
    echo "  ✅ PASS: User 'user2' exists"
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
