#!/bin/bash
# Validation script for install-os-login role
# Checks if OS Login is properly installed and configured

set -euo pipefail

FAILED=0
ROLE_NAME="install-os-login"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: OS Login package is installed
echo "Check 1: OS Login package is installed..."
if ! rpm -q google-compute-engine-oslogin >/dev/null 2>&1; then
    echo "  ❌ ERROR: google-compute-engine-oslogin package not installed"
    FAILED=1
else
    PACKAGE_VERSION=$(rpm -q google-compute-engine-oslogin)
    echo "  ✅ PASS: OS Login package installed (${PACKAGE_VERSION})"
fi

# Check 2: PAM configuration
echo "Check 2: PAM configuration for OS Login..."
if grep -q "pam_oslogin_login.so" /etc/pam.d/sshd 2>/dev/null; then
    echo "  ✅ PASS: OS Login PAM configuration found in /etc/pam.d/sshd"
else
    echo "  ⚠️  WARN: OS Login PAM configuration not found (may be commented out)"
fi

# Check 3: NSS configuration
echo "Check 3: NSS configuration for OS Login..."
if grep -q "^passwd:.*oslogin" /etc/nsswitch.conf 2>/dev/null; then
    echo "  ✅ PASS: OS Login configured in /etc/nsswitch.conf"
else
    echo "  ⚠️  WARN: OS Login not configured in /etc/nsswitch.conf"
fi

# Check 4: Sudoers configuration
echo "Check 4: Sudoers configuration for OS Login..."
if [[ -f /etc/sudoers.d/google-oslogin ]]; then
    echo "  ✅ PASS: OS Login sudoers file exists"
    if grep -q "google-sudoers" /etc/sudoers.d/google-oslogin 2>/dev/null; then
        echo "  ✅ PASS: google-sudoers group configured"
    else
        echo "  ⚠️  WARN: google-sudoers group not found in sudoers file"
    fi
else
    echo "  ⚠️  WARN: OS Login sudoers file not found"
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
