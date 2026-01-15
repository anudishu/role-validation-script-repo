#!/bin/bash
# Script to copy validation scripts to VM for testing

set -euo pipefail

PROJECT_ID="lyfedge-project"
VM_NAME="rhel9-roles-test"
ZONE="us-central1-a"
ROLES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/roles"

echo "Copying ALL validation scripts to VM..."

# List of all roles (9 original + 5 new = 14 total)
ALL_ROLES=(
    "install-metadata"
    "install-users-group"
    "install-selinux-firewalld"
    "install-docker-config"
    "install-kubectl"
    "install-nltk-data"
    "install-ops-agent-logging"
    "install-cleanup"
    "install-pyhton-runtime"
    "install-Home"
    "install-home-dir"
    "install-os-login"
    "install-disk"
    "install-nfs-mount"
)

# Copy each validation script
SUCCESS_COUNT=0
FAILED_COUNT=0

for role in "${ALL_ROLES[@]}"; do
    VALIDATION_SCRIPT="${ROLES_DIR}/${role}/validation/validate.sh"
    if [[ -f "$VALIDATION_SCRIPT" ]]; then
        if gcloud compute scp "$VALIDATION_SCRIPT" "${VM_NAME}:/tmp/validate-${role}.sh" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" 2>/dev/null; then
            echo "  ✅ Copied ${role} validation script"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "  ❌ Failed to copy ${role} validation script"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    else
        echo "  ⚠️  Warning: Validation script not found for ${role}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
done

echo ""
echo "=========================================="
echo "Copy Summary:"
echo "  Successfully copied: ${SUCCESS_COUNT}"
echo "  Failed/Missing: ${FAILED_COUNT}"
echo "=========================================="
echo ""
echo "Validation scripts copied to /tmp/ on VM"
echo "They will be used by install-new-roles.sh and Master_Script.sh for validation"
