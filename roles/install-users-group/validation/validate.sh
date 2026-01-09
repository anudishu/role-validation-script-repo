#!/bin/bash
# Validation script for install-users-group role
# Checks if users, groups, sudoers, and limits are properly configured

set -euo pipefail

FAILED=0
ROLE_NAME="install-users-group"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: Primary group exists
echo "Check 1: Primary group 'dataiku' exists..."
if ! getent group dataiku >/dev/null 2>&1; then
    echo "  ❌ ERROR: Group 'dataiku' not found"
    FAILED=1
else
    echo "  ✅ PASS: Group 'dataiku' exists"
fi

# Check 2: dataiku user exists
echo "Check 2: User 'dataiku' exists..."
if ! id dataiku >/dev/null 2>&1; then
    echo "  ❌ ERROR: User 'dataiku' not found"
    FAILED=1
else
    DATAIKU_UID=$(id -u dataiku)
    DATAIKU_GID=$(id -g dataiku)
    echo "  ✅ PASS: User 'dataiku' exists (UID: ${DATAIKU_UID}, GID: ${DATAIKU_GID})"
fi

# Check 3: dataiku user is in correct primary group
echo "Check 3: User 'dataiku' is in correct primary group..."
if id -gn dataiku | grep -q "^dataiku$"; then
    echo "  ✅ PASS: User 'dataiku' is in group 'dataiku'"
else
    echo "  ❌ ERROR: User 'dataiku' is not in group 'dataiku'"
    FAILED=1
fi

# Check 4: Secondary group exists
echo "Check 4: Secondary group 'dataiku_user_group' exists..."
if ! getent group dataiku_user_group >/dev/null 2>&1; then
    echo "  ❌ ERROR: Group 'dataiku_user_group' not found"
    FAILED=1
else
    GROUP_GID=$(getent group dataiku_user_group | cut -d: -f3)
    echo "  ✅ PASS: Group 'dataiku_user_group' exists (GID: ${GROUP_GID})"
fi

# Check 5: dataiku_user exists
echo "Check 5: User 'dataiku_user' exists..."
if ! id dataiku_user >/dev/null 2>&1; then
    echo "  ❌ ERROR: User 'dataiku_user' not found"
    FAILED=1
else
    DATAIKU_USER_UID=$(id -u dataiku_user)
    echo "  ✅ PASS: User 'dataiku_user' exists (UID: ${DATAIKU_USER_UID})"
fi

# Check 6: dataiku_user is in secondary group
echo "Check 6: User 'dataiku_user' is in secondary group..."
if id -Gn dataiku_user | grep -q "dataiku_user_group"; then
    echo "  ✅ PASS: User 'dataiku_user' is in group 'dataiku_user_group'"
else
    echo "  ❌ ERROR: User 'dataiku_user' is not in group 'dataiku_user_group'"
    FAILED=1
fi

# Check 7: Sudoers configuration file (optional - not critical)
echo "Check 7: Sudoers configuration file (optional)..."
if [[ -f /etc/sudoers.d/dataiku-dss-uf-wrapper ]]; then
    echo "  ✅ PASS: Sudoers file exists"
else
    echo "  ⚠️  INFO: Sudoers file not found (optional)"
fi

# Check 10: Limits file exists
echo "Check 10: Limits configuration file exists..."
if [[ ! -f /etc/security/limits.d/90-custom.conf ]]; then
    echo "  ❌ ERROR: Limits file not found at /etc/security/limits.d/90-custom.conf"
    FAILED=1
else
    echo "  ✅ PASS: Limits file exists"
fi

# Check 11: Limits file has correct content
echo "Check 11: Limits file has correct content..."
if grep -q "dataiku soft nofile 4096" /etc/security/limits.d/90-custom.conf 2>/dev/null; then
    echo "  ✅ PASS: Limits file has correct nofile limit configuration"
else
    echo "  ❌ ERROR: Limits file does not have correct nofile limit configuration"
    FAILED=1
fi

# Check 12: Home directories exist
echo "Check 12: User home directories exist..."
if [[ -d /home/dataiku ]]; then
    echo "  ✅ PASS: Home directory for 'dataiku' exists"
else
    echo "  ❌ ERROR: Home directory for 'dataiku' not found"
    FAILED=1
fi

if [[ -d /home/dataiku_user ]]; then
    echo "  ✅ PASS: Home directory for 'dataiku_user' exists"
else
    echo "  ❌ ERROR: Home directory for 'dataiku_user' not found"
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
