# Shivani 2026 - Ansible Roles Deployment

Comprehensive Ansible roles for RHEL 9 VM configuration and deployment on GCP.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Available Roles](#available-roles)
4. [Installation](#installation)
5. [Validation](#validation)
6. [Project Structure](#project-structure)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This repository contains Ansible roles for automating the installation and configuration of various software packages, system settings, and services on RHEL 9 VMs running on Google Cloud Platform.

### Key Features

- ✅ **14 Installable Roles** - Ready-to-use roles for common configurations
- ✅ **Automated Installation** - Bash scripts for easy deployment
- ✅ **Validation Scripts** - Comprehensive validation for each role
- ✅ **Master Validation** - Single script to validate all roles
- ✅ **GCP Optimized** - Designed for Google Cloud Platform VMs

### Project Status

- **Total Roles**: 23 roles (14 easily installable, 5 conditionally installable, 4 requiring organization resources)
- **Successfully Tested**: 14 roles validated and working
- **VM Tested On**: rhel9-roles-test (us-central1-a, lyfedge-project)

---

## 🚀 Quick Start

### Prerequisites

- GCP VM running RHEL 9
- SSH access to the VM
- Sudo/root privileges
- Internet access (for package downloads)

### Quick Installation

```bash
# 1. Clone or download this repository
cd shivani-2026

# 2. Deploy all 14 roles (recommended)
./deploy-roles.sh

# Or deploy specific role sets:
# ./deploy-roles.sh --original-only    # Deploy only original 9 roles
# ./deploy-roles.sh --new-only         # Deploy only new 5 roles

# 3. Validate all installations
./copy-validation-scripts.sh
gcloud compute ssh rhel9-roles-test --zone=us-central1-a --project=lyfedge-project \
  --command="cd /tmp && bash Master_Script.sh"
```

---

## 📦 Available Roles

### ✅ Easily Installable Roles (14 roles)

These roles can be installed independently without organization-specific requirements:

1. **install-metadata** - Verifies GCE metadata access
2. **install-pyhton-runtime** - Installs Python 3.8 and 3.9
3. **install-users-group** - Creates users, groups, and configures sudoers
4. **install-selinux-firewalld** - Configures SELinux and firewalld
5. **install-docker-config** - Installs Docker and creates wrapper script
6. **install-kubectl** - Installs kubectl CLI tool
7. **install-nltk-data** - Downloads NLTK data packages
8. **install-ops-agent-logging** - Installs Google Cloud Ops Agent
9. **install-cleanup** - Cleans up old kernels and yum cache
10. **install-Home** - Sets up home base directory structure
11. **install-home-dir** - Creates home directories for users
12. **install-os-login** - Configures Google OS Login for IAM-based SSH
13. **install-disk** - Partitions, formats, and mounts disks
14. **install-nfs-mount** - Installs NFS utilities and mounts NFS shares

### ⚠️ Conditionally Installable Roles (5 roles)

These roles require specific resources or setup:

- **install-attach-drive** - Requires disk attachment
- **install-persistent-disk-mount** - Requires disk attachment
- **install-shared-resource-mount** - Requires shared storage
- **install-certificate** - Requires certificate files
- **install-disk** - Requires disk device (already listed above)

### ❌ Organization-Specific Roles (4 roles)

These roles require organization-specific resources:

- **install-dataiku-app** - Requires Dataiku package/credentials
- **install-local-repo-rpms** - Requires RPM packages
- **install-packages-download** - Requires GCS bucket access
- **install-qualys-agent** - Requires Qualys credentials

For detailed information about each role, see [INSTALLABLE_ROLES.md](INSTALLABLE_ROLES.md).

---

## 📥 Installation

### Method 1: Automated Installation (Recommended)

#### Install All 14 Roles (Default)

```bash
./deploy-roles.sh
```

This installs all 14 roles:
- **Original 9 roles**: install-metadata, install-pyhton-runtime, install-users-group, install-selinux-firewalld, install-docker-config, install-kubectl, install-nltk-data, install-ops-agent-logging, install-cleanup
- **New 5 roles**: install-Home, install-home-dir, install-os-login, install-disk, install-nfs-mount

#### Install Specific Role Sets

```bash
# Install only original 9 roles
./deploy-roles.sh --original-only

# Install only new 5 roles
./deploy-roles.sh --new-only

# Install new roles without disk creation
./deploy-roles.sh --new-only --skip-disk
```

### Method 2: Manual Installation

For detailed manual installation steps, see [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md).

### Installation Scripts

- **`deploy-roles.sh`** - Unified deployment script (embeds install-new-roles.sh, supports --original-only, --new-only flags)
- **`install-new-roles.sh`** - Installation functions (read by deploy-roles.sh, can also be run directly on VM)
- **`copy-validation-scripts.sh`** - Copies validation scripts to VM
- **`quick-deploy.sh`** - Quick deployment helper

**Note**: `deploy-roles.sh` now embeds `install-new-roles.sh` - it reads it locally and executes it on the VM via SSH, so no file copy is needed.

---

## ✅ Validation

### Individual Role Validation

Each role has its own validation script in `roles/<role-name>/validation/validate.sh`.

```bash
# Run validation for a specific role
bash roles/install-docker-config/validation/validate.sh
```

### Master Validation Script

Run all validations at once:

```bash
# 1. Copy all validation scripts to VM
./copy-validation-scripts.sh

# 2. Run master validation script
gcloud compute ssh rhel9-roles-test --zone=us-central1-a --project=lyfedge-project \
  --command="cd /tmp && bash Master_Script.sh"
```

The master script validates all 14 roles and reports PASS/FAIL for each.

### Validation Results

All 14 roles have been validated and are passing:

- ✅ Metadata Access
- ✅ Users and Groups
- ✅ SELinux and Firewalld
- ✅ Docker Configuration
- ✅ Kubectl
- ✅ NLTK Data
- ✅ Ops Agent Logging
- ✅ System Cleanup
- ✅ Python Runtime
- ✅ Home Base Directory
- ✅ User Home Directories
- ✅ OS Login
- ✅ Disk Mount
- ✅ NFS Mount

---

## 📁 Project Structure

```
shivani-2026/
├── README.md                    # This file - main documentation
├── INSTALLABLE_ROLES.md         # Detailed role overview and descriptions
├── INSTALLATION_GUIDE.md        # Step-by-step installation instructions
├── roles/                       # All Ansible roles
│   ├── install-*/              # Individual role directories
│   │   ├── tasks/              # Role tasks
│   │   ├── defaults/           # Default variables
│   │   └── validation/          # Validation scripts
├── scripts/
│   └── Master_Script.sh        # Master validation script
├── deploy-roles.sh              # Unified deployment script (embeds install-new-roles.sh)
├── install-new-roles.sh        # Installation functions (read by deploy-roles.sh)
├── copy-validation-scripts.sh   # Copy validation scripts to VM
└── quick-deploy.sh              # Quick deployment helper
```

---

## 🔧 Configuration

### VM Configuration

Default configuration (can be modified in scripts):

- **Project**: lyfedge-project
- **VM Name**: rhel9-roles-test
- **Zone**: us-central1-a

### Role-Specific Configuration

Each role has default variables that can be customized. See individual role `defaults/main.yaml` files or [INSTALLABLE_ROLES.md](INSTALLABLE_ROLES.md) for details.

---

## 🐛 Troubleshooting

### SSH Access Issues

If SSH is blocked after installation:

```bash
# Use serial console to fix
gcloud compute instances add-metadata rhel9-roles-test \
  --metadata serial-port-enable=true \
  --zone=us-central1-a --project=lyfedge-project

gcloud compute connect-to-serial-port rhel9-roles-test \
  --zone=us-central1-a --project=lyfedge-project

# Then run:
sudo sed -i 's/^X11Forwarding no/X11Forwarding yes/; s/^PasswordAuthentication no/PasswordAuthentication yes/; s/^PermitRootLogin no/#PermitRootLogin yes/' /etc/ssh/sshd_config && sudo sshd -t && sudo systemctl restart sshd
```

### Validation Failures

If a validation fails:

1. Check the validation script output for specific errors
2. Verify the role was installed correctly
3. Check logs: `/tmp/new-role-installation-*.log`
4. Re-run the installation for that specific role

### Disk Mount Issues

If disk mount fails:

```bash
# Check if disk is attached
lsblk

# Check if disk is formatted
sudo fdisk -l /dev/sdb

# Manually mount if needed
sudo mount /dev/sdb1 /mnt/data
```

### NFS Mount Issues

If NFS mount fails:

```bash
# Check NFS server status
sudo systemctl status nfs-server

# Check exports
sudo exportfs -v

# Restart NFS services
sudo systemctl restart rpcbind
sudo systemctl restart nfs-server
```

---

## 📚 Documentation

- **[INSTALLABLE_ROLES.md](INSTALLABLE_ROLES.md)** - Complete role overview with examples, use cases, and detailed explanations
- **[INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)** - Step-by-step installation instructions for all roles

---

## 🎯 Recommended Installation Order

For best results, install roles in this order:

1. **install-metadata** - Verify GCP metadata access
2. **install-pyhton-runtime** - Install Python (needed for other roles)
3. **install-users-group** - Create users early
4. **install-Home** - Set up home base directory
5. **install-home-dir** - Create user home directories
6. **install-selinux-firewalld** - Configure basic security
7. **install-os-login** - Configure OS Login (optional)
8. **install-docker-config** - Install Docker
9. **install-kubectl** - Install kubectl
10. **install-nltk-data** - Install NLTK (requires Python)
11. **install-ops-agent-logging** - Install logging agent
12. **install-disk** - Mount additional disk (if needed)
13. **install-nfs-mount** - Mount NFS shares (if needed)
14. **install-cleanup** - Clean up at the end

---

## 📊 Current Status

### Successfully Deployed Roles (14/14)

| # | Role Name | Status | Validation |
|---|-----------|--------|------------|
| 1 | install-metadata | ✅ Success | ✅ PASS |
| 2 | install-users-group | ✅ Success | ✅ PASS |
| 3 | install-selinux-firewalld | ✅ Success | ✅ PASS |
| 4 | install-docker-config | ✅ Success | ✅ PASS |
| 5 | install-kubectl | ✅ Success | ✅ PASS |
| 6 | install-nltk-data | ✅ Success | ✅ PASS |
| 7 | install-ops-agent-logging | ✅ Success | ✅ PASS |
| 8 | install-cleanup | ✅ Success | ✅ PASS |
| 9 | install-pyhton-runtime | ✅ Success | ✅ PASS |
| 10 | install-Home | ✅ Success | ✅ PASS |
| 11 | install-home-dir | ✅ Success | ✅ PASS |
| 12 | install-os-login | ✅ Success | ✅ PASS |
| 13 | install-disk | ✅ Success | ✅ PASS |
| 14 | install-nfs-mount | ✅ Success | ✅ PASS |

**Note**: All 14 roles have been successfully deployed and validated on rhel9-roles-test VM.

---

## 🔐 Security Notes

- **Security Policy**: The `install-security-policy` role is **disabled by default** to prevent SSH blocking issues
- **SSH Settings**: Installation scripts do not modify SSH settings to ensure access is maintained
- **Password Policy**: Minimal password requirements (4 characters minimum) to avoid blocking
- **OS Login**: Configured for IAM-based SSH access (optional)

---

## 📝 Scripts Overview

### Deployment Scripts

- **`deploy-roles.sh`** - Unified deployment script for all 14 roles
  - Supports `--original-only` flag to deploy only original 9 roles
  - Supports `--new-only` flag to deploy only new 5 roles
  - Supports `--skip-disk` flag to skip disk creation
  - Configurable VM name, zone, and project
- **`install-new-roles.sh`** - Main installation script (can be run directly on VM)

### Validation Scripts

- **`copy-validation-scripts.sh`** - Copies all validation scripts to VM
- **`scripts/Master_Script.sh`** - Master validation script (validates all 14 roles)

### Helper Scripts

- **`quick-deploy.sh`** - Quick deployment helper

---

## 🤝 Contributing

When adding new roles:

1. Create role directory structure: `roles/install-<name>/`
2. Add tasks in `roles/install-<name>/tasks/main.yaml`
3. Add defaults in `roles/install-<name>/defaults/main.yaml`
4. Create validation script: `roles/install-<name>/validation/validate.sh`
5. Add role to `INSTALLABLE_ROLES.md`
6. Add role to `install-new-roles.sh` or `deploy-roles.sh`
7. Add validation to `scripts/Master_Script.sh`

---

## 📞 Support

For issues or questions:

1. Check [INSTALLABLE_ROLES.md](INSTALLABLE_ROLES.md) for role-specific information
2. Check [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) for installation steps
3. Review validation logs: `/tmp/new-role-installation-*.log`
4. Check master validation log: `/tmp/validation_results_*.log`

---

## 📄 License

This project is for internal use.

---

**Last Updated**: January 15, 2026  
**Tested On**: RHEL 9, GCP (lyfedge-project)  
**Status**: ✅ All 14 roles validated and working
