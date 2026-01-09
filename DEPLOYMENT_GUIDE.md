# Deployment Guide - Easily Installable Roles on GCP RHEL 9 VM

## Quick Start

This guide will help you deploy all 9 easily installable roles on your GCP RHEL 9 VM in the `lyfedge-project` project.

---

## Prerequisites

1. **GCP RHEL 9 VM** - Must be running RHEL 9
2. **gcloud CLI** - Installed and authenticated
3. **SSH Access** - Access to the VM
4. **Sudo Access** - Root or sudo privileges on the VM

---

## Step 1: Find Your VM

List all VMs in your project:

```bash
gcloud compute instances list --project=lyfedge-project
```

Note down:
- **VM Name**
- **Zone**

---

## Step 2: SSH to Your VM

```bash
gcloud compute ssh <VM_NAME> \
  --zone=<ZONE> \
  --project=lyfedge-project
```

Example:
```bash
gcloud compute ssh my-rhel9-vm \
  --zone=us-central1-a \
  --project=lyfedge-project
```

---

## Step 3: Upload Deployment Script

### Option A: Copy script content manually

1. Open the `deploy-roles.sh` file locally
2. Copy its contents
3. On the VM, create the file:
   ```bash
   nano deploy-roles.sh
   ```
4. Paste the contents and save (Ctrl+X, then Y, then Enter)
5. Make it executable:
   ```bash
   chmod +x deploy-roles.sh
   ```

### Option B: Use gcloud to copy file

From your local machine:

```bash
gcloud compute scp deploy-roles.sh <VM_NAME>:~/ \
  --zone=<ZONE> \
  --project=lyfedge-project
```

Then on the VM:
```bash
chmod +x deploy-roles.sh
```

---

## Step 4: Run Deployment Script

On the VM, execute:

```bash
./deploy-roles.sh
```

The script will:
1. ✅ Install all 9 roles automatically
2. ✅ Show progress for each role
3. ✅ Log everything to `/tmp/role-installation-*.log`
4. ✅ Report success/failure at the end

---

## What Gets Installed

The script installs these 9 roles in order:

1. **install-metadata** - Verifies GCE metadata access
2. **install-pyhton-runtime** - Python 3.8 and 3.9
3. **install-users-group** - Creates dataiku users and groups
4. **install-selinux-firewalld** - Configures SELinux and firewalld
5. **install-docker-config** - Docker and wrapper script
6. **install-kubectl** - kubectl CLI tool
7. **install-nltk-data** - NLTK Python packages
8. **install-ops-agent-logging** - Google Cloud Ops Agent
9. **install-cleanup** - System cleanup

---

## Expected Output

```
==========================================
Role Installation Script
Project: lyfedge-project
Log file: /tmp/role-installation-20250127-143022.log
==========================================

[2025-01-27 14:30:22] Installing role: install-metadata...
✅ Metadata accessible. Project ID: lyfedge-project
✅ Role install-metadata installed successfully

[2025-01-27 14:30:23] Installing role: install-pyhton-runtime...
✅ Python installed: Python 3.8.18, Python 3.9.16
✅ Role install-pyhton-runtime installed successfully

...

==========================================
Installation Summary
==========================================
Total roles: 9
Successful: 9
Failed: 0

✅ All roles installed successfully!
Log file: /tmp/role-installation-20250127-143022.log
```

---

## Troubleshooting

### Issue: "yum command not found"
**Solution**: Ensure you're on RHEL/CentOS. For RHEL 9, use `dnf` instead of `yum` (the script uses `yum` which should work on RHEL 9).

### Issue: "Cannot access GCE metadata"
**Solution**: This is normal if running outside GCP. The script will continue with a warning.

### Issue: "Failed to install Docker"
**Solution**: 
- Check internet connectivity
- Verify Docker repository is accessible
- Try: `sudo yum clean all && sudo yum makecache`

### Issue: "Failed to download kubectl"
**Solution**: 
- Check internet connectivity
- Verify you can access `dl.k8s.io`
- Try downloading manually first

### Issue: "Permission denied"
**Solution**: Ensure you have sudo access:
```bash
sudo -v
```

---

## Verification

After installation, verify each role:

```bash
# 1. Metadata
curl -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id

# 2. Python
/usr/bin/python3.8 --version
/usr/bin/python3.9 --version

# 3. Users
id dataiku
id dataiku_user

# 4. SELinux & Firewalld
grep "^SELINUX=" /etc/selinux/config
sudo systemctl status firewalld

# 5. Docker
docker --version
ls -la /usr/local/bin/docker-wrapper.py

# 6. kubectl
kubectl version --client

# 7. NLTK
ls -la /opt/dataiku/nltk_data

# 8. Ops Agent
sudo systemctl status google-cloud-ops-agent

# 9. Cleanup (check kernel count)
rpm -qa kernel | wc -l
```

---

## Running Validation Scripts

After installation, you can run validation scripts:

```bash
# Navigate to roles directory (if you have the repo)
cd /path/to/shivani-2026/roles

# Run validation for each role
./install-metadata/validation/validate.sh
./install-pyhton-runtime/validation/validate.sh
./install-users-group/validation/validate.sh
./install-selinux-firewalld/validation/validate.sh
./install-docker-config/validation/validate.sh
./install-kubectl/validation/validate.sh
./install-nltk-data/validation/validate.sh
./install-ops-agent-logging/validation/validate.sh
./install-cleanup/validation/validate.sh
```

---

## Log Files

All installation logs are saved to:
```
/tmp/role-installation-YYYYMMDD-HHMMSS.log
```

View the log:
```bash
cat /tmp/role-installation-*.log
```

---

## Manual Installation (Alternative)

If you prefer to install roles manually, refer to the `README.md` file for step-by-step instructions for each role.

---

## Next Steps

1. ✅ Install all 9 roles using the deployment script
2. ✅ Verify installation using the verification commands above
3. ✅ Run validation scripts to ensure everything works
4. ✅ Create/update validation scripts if needed

---

## Support

If you encounter issues:

1. Check the log file: `/tmp/role-installation-*.log`
2. Review the troubleshooting section above
3. Verify prerequisites are met
4. Check GCP VM console for any errors

---

## Quick Command Reference

```bash
# SSH to VM
gcloud compute ssh <VM_NAME> --zone=<ZONE> --project=lyfedge-project

# Copy script to VM
gcloud compute scp deploy-roles.sh <VM_NAME>:~/ --zone=<ZONE> --project=lyfedge-project

# On VM: Run deployment
./deploy-roles.sh

# On VM: Check logs
cat /tmp/role-installation-*.log
```

