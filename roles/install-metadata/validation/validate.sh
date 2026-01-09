#!/bin/bash
# Validation script for install-metadata role
# Checks if GCE metadata is accessible and readable

set -euo pipefail

FAILED=0
ROLE_NAME="install-metadata"

echo "=========================================="
echo "Validating: ${ROLE_NAME}"
echo "=========================================="

# Check 1: Metadata server is accessible
echo "Check 1: GCE metadata server is accessible..."
if ! curl -s -f -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/instance/zone >/dev/null 2>&1; then
    echo "  ❌ ERROR: Cannot access GCE metadata server"
    echo "  Note: This check may fail if not running on GCP VM"
    FAILED=1
else
    echo "  ✅ PASS: GCE metadata server is accessible"
fi

# Check 2: Project ID metadata is readable
echo "Check 2: Project ID metadata is readable..."
PROJECT_ID=$(curl -s -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/project/project-id 2>/dev/null || echo "")

if [[ -z "${PROJECT_ID}" ]]; then
    echo "  ❌ ERROR: Cannot read project-id from metadata"
    FAILED=1
else
    echo "  ✅ PASS: Project ID metadata readable (${PROJECT_ID})"
fi

# Check 3: Instance metadata is readable
echo "Check 3: Instance metadata is readable..."
INSTANCE_NAME=$(curl -s -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/instance/name 2>/dev/null || echo "")

if [[ -z "${INSTANCE_NAME}" ]]; then
    echo "  ❌ ERROR: Cannot read instance name from metadata"
    FAILED=1
else
    echo "  ✅ PASS: Instance name metadata readable (${INSTANCE_NAME})"
fi

# Check 4: Zone metadata is readable
echo "Check 4: Zone metadata is readable..."
ZONE=$(curl -s -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/instance/zone 2>/dev/null || echo "")

if [[ -z "${ZONE}" ]]; then
    echo "  ❌ ERROR: Cannot read zone from metadata"
    FAILED=1
else
    echo "  ✅ PASS: Zone metadata readable (${ZONE})"
fi

# Check 5: STARTUP_BUCKET metadata (if set)
echo "Check 5: STARTUP_BUCKET metadata (optional)..."
STARTUP_BUCKET=$(curl -s -H "Metadata-Flavor: Google" \
    http://metadata.google.internal/computeMetadata/v1/instance/attributes/STARTUP_BUCKET 2>/dev/null || echo "")

if [[ -n "${STARTUP_BUCKET}" ]]; then
    echo "  ✅ PASS: STARTUP_BUCKET metadata found (${STARTUP_BUCKET})"
else
    echo "  ⚠️  INFO: STARTUP_BUCKET metadata not set (this is optional)"
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
