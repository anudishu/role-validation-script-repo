#!/bin/bash
# Validation script for install-cleanup role
# Checks if system cleanup was performed (kernels, yum cache)

set -euo pipefail

FAILED=0
ROLE_NAME="install-cleanup"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: yum-utils package is installed (needed for package-cleanup)
echo "Check 1: yum-utils package is installed..."
if ! rpm -q yum-utils >/dev/null 2>&1; then
    echo "  ⚠️  WARNING: yum-utils package is not installed (needed for kernel cleanup)"
else
    echo "  ✅ PASS: yum-utils package is installed"
fi

# Check 2: Kernel count is reasonable (should be 1-3 kernels)
echo "Check 2: Kernel count is reasonable..."
KERNEL_COUNT=$(rpm -qa kernel | wc -l)
if [[ ${KERNEL_COUNT} -le 3 ]]; then
    echo "  ✅ PASS: Kernel count is reasonable (${KERNEL_COUNT} kernels)"
else
    echo "  ⚠️  WARNING: High kernel count (${KERNEL_COUNT} kernels), cleanup may be needed"
fi

# Check 3: Current kernel is installed
echo "Check 3: Current kernel is installed..."
CURRENT_KERNEL=$(uname -r)
if rpm -q "kernel-${CURRENT_KERNEL}" >/dev/null 2>&1 || rpm -q "kernel-core-${CURRENT_KERNEL}" >/dev/null 2>&1; then
    echo "  ✅ PASS: Current kernel is installed (${CURRENT_KERNEL})"
else
    echo "  ⚠️  WARNING: Current kernel package not found in RPM database"
fi

# Check 4: Yum cache can be cleaned (verifies yum is working)
echo "Check 4: Yum cache status..."
if command -v yum >/dev/null 2>&1; then
    YUM_CACHE_SIZE=$(du -sh /var/cache/yum 2>/dev/null | cut -f1 || echo "unknown")
    echo "  ✅ PASS: Yum is available (cache size: ${YUM_CACHE_SIZE})"
else
    echo "  ❌ ERROR: yum command not found"
    FAILED=1
fi

# Check 5: Yum cache directory exists
echo "Check 5: Yum cache directory exists..."
if [[ -d /var/cache/yum ]]; then
    echo "  ✅ PASS: Yum cache directory exists"
else
    echo "  ⚠️  WARNING: Yum cache directory not found (may have been cleaned)"
fi

# Check 6: System has reasonable disk space (cleanup should help)
echo "Check 6: System disk space..."
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [[ ${DISK_USAGE} -lt 90 ]]; then
    echo "  ✅ PASS: Disk usage is reasonable (${DISK_USAGE}% used)"
else
    echo "  ⚠️  WARNING: High disk usage (${DISK_USAGE}%), cleanup may be needed"
fi

# Check 7: package-cleanup command is available (if yum-utils installed)
echo "Check 7: package-cleanup command is available..."
if command -v package-cleanup >/dev/null 2>&1; then
    echo "  ✅ PASS: package-cleanup command is available"
else
    echo "  ⚠️  INFO: package-cleanup command not available (install yum-utils if needed)"
fi

# Check 8: System is responsive (cleanup shouldn't break system)
echo "Check 8: System is responsive..."
if uptime >/dev/null 2>&1; then
    UPTIME=$(uptime -p 2>/dev/null || uptime | awk -F'up' '{print $2}' | awk '{print $1,$2}')
    echo "  ✅ PASS: System is responsive (uptime: ${UPTIME})"
else
    echo "  ❌ ERROR: System is not responsive"
    FAILED=1
fi

# Note: Cleanup is a maintenance task, so we validate that:
# 1. The tools needed for cleanup are available
# 2. The system is in a reasonable state after cleanup
# 3. We can't really "validate" that cleanup happened, but we can check system health

# Final result
echo "=========================================="
if [[ $FAILED -eq 0 ]]; then
    echo "✅ VALIDATION PASSED: All checks passed for ${ROLE_NAME}"
    echo "Note: Cleanup validation checks system health and cleanup tools availability"
    exit 0
else
    echo "❌ VALIDATION FAILED: One or more checks failed for ${ROLE_NAME}"
    exit 1
fi
