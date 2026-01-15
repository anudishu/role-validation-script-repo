# Installable Roles - Quick Reference

This document categorizes roles based on their installability and dependencies.

> **💡 Quick Start**: Use the unified deployment script to install all roles:
> ```bash
> ./deploy-roles.sh                    # Deploy all 14 roles
> ./deploy-roles.sh --original-only    # Deploy only original 9 roles
> ./deploy-roles.sh --new-only         # Deploy only new 5 roles
> ```

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

### 10. **install-Home** ⭐
**Status**: ✅ Fully Installable  
**Dependencies**: None  
**Complexity**: Low  
**What it does**: Sets up home base directory structure and configures skeleton files  
**Why it's easy**: Just creates directories and sets permissions  

**Detailed Explanation**:
This role prepares the base directory structure for user home directories. It ensures the `/home` directory exists with proper permissions and can optionally set up skeleton files (template files that are copied to new user home directories when users are created).

**Use Cases**:
- **Initial VM Setup**: When setting up a new VM, ensure `/home` directory structure is ready
- **Standardization**: Ensure consistent home directory permissions across all servers
- **Custom Skeleton Files**: Set up custom `.bashrc`, `.profile`, or other template files that all new users will get

**Example Scenario**:
You're setting up a new RHEL server and want to ensure:
1. The `/home` directory exists with proper permissions (0755)
2. All new users get a custom `.bashrc` with company-specific aliases
3. A standard `.vimrc` file is available to all users

**Variables**:
- `home_base_dir`: Base directory for home (default: `/home`)
- `home_dir_mode`: Permissions mode (default: `0755`)
- `home_dir_recurse`: Apply permissions recursively (default: `false`)
- `skel_source_dir`: Source directory for skeleton files (optional)

**Example Configuration**:
```yaml
home_base_dir: /home
home_dir_mode: "0755"
home_dir_recurse: false
skel_source_dir: "/tmp/custom-skel"  # Optional: custom skeleton files
```

**Before/After Example**:
```bash
# Before: /home might not exist or have wrong permissions
$ ls -ld /home
ls: cannot access '/home': No such file or directory

# After running install-Home:
$ ls -ld /home
drwxr-xr-x 2 root root 4096 Jan 15 10:00 /home

# If skeleton files are configured:
$ ls /etc/skel/
.bashrc  .profile  .vimrc  README.txt
```

**Installation Commands**:
```bash
# Create home base directory
sudo mkdir -p /home
sudo chmod 0755 /home
sudo chown root:root /home

# Optional: Copy skeleton files
# sudo cp -r /path/to/skel/* /etc/skel/
```

---

### 11. **install-home-dir** ⭐
**Status**: ✅ Fully Installable (with user list)  
**Dependencies**: Users must exist (can be created by install-users-group)  
**Complexity**: Low  
**What it does**: Creates home directories for specific users and copies skeleton files  
**Why it's easy**: Standard user home directory setup  

**Detailed Explanation**:
This role creates home directories for specific users and populates them with skeleton files from `/etc/skel/`. It ensures proper ownership and permissions for each user's home directory. This is useful when users are created without home directories, or when you need to recreate/repair home directories.

**Use Cases**:
- **Post-User Creation**: After creating users with `install-users-group`, set up their home directories
- **Home Directory Recovery**: Recreate home directories if they were accidentally deleted
- **Bulk User Setup**: Set up home directories for multiple users at once
- **Custom Permissions**: Set specific permissions (e.g., 0750 for private, 0755 for shared)

**Example Scenario**:
You've created users `dataiku` and `appuser` but they don't have home directories yet. You want to:
1. Create `/home/dataiku` with permissions 0750 (private)
2. Create `/home/appuser` with permissions 0755 (slightly more open)
3. Copy all skeleton files (`.bashrc`, `.profile`, etc.) to each home directory
4. Set proper ownership so users can access their files

**Variables**:
- `home_base_path`: Base path for home directories (default: `/home`)
- `home_dir_users`: List of users with their home directory config
  ```yaml
  home_dir_users:
    - name: user1
      group: user1
      mode: "0750"
  ```

**Example Configuration**:
```yaml
home_base_path: /home
home_dir_users:
  - name: dataiku
    group: dataiku
    mode: "0750"  # Private: only owner and group can access
  - name: appuser
    group: appuser
    mode: "0755"  # More open: others can read/execute
  - name: shareduser
    group: developers
    mode: "0775"  # Shared: group members can write
```

**Before/After Example**:
```bash
# Before: Users exist but no home directories
$ id dataiku
uid=1001(dataiku) gid=1001(dataiku) groups=1001(dataiku)
$ ls -ld /home/dataiku
ls: cannot access '/home/dataiku': No such file or directory

# After running install-home-dir:
$ ls -ld /home/dataiku
drwxr-x--- 2 dataiku dataiku 4096 Jan 15 10:00 /home/dataiku
$ ls -la /home/dataiku/
total 24
drwxr-x---  2 dataiku dataiku 4096 Jan 15 10:00 .
drwxr-xr-x  4 root    root    4096 Jan 15 10:00 ..
-rw-r--r--  1 dataiku dataiku  231 Jan 15 10:00 .bashrc
-rw-r--r--  1 dataiku dataiku  193 Jan 15 10:00 .profile
-rw-r--r--  1 dataiku dataiku  220 Jan 15 10:00 .bash_logout
```

**Installation Commands**:
```bash
# For each user in home_dir_users:
sudo mkdir -p /home/user1
sudo chown user1:user1 /home/user1
sudo chmod 0750 /home/user1
sudo cp -r /etc/skel/* /home/user1/
sudo chown -R user1:user1 /home/user1
```

---

### 12. **install-os-login** ⭐
**Status**: ✅ Fully Installable (on GCP VMs)  
**Dependencies**: GCP VM, internet access  
**Complexity**: Medium  
**What it does**: Installs and configures Google OS Login for IAM-based SSH access  
**Why it's easy**: Standard GCP package, works on any GCP VM  

**Detailed Explanation**:
Google OS Login allows you to manage SSH access to GCP VMs using IAM (Identity and Access Management) instead of managing SSH keys on each VM. When enabled, users can SSH to VMs using their Google Cloud identity, and access is controlled through IAM roles and policies. This eliminates the need to distribute SSH keys and provides centralized access control.

**Use Cases**:
- **Centralized Access Control**: Manage who can SSH to VMs through GCP IAM instead of managing keys
- **Security Compliance**: Meet security requirements for centralized authentication
- **Team Access Management**: Grant/revoke access to team members without touching VMs
- **Audit Trail**: All SSH access is logged in Cloud Audit Logs
- **No Key Management**: No need to distribute or rotate SSH keys

**Example Scenario**:
You have a team of 10 developers who need SSH access to production VMs. Instead of:
- Managing SSH keys on each VM
- Rotating keys when someone leaves
- Manually adding/removing keys

You can:
1. Enable OS Login on the VM
2. Grant IAM role `roles/compute.osLogin` to developers in GCP Console
3. Developers SSH using: `gcloud compute ssh vm-name --zone=us-central1-a`
4. Access is automatically granted/denied based on IAM permissions

**How It Works**:
1. **PAM Integration**: Configures PAM to authenticate users via OS Login
2. **NSS Integration**: Makes OS Login users visible to the system (getent passwd)
3. **Sudo Configuration**: Allows users in `google-sudoers` group to use sudo
4. **IAM Integration**: Users with `roles/compute.osLogin` can SSH; users with `roles/compute.osAdminLogin` get sudo access

**Variables**:
- `os_login_packages`: List of packages (default: `google-compute-engine-oslogin`)
- `os_login_enable_pam`: Enable PAM configuration (default: `true`)
- `os_login_enable_nss`: Enable NSS configuration (default: `true`)
- `os_login_enable_sudo`: Configure sudoers (default: `true`)
- `os_login_restart_sshd`: Restart SSH service (default: `false`)

**Example Configuration**:
```yaml
os_login_packages:
  - google-compute-engine-oslogin
os_login_enable_pam: true
os_login_enable_nss: true
os_login_enable_sudo: true
os_login_restart_sshd: false  # Set to true if you want immediate effect
```

**Before/After Example**:
```bash
# Before: Traditional SSH key-based access
$ ssh -i ~/.ssh/mykey.pem user@vm-ip
# Requires managing SSH keys on each VM

# After: IAM-based access
$ gcloud compute ssh vm-name --zone=us-central1-a
# Or using IAP tunnel:
$ gcloud compute ssh vm-name --zone=us-central1-a --tunnel-through-iap
# Access controlled by IAM roles

# Check OS Login users:
$ getent passwd | grep oslogin
user1_google_com@example.com:x:12345:12345:User One:/home/user1_google_com@example.com:/bin/bash
```

**GCP IAM Roles Required**:
- **To SSH**: `roles/compute.osLogin` (read-only access)
- **To SSH with sudo**: `roles/compute.osAdminLogin` (admin access)

**Installation Commands**:
```bash
# Install OS Login package
sudo yum install -y google-compute-engine-oslogin

# Enable PAM (add to /etc/pam.d/sshd)
echo "account    required     pam_oslogin_login.so" | sudo tee -a /etc/pam.d/sshd

# Configure NSS (update /etc/nsswitch.conf)
sudo sed -i 's/^passwd:.*/passwd:     files oslogin/' /etc/nsswitch.conf

# Configure sudoers
echo "%google-sudoers ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/google-oslogin
sudo chmod 0440 /etc/sudoers.d/google-oslogin

# Restart SSH (if needed)
sudo systemctl restart sshd
```

---

### 13. **install-security-policy** ⭐
**Status**: ✅ Fully Installable  
**Dependencies**: None  
**Complexity**: Medium  
**What it does**: Configures system security policies including password policies, SSH settings, file permissions, and disables unnecessary services  
**Why it's easy**: Standard system security configuration  

**Detailed Explanation**:
This role implements security hardening policies to protect your system. It configures password complexity requirements, SSH security settings, file permissions, and disables unnecessary services. This is essential for production systems and compliance with security standards (PCI-DSS, HIPAA, SOC 2, etc.).

**Use Cases**:
- **Security Compliance**: Meet security requirements for production systems
- **Security Hardening**: Reduce attack surface by disabling unnecessary services
- **Password Policy Enforcement**: Ensure strong passwords are used
- **SSH Security**: Prevent common SSH-based attacks
- **File Protection**: Secure sensitive system files

**Example Scenario**:
You're deploying a production server and need to:
1. Enforce strong passwords (14+ chars, mixed case, numbers, special chars)
2. Disable root SSH login (use sudo instead)
3. Disable password authentication (use keys only)
4. Set password expiration (90 days max)
5. Secure sensitive files (`/etc/shadow` should be 0600)
6. Disable insecure services (telnet, rsh, etc.)

**Security Policies Configured**:

1. **Password Quality** (`/etc/security/pwquality.conf`):
   - `minlen = 14`: Minimum 14 characters
   - `dcredit = -1`: Require at least 1 digit
   - `ucredit = -1`: Require at least 1 uppercase letter
   - `lcredit = -1`: Require at least 1 lowercase letter
   - `ocredit = -1`: Require at least 1 special character

2. **Password Expiration** (`/etc/login.defs`):
   - `PASS_MAX_DAYS 90`: Passwords expire after 90 days
   - `PASS_MIN_DAYS 1`: Can't change password for 1 day (prevents rapid changes)
   - `PASS_WARN_AGE 7`: Warn users 7 days before expiration

3. **SSH Security** (`/etc/ssh/sshd_config`):
   - `PermitRootLogin no`: Prevent direct root login
   - `PasswordAuthentication no`: Only allow key-based authentication
   - `X11Forwarding no`: Disable X11 forwarding (security risk)

4. **File Permissions**: Secure sensitive system files

5. **Service Disabling**: Disable unnecessary/insecure services

**Variables**:
- `security_password_policy`: Password quality settings
- `security_login_defs`: Login definitions (PASS_MAX_DAYS, etc.)
- `security_ssh_settings`: SSH security settings
- `security_file_permissions`: File permission settings
- `security_disabled_services`: List of services to disable

**Example Configuration**:
```yaml
security_password_policy:
  - { key: "minlen", value: "14" }
  - { key: "dcredit", value: "-1" }
  - { key: "ucredit", value: "-1" }
  - { key: "lcredit", value: "-1" }
  - { key: "ocredit", value: "-1" }

security_login_defs:
  - { key: "PASS_MAX_DAYS", value: "90" }
  - { key: "PASS_MIN_DAYS", value: "1" }
  - { key: "PASS_WARN_AGE", value: "7" }

security_ssh_settings:
  - { key: "PermitRootLogin", value: "no" }
  - { key: "PasswordAuthentication", value: "no" }
  - { key: "X11Forwarding", value: "no" }

security_file_permissions:
  - { path: "/etc/shadow", mode: "0600" }
  - { path: "/etc/passwd", mode: "0644" }

security_disabled_services:
  - telnet
  - rsh
  - rlogin
```

**Before/After Example**:
```bash
# Before: Weak security settings
$ grep PermitRootLogin /etc/ssh/sshd_config
#PermitRootLogin yes  # Commented but default is yes
$ grep PasswordAuthentication /etc/ssh/sshd_config
#PasswordAuthentication yes  # Default allows passwords
$ passwd user1
New password: weak123  # Weak password accepted

# After: Strong security settings
$ grep PermitRootLogin /etc/ssh/sshd_config
PermitRootLogin no  # Explicitly disabled
$ grep PasswordAuthentication /etc/ssh/sshd_config
PasswordAuthentication no  # Only keys allowed
$ passwd user1
New password: weak123
BAD PASSWORD: The password is too short  # Enforced!
New password: MyStr0ng!P@ssw0rd  # Strong password required
```

**Installation Commands**:
```bash
# Configure password policy (/etc/security/pwquality.conf)
echo "minlen = 14" | sudo tee -a /etc/security/pwquality.conf
echo "dcredit = -1" | sudo tee -a /etc/security/pwquality.conf
echo "ucredit = -1" | sudo tee -a /etc/security/pwquality.conf
echo "lcredit = -1" | sudo tee -a /etc/security/pwquality.conf
echo "ocredit = -1" | sudo tee -a /etc/security/pwquality.conf

# Configure login defs (/etc/login.defs)
sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
sudo sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
sudo sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs

# Configure SSH settings (/etc/ssh/sshd_config)
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sudo sshd -t  # Validate config
sudo systemctl restart sshd

# Set file permissions (example)
sudo chmod 0600 /etc/shadow
sudo chmod 0644 /etc/passwd

# Disable unnecessary services (example)
sudo systemctl stop telnet
sudo systemctl disable telnet
```

---

## ⚠️ **CONDITIONALLY INSTALLABLE ROLES**

These roles can be installed but require specific resources or setup:

### 14. **install-attach-drive**
**Status**: ⚠️ Requires Disk Attachment  
**Dependencies**: GCP disk must be attached first  
**Complexity**: Low (but needs disk)  
**What it does**: Waits for disk device to be available  
**Note**: Can be tested by attaching a test disk

---

### 15. **install-persistent-disk-mount**
**Status**: ⚠️ Requires Disk Attachment  
**Dependencies**: Disk must be attached and formatted  
**Complexity**: Medium  
**What it does**: Mounts persistent disk  
**Note**: Can be tested with a test disk

---

### 16. **install-shared-resource-mount**
**Status**: ⚠️ Requires Shared Storage  
**Dependencies**: NFS share or shared device  
**Complexity**: Medium  
**What it does**: Mounts shared resources  
**Note**: Can skip if no shared storage available

---

### 17. **install-disk**
**Status**: ⚠️ Requires Disk Device  
**Dependencies**: Disk device must be available (e.g., `/dev/sdb`)  
**Complexity**: Medium  
**What it does**: Creates partition, filesystem, and mounts a disk  
**Why it's conditional**: Requires a disk device to be attached to the VM

**Detailed Explanation**:
This role automates the process of preparing and mounting a new disk. It creates a partition table, creates a partition, formats it with a filesystem, creates a mount point, and mounts the disk. It also adds the mount to `/etc/fstab` so it persists across reboots.

**Use Cases**:
- **Additional Storage**: Add extra storage to a VM for data, logs, or applications
- **Data Separation**: Separate OS disk from data disk for better performance/backup
- **Database Storage**: Mount a dedicated disk for database files
- **Log Storage**: Mount a disk specifically for application logs
- **Backup Storage**: Mount a disk for backup storage

**Example Scenario**:
You've attached a 100GB persistent disk to your GCP VM for application data. The disk appears as `/dev/sdb` but is not yet usable. You need to:
1. Create a partition table (GPT)
2. Create a partition using the full disk
3. Format it with ext4 filesystem
4. Mount it at `/mnt/appdata`
5. Make it persistent across reboots

**Variables**:
- `disk_device`: Disk device path (e.g., `/dev/sdb`)
- `disk_mount_point`: Mount point directory (e.g., `/mnt/data`)
- `disk_fstype`: Filesystem type (default: `ext4`)
- `disk_mount_opts`: Mount options (default: `defaults`)

**Example Configuration**:
```yaml
disk_device: /dev/sdb
disk_mount_point: /mnt/appdata
disk_fstype: ext4
disk_mount_opts: defaults,noatime
```

**Before/After Example**:
```bash
# Before: Disk is attached but not usable
$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda    8:0    0  20G  0 disk
└─sda1 8:1    0  20G  0 part /
sdb    8:16   0 100G  0 disk  # Disk exists but not partitioned/formatted

$ df -h /mnt/appdata
df: /mnt/appdata: No such file or directory

# After: Disk is partitioned, formatted, and mounted
$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda    8:0    0  20G  0 disk
└─sda1 8:1    0  20G  0 part /
sdb    8:16   0 100G  0 disk
└─sdb1 8:17   0 100G  0 part /mnt/appdata  # Partitioned and mounted!

$ df -h /mnt/appdata
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdb1        99G   61M   94G   1% /mnt/appdata

$ grep sdb1 /etc/fstab
/dev/sdb1 /mnt/appdata ext4 defaults 0 2  # Persistent across reboots
```

**⚠️ WARNING**: This role will **FORMAT** the disk, destroying all existing data! Always verify the disk device is correct before running.

**Installation Commands**:
```bash
# Create partition on disk
sudo parted /dev/sdb mklabel gpt
sudo parted /dev/sdb mkpart primary ext4 0% 100%

# Create filesystem
sudo mkfs.ext4 /dev/sdb1

# Create mount point
sudo mkdir -p /mnt/data
sudo chmod 0755 /mnt/data

# Mount the disk
sudo mount -t ext4 /dev/sdb1 /mnt/data

# Add to /etc/fstab for persistence
echo "/dev/sdb1 /mnt/data ext4 defaults 0 2" | sudo tee -a /etc/fstab
```

---

### 18. **install-certificate**
**Status**: ⚠️ Requires Certificate Files  
**Dependencies**: Certificate files (.crt) and private keys (.key) must be available  
**Complexity**: Low  
**What it does**: Copies SSL certificates and private keys to certificate directory  
**Why it's conditional**: Requires certificate files to be available (from secure source)

**Detailed Explanation**:
This role installs SSL/TLS certificates and private keys on the system. It copies certificate files (`.crt`) and private keys (`.key`) to the standard certificate directory and sets appropriate permissions. It also updates the CA trust store so applications can verify certificates.

**Use Cases**:
- **HTTPS/SSL Setup**: Install certificates for web servers (Apache, Nginx)
- **Application Certificates**: Install certificates for applications that use TLS
- **CA Certificates**: Install custom CA certificates for internal services
- **Client Certificates**: Install client certificates for mutual TLS authentication
- **Certificate Updates**: Update/renew certificates on the system

**Example Scenario**:
You have a web application that needs HTTPS. You've obtained SSL certificates from your certificate authority:
- `example.com.crt` - Certificate file
- `example.com.key` - Private key file
- `ca-bundle.crt` - CA bundle

You need to:
1. Copy these files to `/etc/pki/tls/certs/`
2. Set proper permissions (0644 for certs, 0600 for keys)
3. Update the CA trust store so applications can verify certificates

**Variables**:
- `cert_dir`: Certificate directory (default: `/etc/pki/tls/certs`)
- `cert_source_dir`: Source directory containing certificate files

**Example Configuration**:
```yaml
cert_dir: /etc/pki/tls/certs
cert_source_dir: /tmp/certificates  # Source directory with .crt and .key files
```

**File Structure Example**:
```
/tmp/certificates/
├── example.com.crt      # Certificate file
├── example.com.key      # Private key file
├── ca-bundle.crt        # CA bundle
└── intermediate.crt     # Intermediate certificate
```

**Before/After Example**:
```bash
# Before: No certificates installed
$ ls /etc/pki/tls/certs/
ca-bundle.crt  ca-bundle.trust.crt  # Only default CA bundle

$ openssl s_client -connect example.com:443
# Certificate verification fails

# After: Certificates installed
$ ls /etc/pki/tls/certs/
ca-bundle.crt
ca-bundle.trust.crt
example.com.crt      # Your certificate
example.com.key      # Your private key (permissions: 0600)

$ ls -l /etc/pki/tls/certs/example.com*
-rw-r--r-- 1 root root 2048 Jan 15 10:00 example.com.crt
-rw------- 1 root root 1675 Jan 15 10:00 example.com.key  # Secure permissions

$ openssl s_client -connect example.com:443
# Certificate verification succeeds
```

**Security Notes**:
- Private keys (`.key`) are set to mode `0600` (read/write for owner only)
- Certificates (`.crt`) are set to mode `0644` (readable by all, writable by owner)
- Always obtain certificates from trusted sources
- Never commit private keys to version control

**Installation Commands**:
```bash
# Create certificate directory
sudo mkdir -p /etc/pki/tls/certs
sudo chmod 0755 /etc/pki/tls/certs

# Copy certificates (from cert_source_dir)
sudo cp /path/to/certificates/*.crt /etc/pki/tls/certs/
sudo chmod 0644 /etc/pki/tls/certs/*.crt

# Copy private keys
sudo cp /path/to/certificates/*.key /etc/pki/tls/certs/
sudo chmod 0600 /etc/pki/tls/certs/*.key

# Update CA certificates (RHEL)
sudo update-ca-trust
```

---

### 19. **install-nfs-mount**
**Status**: ⚠️ Requires NFS Server  
**Dependencies**: NFS server must be accessible, network connectivity  
**Complexity**: Medium  
**What it does**: Installs NFS utilities and mounts NFS shares  
**Why it's conditional**: Requires an NFS server to be available on the network

**Detailed Explanation**:
This role sets up NFS (Network File System) client functionality, allowing the VM to mount remote file shares from an NFS server. NFS is commonly used for shared storage, allowing multiple servers to access the same files. This is useful for shared application data, logs, or home directories.

**Use Cases**:
- **Shared Storage**: Mount shared storage accessible by multiple VMs
- **Centralized Logs**: Store logs on a central NFS server
- **Shared Application Data**: Share application data across multiple instances
- **Home Directories**: Mount user home directories from a central server
- **Backup Storage**: Mount NFS share for backup storage
- **Content Distribution**: Share content files across web servers

**Example Scenario**:
You have a web application running on multiple VMs that need to share uploaded files. Instead of replicating files to each VM, you:
1. Set up an NFS server with a share at `nfs-server:/export/uploads`
2. Mount this share on each web server VM at `/var/www/uploads`
3. All VMs can now read/write to the same shared storage
4. Files uploaded on one VM are immediately available on all VMs

**Variables**:
- `nfs_packages`: NFS packages to install (default: `nfs-utils`, `rpcbind`)
- `nfs_default_opts`: Default mount options (default: `rw,sync,hard,intr`)
- `nfs_enable_services`: Enable NFS services (default: `true`)
- `nfs_mounts`: List of NFS mounts
  ```yaml
  nfs_mounts:
    - src: "nfs-server:/export/share"
      mount_point: "/mnt/nfs-share"
      opts: "rw,sync,hard,intr"
      mode: "0755"
  ```

**Example Configuration**:
```yaml
nfs_packages:
  - nfs-utils
  - rpcbind
nfs_default_opts: "rw,sync,hard,intr"
nfs_enable_services: true
nfs_mounts:
  - src: "nfs-server.example.com:/export/uploads"
    mount_point: "/var/www/uploads"
    opts: "rw,sync,hard,intr"
    mode: "0755"
  - src: "nfs-server.example.com:/export/logs"
    mount_point: "/var/log/shared"
    opts: "ro,sync,hard,intr"  # Read-only for logs
    mode: "0755"
```

**Mount Options Explained**:
- `rw`: Read-write access
- `ro`: Read-only access
- `sync`: Synchronous writes (safer, slower)
- `async`: Asynchronous writes (faster, less safe)
- `hard`: Hard mount (retry indefinitely if server unavailable)
- `soft`: Soft mount (fail after timeout)
- `intr`: Allow interruption of NFS operations

**Before/After Example**:
```bash
# Before: NFS not installed, no shared storage
$ rpm -q nfs-utils
package nfs-utils is not installed

$ ls /var/www/uploads
ls: cannot access '/var/www/uploads': No such file or directory

# After: NFS installed and mounted
$ rpm -q nfs-utils
nfs-utils-1.3.0-0.el7.x86_64

$ mount | grep nfs
nfs-server.example.com:/export/uploads on /var/www/uploads type nfs (rw,sync,hard,intr)

$ df -h /var/www/uploads
Filesystem                          Size  Used Avail Use% Mounted on
nfs-server.example.com:/export/uploads  500G  200G  300G  40% /var/www/uploads

$ ls /var/www/uploads
file1.txt  file2.txt  shared-data/  # Files accessible from NFS server
```

**Network Requirements**:
- NFS server must be accessible (network connectivity)
- Firewall must allow NFS ports (2049/tcp, 111/tcp, 111/udp)
- NFS server must export the share with proper permissions

**Installation Commands**:
```bash
# Install NFS packages
sudo yum install -y nfs-utils rpcbind

# Create mount point
sudo mkdir -p /mnt/nfs-share
sudo chmod 0755 /mnt/nfs-share

# Mount NFS share
sudo mount -t nfs -o rw,sync,hard,intr nfs-server:/export/share /mnt/nfs-share

# Add to /etc/fstab for persistence
echo "nfs-server:/export/share /mnt/nfs-share nfs rw,sync,hard,intr 0 0" | sudo tee -a /etc/fstab

# Enable and start NFS services
sudo systemctl enable rpcbind
sudo systemctl start rpcbind
sudo systemctl enable nfs-client.target
sudo systemctl start nfs-client.target
```

---

## ❌ **NOT EASILY INSTALLABLE** (Requires Organization Resources)

These roles require organization-specific resources, credentials, or app team involvement:

### 20. **install-dataiku-app**
**Status**: ❌ Requires Dataiku Package/Credentials  
**Dependencies**: Dataiku installation package, license  
**Complexity**: High  
**Why it's hard**: Requires Dataiku-specific resources from app team

---

### 21. **install-local-repo-rpms**
**Status**: ❌ Requires RPM Packages  
**Dependencies**: RPM packages must be available  
**Complexity**: Medium  
**Why it's hard**: Needs pre-built RPM packages from organization

---

### 22. **install-packages-download**
**Status**: ❌ Requires GCS Bucket Access  
**Dependencies**: GCS bucket with packages, IAM permissions  
**Complexity**: Medium  
**Why it's hard**: Needs organization-specific GCS bucket

---

### 23. **install-qualys-agent**
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
| install-Home | ✅ Yes | Low | None | ⭐⭐⭐ |
| install-home-dir | ✅ Yes | Low | Users | ⭐⭐⭐ |
| install-kubectl | ✅ Yes | Low | Internet | ⭐⭐⭐ |
| install-metadata | ✅ Yes | Very Low | GCP VM | ⭐⭐⭐ |
| install-nltk-data | ✅ Yes | Low | Python | ⭐⭐⭐ |
| install-ops-agent-logging | ✅ Yes | Medium | GCP VM | ⭐⭐⭐ |
| install-os-login | ✅ Yes | Medium | GCP VM | ⭐⭐⭐ |
| install-pyhton-runtime | ✅ Yes | Low | Internet | ⭐⭐⭐ |
| install-security-policy | ✅ Yes | Medium | None | ⭐⭐⭐ |
| install-selinux-firewalld | ✅ Yes | Low | None | ⭐⭐⭐ |
| install-users-group | ✅ Yes | Low | None | ⭐⭐⭐ |
| install-attach-drive | ⚠️ Conditional | Low | Disk | ⭐⭐ |
| install-certificate | ⚠️ Conditional | Low | Certificates | ⭐⭐ |
| install-disk | ⚠️ Conditional | Medium | Disk Device | ⭐⭐ |
| install-nfs-mount | ⚠️ Conditional | Medium | NFS Server | ⭐⭐ |
| install-persistent-disk-mount | ⚠️ Conditional | Medium | Disk | ⭐⭐ |
| install-shared-resource-mount | ⚠️ Conditional | Medium | Storage | ⭐ |
| install-dataiku-app | ❌ No | High | Dataiku | - |
| install-local-repo-rpms | ❌ No | Medium | RPMs | - |
| install-packages-download | ❌ No | Medium | GCS Bucket | - |
| install-qualys-agent | ❌ No | High | Credentials | - |

---

## 🎯 Recommended Installation Order (13 Easy Roles)

For validation purposes, install these 13 roles in this order:

1. **install-metadata** - No installation, just verify
2. **install-pyhton-runtime** - Install Python first (needed for NLTK)
3. **install-users-group** - Create users early
4. **install-Home** - Set up home base directory
5. **install-home-dir** - Create user home directories (after users are created)
6. **install-selinux-firewalld** - Configure basic security
7. **install-security-policy** - Configure advanced security policies
8. **install-os-login** - Configure OS Login (GCP IAM-based SSH)
9. **install-docker-config** - Install Docker
10. **install-kubectl** - Install kubectl
11. **install-nltk-data** - Install NLTK (requires Python)
12. **install-ops-agent-logging** - Install logging agent
13. **install-cleanup** - Clean up at the end

---

## 📝 Quick Installation

### Using the Unified Deployment Script (Recommended)

The easiest way to install all roles is using the unified deployment script:

```bash
# Deploy all 14 roles
./deploy-roles.sh

# Or deploy specific role sets
./deploy-roles.sh --original-only    # Deploy only original 9 roles
./deploy-roles.sh --new-only         # Deploy only new 5 roles
```

For more details, see [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md).

### Manual Installation Script

Here's a manual script to install all 14 easily installable roles (for reference):

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

# 4. install-Home
echo "4. Setting up home base directory..."
sudo mkdir -p /home
sudo chmod 0755 /home
sudo chown root:root /home

# 5. install-home-dir
echo "5. Creating user home directories..."
sudo mkdir -p /home/dataiku /home/dataiku_user
sudo chown dataiku:dataiku /home/dataiku
sudo chown dataiku_user:dataiku_user_group /home/dataiku_user
sudo chmod 0750 /home/dataiku /home/dataiku_user
sudo cp -r /etc/skel/* /home/dataiku/ 2>/dev/null || true
sudo cp -r /etc/skel/* /home/dataiku_user/ 2>/dev/null || true
sudo chown -R dataiku:dataiku /home/dataiku
sudo chown -R dataiku_user:dataiku_user_group /home/dataiku_user

# 6. install-selinux-firewalld
echo "4. Configuring SELinux and firewalld..."
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
sudo setenforce 0
sudo yum install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-port=10000/tcp
sudo firewall-cmd --reload

# 9. install-docker-config
echo "9. Installing Docker..."
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

# 10. install-kubectl
echo "10. Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/bin/kubectl

# 11. install-nltk-data
echo "11. Installing NLTK data..."
sudo yum install -y python3-pip
sudo pip3 install nltk
sudo mkdir -p /opt/dataiku/nltk_data
sudo python3 << 'PYTHON'
import nltk
nltk.data.path.append('/opt/dataiku/nltk_data')
nltk.download('punkt', download_dir='/opt/dataiku/nltk_data')
nltk.download('stopwords', download_dir='/opt/dataiku/nltk_data')
PYTHON

# 12. install-ops-agent-logging
echo "12. Installing Ops Agent..."
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

# 13. install-cleanup
echo "13. Cleaning up system..."
sudo yum install -y yum-utils
sudo package-cleanup --oldkernels --count=1 -y
sudo yum clean all

echo "=========================================="
echo "✅ All 13 easily installable roles installed!"
echo "=========================================="
```

---

## ✅ Validation Strategy

Focus on creating validation scripts for these **13 easily installable roles**:

1. ✅ install-cleanup
2. ✅ install-docker-config
3. ✅ install-Home
4. ✅ install-home-dir
5. ✅ install-kubectl
6. ✅ install-metadata
7. ✅ install-nltk-data
8. ✅ install-ops-agent-logging
9. ✅ install-os-login
10. ✅ install-pyhton-runtime
11. ✅ install-security-policy
12. ✅ install-selinux-firewalld
13. ✅ install-users-group

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

---

## 📋 New Roles Summary

### ✅ New Easily Installable Roles (4 roles)

1. **install-Home** - Sets up home base directory structure
2. **install-home-dir** - Creates home directories for users
3. **install-os-login** - Configures Google OS Login for IAM-based SSH
4. **install-security-policy** - Configures system security policies

### ⚠️ New Conditionally Installable Roles (3 roles)

1. **install-disk** - Partitions, formats, and mounts disks (⚠️ WARNING: formats disk)
2. **install-certificate** - Installs SSL certificates (requires certificate files)
3. **install-nfs-mount** - Mounts NFS shares (requires NFS server)

All new roles have been documented with:
- ✅ Status and dependencies
- ✅ What they do
- ✅ Installation commands
- ✅ Variable descriptions
- ✅ Notes and warnings
