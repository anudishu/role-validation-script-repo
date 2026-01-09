#!/bin/bash
# Validation script for install-selinux-firewalld role
# Checks if SELinux and firewalld are properly configured

set -euo pipefail

FAILED=0
ROLE_NAME="install-selinux-firewalld"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: SELinux config file exists
echo "Check 1: SELinux config file exists..."
if [[ ! -f /etc/selinux/config ]]; then
    echo "  ❌ ERROR: /etc/selinux/config not found"
    FAILED=1
else
    echo "  ✅ PASS: /etc/selinux/config exists"
fi

# Check 2: SELinux is set to permissive
echo "Check 2: SELinux is set to permissive..."
SELINUX_MODE=$(grep "^SELINUX=" /etc/selinux/config 2>/dev/null | cut -d'=' -f2 || echo "")
if [[ "${SELINUX_MODE}" != "permissive" ]]; then
    echo "  ❌ ERROR: SELinux is not set to permissive (current: ${SELINUX_MODE:-not found})"
    FAILED=1
else
    echo "  ✅ PASS: SELinux is set to permissive"
fi

# Check 3: firewalld package is installed
echo "Check 3: firewalld package is installed..."
if ! rpm -q firewalld >/dev/null 2>&1; then
    echo "  ❌ ERROR: firewalld package is not installed"
    FAILED=1
else
    FIREWALLD_VERSION=$(rpm -q firewalld)
    echo "  ✅ PASS: firewalld package is installed (${FIREWALLD_VERSION})"
fi

# Check 4: firewalld service is running (CRITICAL CHECK)
echo "Check 4: firewalld service is running..."
if systemctl is-active --quiet firewalld; then
    echo "  ✅ PASS: firewalld service is running"
else
    echo "  ❌ ERROR: firewalld service is not running"
    FAILED=1
fi

# Check 5: firewalld command exists (CRITICAL CHECK)
echo "Check 5: firewalld command exists..."
if command -v firewall-cmd >/dev/null 2>&1; then
    echo "  ✅ PASS: firewall-cmd command is available"
else
    echo "  ❌ ERROR: firewall-cmd command not found"
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
