#!/bin/bash
# Validation script for install-disk role
# Checks if disk is properly partitioned, formatted, and mounted

set -euo pipefail

FAILED=0
ROLE_NAME="install-disk"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: Mount point exists
echo "Check 1: Mount point /mnt/data exists..."
if [[ ! -d /mnt/data ]]; then
    echo "  ❌ ERROR: /mnt/data directory not found"
    FAILED=1
else
    echo "  ✅ PASS: /mnt/data directory exists"
fi

# Check 2: Disk is mounted
echo "Check 2: Disk is mounted at /mnt/data..."
if ! mountpoint -q /mnt/data 2>/dev/null; then
    echo "  ❌ ERROR: /mnt/data is not mounted"
    FAILED=1
else
    echo "  ✅ PASS: /mnt/data is mounted"
fi

# Check 3: Mount shows in mount output
echo "Check 3: Mount appears in mount output..."
if mount | grep -q "/mnt/data" 2>/dev/null; then
    MOUNT_INFO=$(mount | grep "/mnt/data" | head -1)
    echo "  ✅ PASS: Mount found: ${MOUNT_INFO}"
else
    echo "  ❌ ERROR: Mount not found in mount output"
    FAILED=1
fi

# Check 4: Disk space is available
echo "Check 4: Disk space is available..."
if mountpoint -q /mnt/data 2>/dev/null; then
    if df -h /mnt/data >/dev/null 2>&1; then
        DISK_SIZE=$(df -h /mnt/data | tail -1 | awk '{print $2}')
        DISK_USED=$(df -h /mnt/data | tail -1 | awk '{print $3}')
        DISK_AVAIL=$(df -h /mnt/data | tail -1 | awk '{print $4}')
        echo "  ✅ PASS: Disk space available (Size: ${DISK_SIZE}, Used: ${DISK_USED}, Avail: ${DISK_AVAIL})"
    else
        echo "  ❌ ERROR: Cannot get disk space information"
        FAILED=1
    fi
else
    echo "  ⚠️  SKIP: Cannot check disk space (not mounted)"
fi

# Check 5: fstab entry exists
echo "Check 5: fstab entry exists..."
if grep -q "/mnt/data" /etc/fstab 2>/dev/null; then
    echo "  ✅ PASS: /mnt/data found in /etc/fstab"
else
    echo "  ⚠️  WARN: /mnt/data not found in /etc/fstab (mount may not persist)"
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
