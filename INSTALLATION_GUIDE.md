# Installation Guide - Step-by-Step Instructions

Complete installation guide for all roles on RHEL 9 VMs.

---

## 📋 Table of Contents

1. [Quick Installation](#quick-installation)
2. [Automated Installation](#automated-installation)
3. [Manual Installation](#manual-installation)
4. [Role-Specific Installation](#role-specific-installation)
5. [Validation](#validation)

---

## 🚀 Quick Installation

### Install All Roles (Recommended)

```bash
# 1. Deploy all 14 roles (unified script)
./deploy-roles.sh

# Or deploy specific role sets:
# ./deploy-roles.sh --original-only    # Deploy only original 9 roles
# ./deploy-roles.sh --new-only         # Deploy only new 5 roles

# 2. Validate all installations
./copy-validation-scripts.sh
gcloud compute ssh rhel9-roles-test --zone=us-central1-a --project=lyfedge-project \
  --command="cd /tmp && bash Master_Script.sh"
```

---

## 🤖 Automated Installation

### Method 1: Using Unified Deployment Script

The `deploy-roles.sh` script is a unified deployment script that can deploy all roles or specific subsets.

#### Deploy All 14 Roles (Default)

```bash
./deploy-roles.sh
```

This script:
- Deploys all 14 easily installable roles
- Creates and attaches 2GB disk (for new roles)
- Copies installation and validation scripts to VM
- Runs installation with validation
- Logs all operations
- Reports success/failure for each role

#### Deploy Only Original 9 Roles

```bash
./deploy-roles.sh --original-only
```

This installs:
- install-metadata
- install-pyhton-runtime
- install-users-group
- install-selinux-firewalld
- install-docker-config
- install-kubectl
- install-nltk-data
- install-ops-agent-logging
- install-cleanup

#### Deploy Only New 5 Roles

```bash
./deploy-roles.sh --new-only
```

This script:
- Creates and attaches 2GB disk
- Installs 5 new roles (Home, home-dir, OS Login, disk, NFS mount)
- Runs validation after each installation

#### Deploy New Roles Without Disk

```bash
./deploy-roles.sh --new-only --skip-disk
```

Use this if the disk is already attached or you don't need disk installation.

#### Custom Configuration

```bash
# Custom VM, zone, or project
./deploy-roles.sh --vm-name my-vm --zone us-east1-a --project my-project
```

### Method 2: Direct Script Execution

```bash
# Copy installation script to VM
gcloud compute scp install-new-roles.sh rhel9-roles-test:~/ \
  --zone=us-central1-a --project=lyfedge-project

# Run on VM
gcloud compute ssh rhel9-roles-test --zone=us-central1-a --project=lyfedge-project \
  --command="chmod +x ~/install-new-roles.sh && ~/install-new-roles.sh"
```

---

## 📝 Manual Installation

### Prerequisites

```bash
# SSH to VM
gcloud compute ssh rhel9-roles-test --zone=us-central1-a --project=lyfedge-project

# Ensure you have sudo access
sudo whoami
```

### 1. install-metadata (Verification Only)

```bash
# Verify GCE metadata access
curl -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/project/project-id
```

### 2. install-pyhton-runtime

```bash
# Install Python 3.8 and 3.9
sudo yum install -y python38 python38-devel python39 python39-devel

# Verify
python3.9 --version
python3.8 --version
```

### 3. install-users-group

```bash
# Create groups
sudo groupadd dataiku
sudo groupadd -g 1011 dataiku_user_group

# Create users
sudo useradd -g dataiku -m -s /bin/bash dataiku
sudo useradd -g dataiku_user_group -m -s /bin/bash dataiku_user

# Configure sudoers
echo "dataiku ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/dataiku-dss-uf-wrapper
sudo chmod 440 /etc/sudoers.d/dataiku-dss-uf-wrapper

# Set limits
echo "dataiku soft nofile 4096" | sudo tee /etc/security/limits.d/90-custom.conf

# Verify
id dataiku
id dataiku_user
```

### 4. install-selinux-firewalld

```bash
# Configure SELinux
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sudo setenforce 0

# Install and configure firewalld
sudo yum install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-port=10000/tcp
sudo firewall-cmd --reload

# Verify
grep "^SELINUX=" /etc/selinux/config
sudo systemctl status firewalld
```

### 5. install-docker-config

```bash
# Install Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Create wrapper script
sudo tee /usr/local/bin/docker-wrapper.py > /dev/null << 'EOF'
#!/usr/bin/env python3
import subprocess
import sys
subprocess.run(['docker'] + sys.argv[1:])
EOF
sudo chmod +x /usr/local/bin/docker-wrapper.py

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Verify
docker --version
sudo systemctl status docker
```

### 6. install-kubectl

```bash
# Download and install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/bin/kubectl

# Verify
kubectl version --client
```

### 7. install-nltk-data

```bash
# Install pip and NLTK
sudo yum install -y python3-pip
sudo pip3 install nltk

# Create directory and download NLTK data
sudo mkdir -p /opt/dataiku/nltk_data
sudo python3 << 'PYTHON'
import nltk
nltk.data.path.append('/opt/dataiku/nltk_data')
nltk.download('punkt', download_dir='/opt/dataiku/nltk_data')
nltk.download('stopwords', download_dir='/opt/dataiku/nltk_data')
PYTHON

# Verify
ls -la /opt/dataiku/nltk_data
```

### 8. install-ops-agent-logging

```bash
# Install Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Configure logging
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

# Restart agent
sudo systemctl restart google-cloud-ops-agent

# Configure timezone and SSH
sudo timedatectl set-timezone America/New_York
sudo sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 86400/' /etc/ssh/sshd_config
sudo sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Verify
sudo systemctl status google-cloud-ops-agent
```

### 9. install-cleanup

```bash
# Install yum-utils
sudo yum install -y yum-utils

# Clean up old kernels
sudo package-cleanup --oldkernels --count=1 -y

# Clean yum cache
sudo yum clean all

# Verify
rpm -qa kernel | wc -l
```

### 10. install-Home

```bash
# Create home base directory
sudo mkdir -p /home
sudo chmod 0755 /home
sudo chown root:root /home

# Verify
ls -ld /home
```

### 11. install-home-dir

```bash
# Create users (if not already created)
sudo useradd -m -s /bin/bash user1
sudo useradd -m -s /bin/bash user2

# Create home directories with proper ownership
sudo mkdir -p /home/user1 /home/user2
sudo chown user1:user1 /home/user1
sudo chown user2:user2 /home/user2
sudo chmod 0750 /home/user1 /home/user2

# Copy skeleton files
sudo cp -r /etc/skel/* /home/user1/ 2>/dev/null || true
sudo cp -r /etc/skel/* /home/user2/ 2>/dev/null || true
sudo chown -R user1:user1 /home/user1
sudo chown -R user2:user2 /home/user2

# Verify
ls -la /home/user1
ls -la /home/user2
```

### 12. install-os-login

```bash
# Install OS Login package
sudo yum install -y google-compute-engine-oslogin

# Configure PAM
echo "account    required     pam_oslogin_login.so" | sudo tee -a /etc/pam.d/sshd

# Configure NSS
sudo sed -i 's/^passwd:.*/passwd:     files oslogin/' /etc/nsswitch.conf

# Configure sudoers
echo "%google-sudoers ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/google-oslogin
sudo chmod 0440 /etc/sudoers.d/google-oslogin

# Validate sudoers
sudo visudo -cf /etc/sudoers.d/google-oslogin

# Verify
rpm -q google-compute-engine-oslogin
grep oslogin /etc/nsswitch.conf
```

### 13. install-disk

```bash
# Create and attach disk (from local machine)
gcloud compute disks create rhel9-roles-test-data-disk \
  --size=2GB \
  --zone=us-central1-a \
  --project=lyfedge-project

gcloud compute instances attach-disk rhel9-roles-test \
  --disk=rhel9-roles-test-data-disk \
  --zone=us-central1-a \
  --project=lyfedge-project

# On VM: Partition and format disk
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary ext4 0% 100%
sleep 2
sudo mkfs -t ext4 /dev/sdb1

# Create mount point and mount
sudo mkdir -p /mnt/data
sudo chmod 0755 /mnt/data
sudo mount -t ext4 /dev/sdb1 /mnt/data

# Add to fstab for persistence
echo "/dev/sdb1 /mnt/data ext4 defaults 0 2" | sudo tee -a /etc/fstab

# Verify
df -h /mnt/data
mount | grep /mnt/data
```

### 14. install-nfs-mount

```bash
# Install NFS packages
sudo yum install -y nfs-utils rpcbind

# Set up NFS server (for testing)
sudo mkdir -p /export/nfs-share
sudo chmod 755 /export/nfs-share
sudo chown nobody:nobody /export/nfs-share
echo "This is a test file" | sudo tee /export/nfs-share/test-file.txt
sudo chown nobody:nobody /export/nfs-share/test-file.txt

# Configure exports
echo "/export/nfs-share 127.0.0.1(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports

# Start NFS server
sudo systemctl enable rpcbind
sudo systemctl start rpcbind
sudo systemctl enable nfs-server
sudo systemctl start nfs-server
sudo exportfs -ra

# Install NFS client and mount
sudo systemctl enable nfs-client.target
sudo systemctl start nfs-client.target
sudo mkdir -p /mnt/nfs-share
sudo chmod 0755 /mnt/nfs-share
sudo mount -t nfs -o rw,sync,hard,intr 127.0.0.1:/export/nfs-share /mnt/nfs-share

# Add to fstab
echo "127.0.0.1:/export/nfs-share /mnt/nfs-share nfs rw,sync,hard,intr 0 0" | sudo tee -a /etc/fstab

# Verify
mount | grep nfs
df -h /mnt/nfs-share
ls -la /mnt/nfs-share
```

---

## ✅ Validation

### Individual Role Validation

```bash
# Run validation for a specific role
bash roles/install-docker-config/validation/validate.sh
bash roles/install-Home/validation/validate.sh
```

### Master Validation

```bash
# Copy all validation scripts
./copy-validation-scripts.sh

# Run master validation
gcloud compute ssh rhel9-roles-test --zone=us-central1-a --project=lyfedge-project \
  --command="cd /tmp && bash Master_Script.sh"
```

---

## 🔧 Troubleshooting

### Installation Fails

1. Check logs: `/tmp/new-role-installation-*.log`
2. Verify internet connectivity
3. Check sudo permissions
4. Review error messages in script output

### Validation Fails

1. Check validation script output for specific errors
2. Verify role was installed correctly
3. Re-run installation for that role
4. Check system logs: `journalctl -xe`

### SSH Access Issues

If SSH is blocked:

```bash
# Use serial console
gcloud compute instances add-metadata rhel9-roles-test \
  --metadata serial-port-enable=true \
  --zone=us-central1-a --project=lyfedge-project

gcloud compute connect-to-serial-port rhel9-roles-test \
  --zone=us-central1-a --project=lyfedge-project

# Fix SSH settings
sudo sed -i 's/^X11Forwarding no/X11Forwarding yes/; s/^PasswordAuthentication no/PasswordAuthentication yes/; s/^PermitRootLogin no/#PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sshd -t && sudo systemctl restart sshd
```

---

## 📊 Installation Order

Recommended installation order:

1. install-metadata
2. install-pyhton-runtime
3. install-users-group
4. install-Home
5. install-home-dir
6. install-selinux-firewalld
7. install-os-login
8. install-docker-config
9. install-kubectl
10. install-nltk-data
11. install-ops-agent-logging
12. install-disk
13. install-nfs-mount
14. install-cleanup

---

For detailed role information, see [INSTALLABLE_ROLES.md](INSTALLABLE_ROLES.md).
