#!/bin/bash
# Quick deployment script - Deploys roles to GCP RHEL 9 VM
# Usage: ./quick-deploy.sh <VM_NAME> <ZONE>

set -euo pipefail

PROJECT_ID="lyfedge-project"
VM_NAME="${1:-}"
ZONE="${2:-}"

if [ -z "$VM_NAME" ] || [ -z "$ZONE" ]; then
    echo "Usage: $0 <VM_NAME> <ZONE>"
    echo ""
    echo "Example:"
    echo "  $0 my-rhel9-vm us-central1-a"
    echo ""
    echo "To find your VM:"
    echo "  gcloud compute instances list --project=${PROJECT_ID}"
    exit 1
fi

echo "=========================================="
echo "Deploying Roles to GCP VM"
echo "=========================================="
echo "Project: ${PROJECT_ID}"
echo "VM Name: ${VM_NAME}"
echo "Zone: ${ZONE}"
echo ""

# Step 1: Copy deployment script to VM
echo "Step 1: Copying deployment script to VM..."
gcloud compute scp deploy-roles.sh ${VM_NAME}:~/ \
  --zone=${ZONE} \
  --project=${PROJECT_ID} \
  --quiet

if [ $? -ne 0 ]; then
    echo "❌ Failed to copy script to VM"
    exit 1
fi

echo "✅ Script copied successfully"
echo ""

# Step 2: SSH to VM and run deployment
echo "Step 2: Running deployment on VM..."
echo "This will SSH to the VM and execute the deployment script."
echo ""

gcloud compute ssh ${VM_NAME} \
  --zone=${ZONE} \
  --project=${PROJECT_ID} \
  --command="chmod +x ~/deploy-roles.sh && ~/deploy-roles.sh"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✅ Deployment completed successfully!"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "❌ Deployment failed. Check the output above."
    echo "=========================================="
    exit 1
fi

