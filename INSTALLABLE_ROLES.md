# Installable Roles - Quick Reference

This document categorizes roles based on their installability and dependencies.

---

## ✅ **EASILY INSTALLABLE ROLES** (Recommended for Validation)

These roles can be installed independently without organization-specific requirements:

### 1. **install-cleanup** ⭐
**Status**: ✅ Fully Installable  
**Dependencies**: None  
**Complexity**: Low  
**What it does**: Cleans up old kernels and yum cache  
**Why it's easy**: Standard system maintenance commands

---

### 2. **install-docker-config** ⭐
**Status**: ✅ Fully Installable  
**Dependencies**: Internet access for Docker repo  
**Complexity**: Medium  
**What it does**: Installs Docker and creates wrapper script  
**Why it's easy**: Standard Docker installation from official repo

---

### 3. **install-kubectl** ⭐
**Status**: ✅ Fully Installable  
**Dependencies**: Internet access  
**Complexity**: Low  
**What it does**: Installs kubectl CLI tool  
**Why it's easy**: Standard tool installation, no credentials needed

---

### 4. **install-metadata** ⭐
**Status**: ✅ Verification Only (No Installation)  
**Dependencies**: GCP VM (metadata is automatic)  
**Complexity**: Very Low  
**What it does**: Reads GCE instance metadata  
**Why it's easy**: Just reads metadata that's already available on GCP VMs

---

### 5. **install-nltk-data** ⭐
**Status**: ✅ Fully Installable  
**Dependencies**: Python3, pip, internet access  
**Complexity**: Low  
**What it does**: Downloads NLTK data packages  
**Why it's easy**: Standard Python package installation

---

### 6. **install-ops-agent-logging** ⭐
**Status**: ✅ Fully Installable (on GCP VMs)  
**Dependencies**: GCP VM, internet access  
**Complexity**: Medium  
**What it does**: Installs Google Cloud Ops Agent for logging  
**Why it's easy**: Standard GCP tool, works on any GCP VM

---

### 7. **install-pyhton-runtime** ⭐
**Status**: ✅ Fully Installable  
**Dependencies**: Internet access, yum repos  
**Complexity**: Low  
**What it does**: Installs Python 3.8 and 3.9  
**Why it's easy**: Standard Python installation from repos

---

### 8. **install-selinux-firewalld** ⭐
**Status**: ✅ Fully Installable  
**Dependencies**: None (firewalld in standard repos)  
**Complexity**: Low  
**What it does**: Configures SELinux and firewalld  
**Why it's easy**: Standard system security configuration

---

### 9. **install-users-group** ⭐
**Status**: ✅ Fully Installable  
**Dependencies**: None  
**Complexity**: Low  
**What it does**: Creates users, groups, and configures sudoers  
**Why it's easy**: Standard Linux user/group management

---

## ⚠️ **CONDITIONALLY INSTALLABLE ROLES**

These roles can be installed but require specific resources or setup:

### 10. **install-attach-drive**
**Status**: ⚠️ Requires Disk Attachment  
**Dependencies**: GCP disk must be attached first  
**Complexity**: Low (but needs disk)  
**What it does**: Waits for disk device to be available  
**Note**: Can be tested by attaching a test disk

---

### 11. **install-persistent-disk-mount**
**Status**: ⚠️ Requires Disk Attachment  
**Dependencies**: Disk must be attached and formatted  
**Complexity**: Medium  
**What it does**: Mounts persistent disk  
**Note**: Can be tested with a test disk

---

### 12. **install-shared-resource-mount**
**Status**: ⚠️ Requires Shared Storage  
**Dependencies**: NFS share or shared device  
**Complexity**: Medium  
**What it does**: Mounts shared resources  
**Note**: Can skip if no shared storage available

---

## ❌ **NOT EASILY INSTALLABLE** (Requires Organization Resources)

These roles require organization-specific resources, credentials, or app team involvement:

### 13. **install-dataiku-app**
**Status**: ❌ Requires Dataiku Package/Credentials  
**Dependencies**: Dataiku installation package, license  
**Complexity**: High  
**Why it's hard**: Requires Dataiku-specific resources from app team

---

### 14. **install-local-repo-rpms**
**Status**: ❌ Requires RPM Packages  
**Dependencies**: RPM packages must be available  
**Complexity**: Medium  
**Why it's hard**: Needs pre-built RPM packages from organization

---

### 15. **install-packages-download**
**Status**: ❌ Requires GCS Bucket Access  
**Dependencies**: GCS bucket with packages, IAM permissions  
**Complexity**: Medium  
**Why it's hard**: Needs organization-specific GCS bucket

---

### 16. **install-qualys-agent**
**Status**: ❌ Requires Qualys Credentials  
**Dependencies**: Qualys account, activation ID, customer ID  
**Complexity**: High  
**Why it's hard**: Requires security team credentials

---

## 📊 Summary Table

| Role | Installable | Complexity | Dependencies | Recommended |
|------|------------|------------|--------------|-------------|
| install-cleanup | ✅ Yes | Low | None | ⭐⭐⭐ |
| install-docker-config | ✅ Yes | Medium | Internet | ⭐⭐⭐ |
| install-kubectl | ✅ Yes | Low | Internet | ⭐⭐⭐ |
| install-metadata | ✅ Yes | Very Low | GCP VM | ⭐⭐⭐ |
| install-nltk-data | ✅ Yes | Low | Python | ⭐⭐⭐ |
| install-ops-agent-logging | ✅ Yes | Medium | GCP VM | ⭐⭐⭐ |
| install-pyhton-runtime | ✅ Yes | Low | Internet | ⭐⭐⭐ |
| install-selinux-firewalld | ✅ Yes | Low | None | ⭐⭐⭐ |
| install-users-group | ✅ Yes | Low | None | ⭐⭐⭐ |
| install-attach-drive | ⚠️ Conditional | Low | Disk | ⭐⭐ |
| install-persistent-disk-mount | ⚠️ Conditional | Medium | Disk | ⭐⭐ |
| install-shared-resource-mount | ⚠️ Conditional | Medium | Storage | ⭐ |
| install-dataiku-app | ❌ No | High | Dataiku | - |
| install-local-repo-rpms | ❌ No | Medium | RPMs | - |
| install-packages-download | ❌ No | Medium | GCS Bucket | - |
| install-qualys-agent | ❌ No | High | Credentials | - |

---

## 🎯 Recommended Installation Order (9 Easy Roles)

For validation purposes, install these 9 roles in this order:

1. **install-metadata** - No installation, just verify
2. **install-pyhton-runtime** - Install Python first (needed for NLTK)
3. **install-users-group** - Create users early
4. **install-selinux-firewalld** - Configure security
5. **install-docker-config** - Install Docker
6. **install-kubectl** - Install kubectl
7. **install-nltk-data** - Install NLTK (requires Python)
8. **install-ops-agent-logging** - Install logging agent
9. **install-cleanup** - Clean up at the end

---

## 📝 Quick Installation Script

Here's a script to install all 9 easily installable roles:

```bash
#!/bin/bash
# Install all easily installable roles on RHEL 9

set -euo pipefail

echo "=========================================="
echo "Installing Easily Installable Roles"
echo "=========================================="

# 1. install-metadata (verification only)
echo "1. Verifying metadata access..."
curl -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id

# 2. install-pyhton-runtime
echo "2. Installing Python 3.8 and 3.9..."
sudo yum install -y python38 python38-devel python39 python39-devel

# 3. install-users-group
echo "3. Creating users and groups..."
sudo groupadd dataiku
sudo useradd -g dataiku -m -s /bin/bash dataiku
sudo groupadd -g 1011 dataiku_user_group
sudo useradd -g dataiku_user_group -m -s /bin/bash dataiku_user
echo "dataiku ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/dataiku-dss-uf-wrapper
sudo chmod 440 /etc/sudoers.d/dataiku-dss-uf-wrapper
echo "dataiku soft nofile 4096" | sudo tee /etc/security/limits.d/90-custom.conf

# 4. install-selinux-firewalld
echo "4. Configuring SELinux and firewalld..."
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sudo setenforce 0
sudo yum install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-port=10000/tcp
sudo firewall-cmd --reload

# 5. install-docker-config
echo "5. Installing Docker..."
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo tee /usr/local/bin/docker-wrapper.py > /dev/null << 'EOF'
#!/usr/bin/env python3
import subprocess
import sys
subprocess.run(['docker'] + sys.argv[1:])
EOF
sudo chmod +x /usr/local/bin/docker-wrapper.py
sudo systemctl enable docker
sudo systemctl start docker

# 6. install-kubectl
echo "6. Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/bin/kubectl

# 7. install-nltk-data
echo "7. Installing NLTK data..."
sudo yum install -y python3-pip
sudo pip3 install nltk
sudo mkdir -p /opt/dataiku/nltk_data
sudo python3 << 'PYTHON'
import nltk
nltk.data.path.append('/opt/dataiku/nltk_data')
nltk.download('punkt', download_dir='/opt/dataiku/nltk_data')
nltk.download('stopwords', download_dir='/opt/dataiku/nltk_data')
PYTHON

# 8. install-ops-agent-logging
echo "8. Installing Ops Agent..."
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo mkdir -p /etc/google-cloud-ops-agent
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << 'EOF'
logging:
  receivers:
    syslog:
      type: files
      include_paths:
        - /var/log/messages
        - /var/log/syslog
  service:
    pipelines:
      default_pipeline:
        receivers: [syslog]
EOF
sudo systemctl restart google-cloud-ops-agent
sudo timedatectl set-timezone America/New_York
sudo sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 86400/' /etc/ssh/sshd_config
sudo sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# 9. install-cleanup
echo "9. Cleaning up system..."
sudo yum install -y yum-utils
sudo package-cleanup --oldkernels --count=1 -y
sudo yum clean all

echo "=========================================="
echo "✅ All easily installable roles installed!"
echo "=========================================="
```

---

## ✅ Validation Strategy

Focus on creating validation scripts for these **9 easily installable roles**:

1. ✅ install-cleanup
2. ✅ install-docker-config
3. ✅ install-kubectl
4. ✅ install-metadata
5. ✅ install-nltk-data
6. ✅ install-ops-agent-logging
7. ✅ install-pyhton-runtime
8. ✅ install-selinux-firewalld
9. ✅ install-users-group

These roles are:
- ✅ Self-contained
- ✅ No external dependencies
- ✅ Easy to install
- ✅ Easy to validate
- ✅ Standard tools/packages

---

## 🚫 Skip These for Now

Don't focus on these roles for validation (they require organization resources):

- ❌ install-dataiku-app
- ❌ install-local-repo-rpms
- ❌ install-packages-download
- ❌ install-qualys-agent

You can add validation for these later when you have access to the required resources.

