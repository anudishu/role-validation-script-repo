#!/bin/bash
# Validation script for install-nfs-mount role
# Checks if NFS is properly installed and mounted

set -euo pipefail

FAILED=0
ROLE_NAME="install-nfs-mount"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: NFS packages are installed
echo "Check 1: NFS packages are installed..."
if ! rpm -q nfs-utils >/dev/null 2>&1; then
    echo "  ❌ ERROR: nfs-utils package not installed"
    FAILED=1
else
    PACKAGE_VERSION=$(rpm -q nfs-utils)
    echo "  ✅ PASS: nfs-utils installed (${PACKAGE_VERSION})"
fi

if ! rpm -q rpcbind >/dev/null 2>&1; then
    echo "  ❌ ERROR: rpcbind package not installed"
    FAILED=1
else
    echo "  ✅ PASS: rpcbind installed"
fi

# Check 2: NFS services are running
echo "Check 2: NFS services are running..."
if systemctl is-active --quiet rpcbind 2>/dev/null; then
    echo "  ✅ PASS: rpcbind service is running"
else
    echo "  ⚠️  WARN: rpcbind service is not running"
fi

if systemctl is-active --quiet nfs-client.target 2>/dev/null; then
    echo "  ✅ PASS: nfs-client.target is active"
else
    echo "  ⚠️  WARN: nfs-client.target is not active"
fi

# Check 3: NFS mount point exists
echo "Check 3: NFS mount point /mnt/nfs-share exists..."
if [[ ! -d /mnt/nfs-share ]]; then
    echo "  ❌ ERROR: /mnt/nfs-share directory not found"
    FAILED=1
else
    echo "  ✅ PASS: /mnt/nfs-share directory exists"
fi

# Check 4: NFS share is mounted
echo "Check 4: NFS share is mounted..."
if ! mountpoint -q /mnt/nfs-share 2>/dev/null; then
    echo "  ❌ ERROR: /mnt/nfs-share is not mounted"
    FAILED=1
else
    echo "  ✅ PASS: /mnt/nfs-share is mounted"
fi

# Check 5: NFS mount appears in mount output
echo "Check 5: NFS mount appears in mount output..."
if mount | grep -q "/mnt/nfs-share" 2>/dev/null; then
    MOUNT_INFO=$(mount | grep "/mnt/nfs-share" | head -1)
    echo "  ✅ PASS: NFS mount found: ${MOUNT_INFO}"
else
    echo "  ❌ ERROR: NFS mount not found in mount output"
    FAILED=1
fi

# Check 6: NFS share is accessible
echo "Check 6: NFS share is accessible..."
if mountpoint -q /mnt/nfs-share 2>/dev/null; then
    if [[ -r /mnt/nfs-share ]] && [[ -w /mnt/nfs-share ]] 2>/dev/null; then
        echo "  ✅ PASS: NFS share is readable and writable"
    else
        echo "  ⚠️  WARN: NFS share may have permission issues"
    fi
else
    echo "  ⚠️  SKIP: Cannot check accessibility (not mounted)"
fi

# Check 7: fstab entry exists
echo "Check 7: fstab entry exists..."
if grep -q "/mnt/nfs-share" /etc/fstab 2>/dev/null; then
    echo "  ✅ PASS: /mnt/nfs-share found in /etc/fstab"
else
    echo "  ⚠️  WARN: /mnt/nfs-share not found in /etc/fstab (mount may not persist)"
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
