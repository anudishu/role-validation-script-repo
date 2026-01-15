#!/bin/bash
# Installation script for new roles on rhel9-roles-test VM
# Roles: install-Home, install-home-dir, install-os-login, install-security-policy, install-disk

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="lyfedge-project"
VM_NAME="rhel9-roles-test"
ZONE="us-central1-a"
LOG_FILE="/tmp/new-role-installation-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "${LOG_FILE}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ==============================================================================
# Original 9 Role Installation Functions
# ==============================================================================

# 1. install-metadata (verification only)
install_metadata() {
    log "Verifying GCE metadata access..."
    if curl -H "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/project/project-id >/dev/null 2>&1; then
        PROJECT_ID_META=$(curl -H "Metadata-Flavor: Google" \
            http://metadata.google.internal/computeMetadata/v1/project/project-id)
        log_success "Metadata accessible. Project ID: ${PROJECT_ID_META}"
    else
        log_error "Cannot access GCE metadata"
        return 1
    fi
}

# 2. install-pyhton-runtime
install_python_runtime() {
    log "Installing Python 3.8 and 3.9..."
    
    if ! command_exists yum; then
        log_error "yum command not found. This script is for RHEL/CentOS."
        return 1
    fi
    
    PYTHON38_AVAILABLE=false
    PYTHON39_AVAILABLE=false
    
    # Check for Python 3.9 (default on RHEL 9)
    if command_exists python3.9 || [ -f /usr/bin/python3.9 ]; then
        PYTHON39_AVAILABLE=true
        PYTHON39_VER=$(python3.9 --version 2>&1 || /usr/bin/python3.9 --version 2>&1)
    else
        if sudo yum install -y python39 python39-devel 2>/dev/null; then
            PYTHON39_AVAILABLE=true
            PYTHON39_VER=$(python3.9 --version 2>&1)
        fi
    fi
    
    # Check for Python 3.8 (may not be available on RHEL 9)
    if command_exists python3.8 || [ -f /usr/bin/python3.8 ]; then
        PYTHON38_AVAILABLE=true
        PYTHON38_VER=$(python3.8 --version 2>&1 || /usr/bin/python3.8 --version 2>&1)
    else
        if sudo yum install -y python38 python38-devel 2>/dev/null; then
            PYTHON38_AVAILABLE=true
            PYTHON38_VER=$(python3.8 --version 2>&1)
        else
            log_warning "Python 3.8 not available in repos (this is normal for RHEL 9)"
        fi
    fi
    
    if [ "$PYTHON39_AVAILABLE" = true ]; then
        if [ "$PYTHON38_AVAILABLE" = true ]; then
            log_success "Python installed: ${PYTHON38_VER}, ${PYTHON39_VER}"
        else
            log_success "Python installed: ${PYTHON39_VER} (Python 3.8 not available on RHEL 9)"
        fi
    else
        log_error "Python 3.9 installation verification failed"
        return 1
    fi
}

# 3. install-users-group
install_users_group() {
    log "Creating users and groups..."
    
    if ! getent group dataiku >/dev/null 2>&1; then
        sudo groupadd dataiku || {
            log_error "Failed to create dataiku group"
            return 1
        }
    fi
    
    if ! id dataiku >/dev/null 2>&1; then
        sudo useradd -g dataiku -m -s /bin/bash dataiku || {
            log_error "Failed to create dataiku user"
            return 1
        }
    fi
    
    if ! getent group dataiku_user_group >/dev/null 2>&1; then
        sudo groupadd -g 1011 dataiku_user_group || {
            log_error "Failed to create dataiku_user_group"
            return 1
        }
    fi
    
    if ! id dataiku_user >/dev/null 2>&1; then
        sudo useradd -g dataiku_user_group -m -s /bin/bash dataiku_user || {
            log_error "Failed to create dataiku_user"
            return 1
        }
    fi
    
    echo "dataiku ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/dataiku-dss-uf-wrapper >/dev/null
    sudo chmod 440 /etc/sudoers.d/dataiku-dss-uf-wrapper
    
    echo "dataiku soft nofile 4096" | sudo tee /etc/security/limits.d/90-custom.conf >/dev/null
    sudo chmod 644 /etc/security/limits.d/90-custom.conf
    
    log_success "Users and groups created successfully"
}

# 4. install-selinux-firewalld
install_selinux_firewalld() {
    log "Configuring SELinux and firewalld..."
    
    sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
    sudo setenforce 0 || log_warning "Could not set SELinux to permissive (may require reboot)"
    
    if ! rpm -q firewalld >/dev/null 2>&1; then
        sudo yum install -y firewalld || {
            log_error "Failed to install firewalld"
            return 1
        }
    fi
    
    sudo systemctl enable firewalld
    sudo systemctl start firewalld || {
        log_error "Failed to start firewalld"
        return 1
    }
    
    sudo firewall-cmd --permanent --add-port=10000/tcp
    sudo firewall-cmd --reload
    
    log_success "SELinux and firewalld configured"
}

# 5. install-docker-config
install_docker_config() {
    log "Installing Docker and creating wrapper..."
    
    if ! command_exists docker; then
        sudo yum install -y yum-utils || {
            log_error "Failed to install yum-utils"
            return 1
        }
        
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || {
            log_error "Failed to add Docker repository"
            return 1
        }
        
        sudo yum install -y docker-ce docker-ce-cli containerd.io || {
            log_error "Failed to install Docker"
            return 1
        }
    fi
    
    sudo tee /usr/local/bin/docker-wrapper.py > /dev/null << 'EOF'
#!/usr/bin/env python3
import subprocess
import sys
subprocess.run(['docker'] + sys.argv[1:])
EOF
    
    sudo chmod +x /usr/local/bin/docker-wrapper.py
    sudo chown root:root /usr/local/bin/docker-wrapper.py
    
    sudo systemctl enable docker
    sudo systemctl start docker || {
        log_error "Failed to start Docker service"
        return 1
    }
    
    if docker --version >/dev/null 2>&1; then
        DOCKER_VER=$(docker --version)
        log_success "Docker installed: ${DOCKER_VER}"
    else
        log_error "Docker verification failed"
        return 1
    fi
}

# 6. install-kubectl
install_kubectl() {
    log "Installing kubectl..."
    
    if [ -f /usr/bin/kubectl ]; then
        log_warning "kubectl already exists, skipping installation"
        return 0
    fi
    
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" || {
        log_error "Failed to download kubectl"
        return 1
    }
    
    chmod +x kubectl
    sudo mv kubectl /usr/bin/kubectl
    
    if kubectl version --client >/dev/null 2>&1; then
        KUBECTL_VER=$(kubectl version --client --output=yaml 2>/dev/null | grep gitVersion | cut -d'"' -f2 || echo "unknown")
        log_success "kubectl installed: ${KUBECTL_VER}"
    else
        log_error "kubectl verification failed"
        return 1
    fi
}

# 7. install-nltk-data
install_nltk_data() {
    log "Installing NLTK data..."
    
    if ! command_exists pip3; then
        sudo yum install -y python3-pip || {
            log_error "Failed to install python3-pip"
            return 1
        }
    fi
    
    sudo pip3 install nltk || {
        log_error "Failed to install NLTK"
        return 1
    }
    
    sudo mkdir -p /opt/dataiku/nltk_data
    sudo chmod 755 /opt/dataiku/nltk_data
    
    sudo python3 << 'PYTHON'
import nltk
import sys
nltk.data.path.append('/opt/dataiku/nltk_data')
try:
    nltk.download('punkt', download_dir='/opt/dataiku/nltk_data', quiet=True)
    nltk.download('stopwords', download_dir='/opt/dataiku/nltk_data', quiet=True)
    print("NLTK data downloaded successfully")
except Exception as e:
    print(f"Error downloading NLTK data: {e}")
    sys.exit(1)
PYTHON
    
    if [ $? -eq 0 ]; then
        log_success "NLTK data installed"
    else
        log_error "Failed to download NLTK data"
        return 1
    fi
}

# 8. install-ops-agent-logging
install_ops_agent_logging() {
    log "Installing Google Cloud Ops Agent..."
    
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh || {
        log_error "Failed to download Ops Agent installer"
        return 1
    }
    
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install || {
        log_error "Failed to install Ops Agent"
        return 1
    }
    
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
    
    sudo systemctl restart google-cloud-ops-agent || {
        log_warning "Could not restart Ops Agent (may not be installed)"
    }
    
    sudo timedatectl set-timezone America/New_York || log_warning "Could not set timezone"
    
    sudo sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 86400/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config
    sudo systemctl restart sshd || log_warning "Could not restart sshd"
    
    log_success "Ops Agent configured"
}

# 9. install-cleanup
install_cleanup() {
    log "Cleaning up system..."
    
    if ! command_exists package-cleanup; then
        sudo yum install -y yum-utils || {
            log_warning "Could not install yum-utils"
        }
    fi
    
    if command_exists package-cleanup; then
        sudo package-cleanup --oldkernels --count=1 -y || {
            log_warning "Could not clean up old kernels"
        }
    fi
    
    sudo yum clean all || {
        log_warning "Could not clean yum cache"
    }
    
    log_success "System cleanup completed"
}

# ==============================================================================
# New 5 Role Installation Functions
# ==============================================================================

# Function to validate a role installation
validate_role() {
    local role_name=$1
    local validation_script_path=""
    
    log "Validating role: ${role_name}..."
    
    # Try to find validation script in common locations
    # First, try in /tmp (if copied there)
    if [[ -f "/tmp/validate-${role_name}.sh" ]]; then
        validation_script_path="/tmp/validate-${role_name}.sh"
    # Try in roles directory structure (if roles are deployed)
    elif [[ -f "~/roles/${role_name}/validation/validate.sh" ]]; then
        validation_script_path="~/roles/${role_name}/validation/validate.sh"
    elif [[ -f "/home/$(whoami)/roles/${role_name}/validation/validate.sh" ]]; then
        validation_script_path="/home/$(whoami)/roles/${role_name}/validation/validate.sh"
    fi
    
    # If validation script found, run it
    if [[ -n "$validation_script_path" ]] && [[ -f "$validation_script_path" ]]; then
        log "Running validation script: ${validation_script_path}"
        if bash "$validation_script_path"; then
            return 0
        else
            return 1
        fi
    else
        # Fall back to inline validation functions
        log_warning "Validation script not found, using inline validation"
        case "${role_name}" in
            "install-Home")
                validate_install_home
                ;;
            "install-home-dir")
                validate_install_home_dir
                ;;
            "install-os-login")
                validate_install_os_login
                ;;
            "install-disk")
                validate_install_disk
                ;;
            "install-nfs-mount")
                validate_install_nfs_mount
                ;;
            *)
                log_warning "No validation available for ${role_name}"
                return 0
                ;;
        esac
    fi
}

# Validation functions for each role
validate_install_home() {
    local failed=0
    echo "=========================================="
    echo "Validating: install-Home"
    echo "=========================================="
    
    if [[ ! -d /home ]]; then
        echo "  ❌ ERROR: /home directory not found"
        failed=1
    else
        echo "  ✅ PASS: /home directory exists"
        PERMS=$(stat -c "%a" /home 2>/dev/null || echo "unknown")
        if [[ "$PERMS" == "755" ]] || [[ "$PERMS" == "0755" ]]; then
            echo "  ✅ PASS: /home has correct permissions (755)"
        else
            echo "  ⚠️  WARN: /home permissions are ${PERMS} (expected 755)"
        fi
    fi
    
    echo "=========================================="
    if [[ $failed -eq 0 ]]; then
        echo "✅ VALIDATION PASSED: install-Home"
        return 0
    else
        echo "❌ VALIDATION FAILED: install-Home"
        return 1
    fi
}

validate_install_home_dir() {
    local failed=0
    echo "=========================================="
    echo "Validating: install-home-dir"
    echo "=========================================="
    
    for user in user1 user2; do
        if [[ ! -d "/home/${user}" ]]; then
            echo "  ❌ ERROR: /home/${user} directory not found"
            failed=1
        else
            echo "  ✅ PASS: /home/${user} directory exists"
            OWNER=$(stat -c "%U" "/home/${user}" 2>/dev/null || echo "unknown")
            if [[ "$OWNER" == "$user" ]]; then
                echo "  ✅ PASS: /home/${user} is owned by ${user}"
            else
                echo "  ❌ ERROR: /home/${user} is owned by ${OWNER} (expected ${user})"
                failed=1
            fi
        fi
        
        if ! id "$user" >/dev/null 2>&1; then
            echo "  ❌ ERROR: User '${user}' not found"
            failed=1
        else
            echo "  ✅ PASS: User '${user}' exists"
        fi
    done
    
    echo "=========================================="
    if [[ $failed -eq 0 ]]; then
        echo "✅ VALIDATION PASSED: install-home-dir"
        return 0
    else
        echo "❌ VALIDATION FAILED: install-home-dir"
        return 1
    fi
}

validate_install_os_login() {
    local failed=0
    echo "=========================================="
    echo "Validating: install-os-login"
    echo "=========================================="
    
    if ! rpm -q google-compute-engine-oslogin >/dev/null 2>&1; then
        echo "  ❌ ERROR: google-compute-engine-oslogin package not installed"
        failed=1
    else
        PACKAGE_VERSION=$(rpm -q google-compute-engine-oslogin)
        echo "  ✅ PASS: OS Login package installed (${PACKAGE_VERSION})"
    fi
    
    if grep -q "pam_oslogin_login.so" /etc/pam.d/sshd 2>/dev/null; then
        echo "  ✅ PASS: OS Login PAM configuration found"
    else
        echo "  ⚠️  WARN: OS Login PAM configuration not found"
    fi
    
    if grep -q "^passwd:.*oslogin" /etc/nsswitch.conf 2>/dev/null; then
        echo "  ✅ PASS: OS Login configured in /etc/nsswitch.conf"
    else
        echo "  ⚠️  WARN: OS Login not configured in /etc/nsswitch.conf"
    fi
    
    if [[ -f /etc/sudoers.d/google-oslogin ]]; then
        echo "  ✅ PASS: OS Login sudoers file exists"
    else
        echo "  ⚠️  WARN: OS Login sudoers file not found"
    fi
    
    echo "=========================================="
    if [[ $failed -eq 0 ]]; then
        echo "✅ VALIDATION PASSED: install-os-login"
        return 0
    else
        echo "❌ VALIDATION FAILED: install-os-login"
        return 1
    fi
}

validate_install_disk() {
    local failed=0
    echo "=========================================="
    echo "Validating: install-disk"
    echo "=========================================="
    
    if [[ ! -d /mnt/data ]]; then
        echo "  ❌ ERROR: /mnt/data directory not found"
        failed=1
    else
        echo "  ✅ PASS: /mnt/data directory exists"
    fi
    
    if ! mountpoint -q /mnt/data 2>/dev/null; then
        echo "  ❌ ERROR: /mnt/data is not mounted"
        failed=1
    else
        echo "  ✅ PASS: /mnt/data is mounted"
        if df -h /mnt/data >/dev/null 2>&1; then
            DISK_INFO=$(df -h /mnt/data | tail -1)
            echo "  ✅ PASS: Disk info: ${DISK_INFO}"
        fi
    fi
    
    if grep -q "/mnt/data" /etc/fstab 2>/dev/null; then
        echo "  ✅ PASS: /mnt/data found in /etc/fstab"
    else
        echo "  ⚠️  WARN: /mnt/data not found in /etc/fstab"
    fi
    
    echo "=========================================="
    if [[ $failed -eq 0 ]]; then
        echo "✅ VALIDATION PASSED: install-disk"
        return 0
    else
        echo "❌ VALIDATION FAILED: install-disk"
        return 1
    fi
}

validate_install_nfs_mount() {
    local failed=0
    echo "=========================================="
    echo "Validating: install-nfs-mount"
    echo "=========================================="
    
    if ! rpm -q nfs-utils >/dev/null 2>&1; then
        echo "  ❌ ERROR: nfs-utils package not installed"
        failed=1
    else
        PACKAGE_VERSION=$(rpm -q nfs-utils)
        echo "  ✅ PASS: nfs-utils installed (${PACKAGE_VERSION})"
    fi
    
    if ! rpm -q rpcbind >/dev/null 2>&1; then
        echo "  ❌ ERROR: rpcbind package not installed"
        failed=1
    else
        echo "  ✅ PASS: rpcbind installed"
    fi
    
    if [[ ! -d /mnt/nfs-share ]]; then
        echo "  ❌ ERROR: /mnt/nfs-share directory not found"
        failed=1
    else
        echo "  ✅ PASS: /mnt/nfs-share directory exists"
    fi
    
    if ! mountpoint -q /mnt/nfs-share 2>/dev/null; then
        echo "  ❌ ERROR: /mnt/nfs-share is not mounted"
        failed=1
    else
        echo "  ✅ PASS: /mnt/nfs-share is mounted"
        if mount | grep -q "/mnt/nfs-share" 2>/dev/null; then
            MOUNT_INFO=$(mount | grep "/mnt/nfs-share" | head -1)
            echo "  ✅ PASS: NFS mount found"
        fi
    fi
    
    if grep -q "/mnt/nfs-share" /etc/fstab 2>/dev/null; then
        echo "  ✅ PASS: /mnt/nfs-share found in /etc/fstab"
    else
        echo "  ⚠️  WARN: /mnt/nfs-share not found in /etc/fstab"
    fi
    
    echo "=========================================="
    if [[ $failed -eq 0 ]]; then
        echo "✅ VALIDATION PASSED: install-nfs-mount"
        return 0
    else
        echo "❌ VALIDATION FAILED: install-nfs-mount"
        return 1
    fi
}

# 1. install-Home
install_home() {
    log "Installing role: install-Home..."
    
    # Ensure home base directory exists
    sudo mkdir -p /home
    sudo chmod 0755 /home
    sudo chown root:root /home
    
    log_success "Home base directory configured"
}

# 2. install-home-dir
install_home_dir() {
    log "Installing role: install-home-dir..."
    
    # Create users if they don't exist
    for user in user1 user2; do
        if ! id "$user" &>/dev/null; then
            log "Creating user: $user"
            sudo useradd -m -s /bin/bash "$user" || {
                log_warning "User $user might already exist or creation failed"
            }
        fi
    done
    
    # Create home directories for users
    for user in user1 user2; do
        if id "$user" &>/dev/null; then
            HOME_DIR="/home/$user"
            USER_GROUP=$(id -gn "$user")
            
            # Create home directory if it doesn't exist
            if [ ! -d "$HOME_DIR" ]; then
                sudo mkdir -p "$HOME_DIR"
            fi
            
            # Set ownership and permissions
            sudo chown "$user:$USER_GROUP" "$HOME_DIR"
            sudo chmod 0750 "$HOME_DIR"
            
            # Copy skeleton files if /etc/skel has content
            if [ -d /etc/skel ] && [ "$(ls -A /etc/skel)" ]; then
                sudo cp -r /etc/skel/* "$HOME_DIR/" 2>/dev/null || true
                sudo chown -R "$user:$USER_GROUP" "$HOME_DIR"
            fi
            
            log_success "Home directory created for $user"
        fi
    done
    
    log_success "User home directories configured"
}

# 3. install-os-login
install_os_login() {
    log "Installing role: install-os-login..."
    
    # Install OS Login package
    if ! rpm -q google-compute-engine-oslogin &>/dev/null; then
        sudo yum install -y google-compute-engine-oslogin || {
            log_error "Failed to install google-compute-engine-oslogin"
            return 1
        }
    else
        log "google-compute-engine-oslogin already installed"
    fi
    
    # Enable PAM configuration
    if ! grep -q "pam_oslogin_login.so" /etc/pam.d/sshd; then
        echo "account    required     pam_oslogin_login.so" | sudo tee -a /etc/pam.d/sshd
        log_success "PAM configuration updated"
    else
        log "PAM configuration already exists"
    fi
    
    # Configure NSS
    if ! grep -q "^passwd:.*oslogin" /etc/nsswitch.conf; then
        sudo sed -i 's/^passwd:.*/passwd:     files oslogin/' /etc/nsswitch.conf
        log_success "NSS configuration updated"
    else
        log "NSS configuration already exists"
    fi
    
    # Configure sudoers
    if [ ! -f /etc/sudoers.d/google-oslogin ]; then
        echo "%google-sudoers ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/google-oslogin
        sudo chmod 0440 /etc/sudoers.d/google-oslogin
        sudo visudo -cf /etc/sudoers.d/google-oslogin || {
            log_error "Sudoers configuration validation failed"
            return 1
        }
        log_success "Sudoers configuration created"
    else
        log "Sudoers configuration already exists"
    fi
    
    # Note: Not restarting SSH by default to avoid disconnection
    log_warning "SSH service not restarted. Restart manually if needed: sudo systemctl restart sshd"
    
    log_success "OS Login configured"
}

# 4. install-security-policy (BARE MINIMUM - won't block SSH or future testing)
install_security_policy() {
    log "Installing role: install-security-policy (bare minimum)..."
    
    # Configure password policy (BARE MINIMUM - only 4 characters minimum)
    PWQUALITY_CONF="/etc/security/pwquality.conf"
    
    # Set minimum password length to 4 (absolute minimum, won't block anything)
    if ! grep -q "^minlen" "$PWQUALITY_CONF" 2>/dev/null; then
        echo "minlen = 4" | sudo tee -a "$PWQUALITY_CONF"
        log_success "Password minimum length set to 4 (bare minimum)"
    else
        log "Password policy already configured"
    fi
    
    # Configure login defs (password expiration - reasonable defaults, won't block)
    if ! grep -q "^PASS_MAX_DAYS" /etc/login.defs; then
        echo "PASS_MAX_DAYS 99999" | sudo tee -a /etc/login.defs
        log_success "Password expiration set to 99999 days (essentially never)"
    else
        # Only update if it's too restrictive
        CURRENT_MAX=$(grep "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
        if [ -n "$CURRENT_MAX" ] && [ "$CURRENT_MAX" -lt 99999 ]; then
            sudo sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 99999/' /etc/login.defs
            log_success "Password expiration updated to 99999 days"
        fi
    fi
    
    if ! grep -q "^PASS_MIN_DAYS" /etc/login.defs; then
        echo "PASS_MIN_DAYS 0" | sudo tee -a /etc/login.defs
    fi
    
    if ! grep -q "^PASS_WARN_AGE" /etc/login.defs; then
        echo "PASS_WARN_AGE 7" | sudo tee -a /etc/login.defs
    fi
    
    # DO NOT TOUCH SSH SETTINGS AT ALL - to avoid blocking access
    log "SSH settings left completely unchanged to avoid blocking access"
    
    log_success "Security policies configured (bare minimum - won't block SSH or testing)"
}

# 5. install-nfs-mount
install_nfs_mount() {
    log "Installing role: install-nfs-mount..."
    
    NFS_EXPORT_DIR="/export/nfs-share"
    NFS_MOUNT_POINT="/mnt/nfs-share"
    
    # Install NFS packages
    if ! rpm -q nfs-utils &>/dev/null; then
        log "Installing NFS packages..."
        sudo yum install -y nfs-utils rpcbind || {
            log_error "Failed to install NFS packages"
            return 1
        }
    else
        log "NFS packages already installed"
    fi
    
    # Set up NFS Server (for testing)
    log "Setting up NFS server for testing..."
    
    # Create export directory
    sudo mkdir -p "$NFS_EXPORT_DIR"
    sudo chmod 755 "$NFS_EXPORT_DIR"
    sudo chown nobody:nobody "$NFS_EXPORT_DIR"
    
    # Create a test file
    echo "This is a test file from NFS server" | sudo tee "$NFS_EXPORT_DIR/test-file.txt" >/dev/null
    sudo chown nobody:nobody "$NFS_EXPORT_DIR/test-file.txt"
    
    # Configure /etc/exports
    if ! grep -q "$NFS_EXPORT_DIR" /etc/exports 2>/dev/null; then
        echo "$NFS_EXPORT_DIR 127.0.0.1(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
        log_success "NFS export configured"
    else
        log "NFS export already configured"
    fi
    
    # Start and enable NFS server services
    sudo systemctl enable rpcbind
    sudo systemctl start rpcbind
    
    sudo systemctl enable nfs-server
    sudo systemctl start nfs-server
    
    # Export the shares
    sudo exportfs -ra
    
    # Wait a moment for services to be ready
    sleep 2
    
    # Install NFS Client
    log "Installing NFS client..."
    
    # Enable and start NFS client services
    sudo systemctl enable rpcbind
    sudo systemctl start rpcbind
    
    sudo systemctl enable nfs-client.target
    sudo systemctl start nfs-client.target
    
    # Create mount point
    sudo mkdir -p "$NFS_MOUNT_POINT"
    sudo chmod 0755 "$NFS_MOUNT_POINT"
    
    # Mount NFS share
    log "Mounting NFS share from localhost..."
    if sudo mount -t nfs -o rw,sync,hard,intr 127.0.0.1:"$NFS_EXPORT_DIR" "$NFS_MOUNT_POINT" 2>/dev/null; then
        log_success "NFS share mounted successfully"
    else
        # Retry after a short wait
        sleep 3
        if sudo mount -t nfs -o rw,sync,hard,intr 127.0.0.1:"$NFS_EXPORT_DIR" "$NFS_MOUNT_POINT"; then
            log_success "NFS share mounted successfully (after retry)"
        else
            log_error "Failed to mount NFS share"
            return 1
        fi
    fi
    
    # Add to /etc/fstab for persistence
    FSTAB_ENTRY="127.0.0.1:$NFS_EXPORT_DIR $NFS_MOUNT_POINT nfs rw,sync,hard,intr 0 0"
    if ! grep -q "$NFS_MOUNT_POINT" /etc/fstab 2>/dev/null; then
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
        log_success "Added to /etc/fstab for persistence"
    else
        log "Entry already exists in /etc/fstab"
    fi
    
    # Verify mount
    if mountpoint -q "$NFS_MOUNT_POINT"; then
        log_success "NFS mount verified"
        df -h "$NFS_MOUNT_POINT" | tee -a "${LOG_FILE}"
    else
        log_error "NFS mount verification failed"
        return 1
    fi
    
    log_success "NFS mount role installed"
}

# 6. install-disk (create, attach, partition, format, mount)
install_disk() {
    log "Installing role: install-disk..."
    
    DISK_NAME="rhel9-roles-test-disk-$(date +%s)"
    DISK_SIZE="2GB"
    MOUNT_POINT="/mnt/data"
    FSTYPE="ext4"
    
    # Check if we're running on the VM or locally
    if curl -H "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/instance/zone >/dev/null 2>&1; then
        # Running on VM - check for attached disk
        log "Running on GCP VM, checking for available disk..."
        
        # Find available disk device (usually /dev/sdb if boot disk is /dev/sda)
        DISK_DEVICE=""
        for dev in /dev/sdb /dev/sdc /dev/sdd; do
            if [ -b "$dev" ] && ! mountpoint -q "$dev" 2>/dev/null; then
                # Check if device has partitions
                if ! lsblk "$dev" | grep -q part; then
                    DISK_DEVICE="$dev"
                    log "Found available disk device: $DISK_DEVICE"
                    break
                fi
            fi
        done
        
        if [ -z "$DISK_DEVICE" ]; then
            log_warning "No available disk device found. You may need to create and attach a disk first."
            log "To create and attach a disk, run this from your local machine:"
            log "  gcloud compute disks create $DISK_NAME --size=$DISK_SIZE --zone=$ZONE --project=$PROJECT_ID"
            log "  gcloud compute instances attach-disk $VM_NAME --disk=$DISK_NAME --zone=$ZONE --project=$PROJECT_ID"
            return 1
        fi
    else
        # Running locally - create and attach disk
        log "Running locally, creating and attaching disk..."
        
        # Create disk
        gcloud compute disks create "$DISK_NAME" \
            --size="$DISK_SIZE" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" || {
            log_error "Failed to create disk"
            return 1
        }
        log_success "Disk created: $DISK_NAME"
        
        # Attach disk to VM
        gcloud compute instances attach-disk "$VM_NAME" \
            --disk="$DISK_NAME" \
            --zone="$ZONE" \
            --project="$PROJECT_ID" || {
            log_error "Failed to attach disk to VM"
            return 1
        }
        log_success "Disk attached to VM"
        
        log_warning "Disk created and attached. Please SSH to VM and run this script again to partition and mount."
        return 0
    fi
    
    # Partition, format, and mount (running on VM)
    log "Partitioning disk: $DISK_DEVICE"
    
    # Create partition table and partition
    sudo parted "$DISK_DEVICE" mklabel gpt || {
        log_error "Failed to create partition table"
        return 1
    }
    
    sudo parted "$DISK_DEVICE" mkpart primary "$FSTYPE" 0% 100% || {
        log_error "Failed to create partition"
        return 1
    }
    
    # Wait a moment for partition to be recognized
    sleep 2
    
    PARTITION="${DISK_DEVICE}1"
    log "Creating filesystem on: $PARTITION"
    
    # Create filesystem
    sudo mkfs -t "$FSTYPE" "$PARTITION" || {
        log_error "Failed to create filesystem"
        return 1
    }
    
    # Create mount point
    sudo mkdir -p "$MOUNT_POINT"
    sudo chmod 0755 "$MOUNT_POINT"
    
    # Mount the disk
    sudo mount -t "$FSTYPE" "$PARTITION" "$MOUNT_POINT" || {
        log_error "Failed to mount disk"
        return 1
    }
    
    # Add to /etc/fstab for persistence
    if ! grep -q "$PARTITION" /etc/fstab; then
        echo "$PARTITION $MOUNT_POINT $FSTYPE defaults 0 2" | sudo tee -a /etc/fstab
        log_success "Added to /etc/fstab for persistence"
    fi
    
    log_success "Disk partitioned, formatted, and mounted at $MOUNT_POINT"
    
    # Show disk info
    df -h "$MOUNT_POINT" | tee -a "${LOG_FILE}"
}

# Main execution
main() {
    echo "=========================================="
    echo "New Role Installation Script"
    echo "VM: ${VM_NAME}"
    echo "Zone: ${ZONE}"
    echo "Project: ${PROJECT_ID}"
    echo "Log file: ${LOG_FILE}"
    echo "=========================================="
    echo ""
    
    # Check if running on GCP VM
    ON_GCP=false
    if curl -H "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/instance/zone >/dev/null 2>&1; then
        ON_GCP=true
        log "Running on GCP VM"
    else
        log_warning "Not running on GCP VM. Some operations will be limited."
    fi
    
    # List of roles to install
    # NOTE: install-security-policy is commented out to avoid SSH blocking issues
    # Uncomment it only if you understand the implications and have serial console access
    ROLES=(
        "install-Home"
        "install-home-dir"
        "install-os-login"
        # "install-security-policy"  # DISABLED - Can block SSH access
        "install-disk"
        "install-nfs-mount"
    )
    
    FAILED_ROLES=()
    
    # Install each role
    VALIDATION_FAILED=()
    for role in "${ROLES[@]}"; do
        INSTALL_SUCCESS=false
        case "${role}" in
            "install-Home")
                if install_home; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-home-dir")
                if install_home_dir; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-os-login")
                if install_os_login; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-security-policy")
                if install_security_policy; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-disk")
                if [[ "$SKIP_DISK" == "true" ]]; then
                    log_warning "Skipping install-disk (--skip-disk flag set)"
                    INSTALL_SUCCESS=true
                elif install_disk; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-metadata")
                if install_metadata; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-pyhton-runtime")
                if install_python_runtime; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-users-group")
                if install_users_group; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-selinux-firewalld")
                if install_selinux_firewalld; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-docker-config")
                if install_docker_config; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-kubectl")
                if install_kubectl; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-nltk-data")
                if install_nltk_data; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-ops-agent-logging")
                if install_ops_agent_logging; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-cleanup")
                if install_cleanup; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            "install-nfs-mount")
                if install_nfs_mount; then
                    log_success "Role ${role} installed successfully"
                    INSTALL_SUCCESS=true
                else
                    log_error "Role ${role} installation failed"
                    FAILED_ROLES+=("${role}")
                fi
                ;;
            *)
                log_error "Unknown role: ${role}"
                FAILED_ROLES+=("${role}")
                ;;
        esac
        
        # Run validation if installation was successful
        if [[ "$INSTALL_SUCCESS" == "true" ]]; then
            echo ""
            if validate_role "${role}"; then
                log_success "Validation PASSED for ${role}"
            else
                log_error "Validation FAILED for ${role}"
                VALIDATION_FAILED+=("${role}")
            fi
        fi
        echo ""
    done
    
    # Summary
    echo "=========================================="
    echo "Installation Summary"
    echo "=========================================="
    echo "Total roles: ${#ROLES[@]}"
    echo "Successfully installed: $((${#ROLES[@]} - ${#FAILED_ROLES[@]}))"
    echo "Installation failed: ${#FAILED_ROLES[@]}"
    echo "Validation failed: ${#VALIDATION_FAILED[@]}"
    echo ""
    
    if [ ${#FAILED_ROLES[@]} -gt 0 ]; then
        echo "Roles that failed to install:"
        for role in "${FAILED_ROLES[@]}"; do
            echo "  ❌ ${role}"
        done
        echo ""
    fi
    
    if [ ${#VALIDATION_FAILED[@]} -gt 0 ]; then
        echo "Roles that failed validation:"
        for role in "${VALIDATION_FAILED[@]}"; do
            echo "  ❌ ${role}"
        done
        echo ""
    fi
    
    if [ ${#FAILED_ROLES[@]} -gt 0 ] || [ ${#VALIDATION_FAILED[@]} -gt 0 ]; then
        log_error "Some roles failed installation or validation. Check log: ${LOG_FILE}"
        exit 1
    else
        echo ""
        log_success "All roles installed and validated successfully!"
        echo "Log file: ${LOG_FILE}"
        exit 0
    fi
}

# Run main function
main "$@"
