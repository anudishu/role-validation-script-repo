#!/bin/bash
# Deployment script for easily installable roles on RHEL 9 GCP VM
# Project: lyfedge-project

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID="lyfedge-project"
LOG_FILE="/tmp/role-installation-$(date +%Y%m%d-%H%M%S).log"

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

# Function to install a role
install_role() {
    local role_name=$1
    log "Installing role: ${role_name}..."
    
    case "${role_name}" in
        "install-metadata")
            install_metadata
            ;;
        "install-pyhton-runtime")
            install_python_runtime
            ;;
        "install-users-group")
            install_users_group
            ;;
        "install-selinux-firewalld")
            install_selinux_firewalld
            ;;
        "install-docker-config")
            install_docker_config
            ;;
        "install-kubectl")
            install_kubectl
            ;;
        "install-nltk-data")
            install_nltk_data
            ;;
        "install-ops-agent-logging")
            install_ops_agent_logging
            ;;
        "install-cleanup")
            install_cleanup
            ;;
        *)
            log_error "Unknown role: ${role_name}"
            return 1
            ;;
    esac
}

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
    
    # RHEL 9 comes with Python 3.9 by default
    # Try to install python38 if available, otherwise use what's available
    PYTHON38_AVAILABLE=false
    PYTHON39_AVAILABLE=false
    
    # Check for Python 3.9 (default on RHEL 9)
    if command_exists python3.9 || [ -f /usr/bin/python3.9 ]; then
        PYTHON39_AVAILABLE=true
        PYTHON39_VER=$(python3.9 --version 2>&1 || /usr/bin/python3.9 --version 2>&1)
    else
        # Try to install python39
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
        # Try to install python38 (may fail on RHEL 9)
        if sudo yum install -y python38 python38-devel 2>/dev/null; then
            PYTHON38_AVAILABLE=true
            PYTHON38_VER=$(python3.8 --version 2>&1)
        else
            log_warning "Python 3.8 not available in repos (this is normal for RHEL 9)"
        fi
    fi
    
    # Verify at least Python 3.9 is available
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
    
    # Create primary group
    if ! getent group dataiku >/dev/null 2>&1; then
        sudo groupadd dataiku || {
            log_error "Failed to create dataiku group"
            return 1
        }
    fi
    
    # Create dataiku user
    if ! id dataiku >/dev/null 2>&1; then
        sudo useradd -g dataiku -m -s /bin/bash dataiku || {
            log_error "Failed to create dataiku user"
            return 1
        }
    fi
    
    # Create secondary group
    if ! getent group dataiku_user_group >/dev/null 2>&1; then
        sudo groupadd -g 1011 dataiku_user_group || {
            log_error "Failed to create dataiku_user_group"
            return 1
        }
    fi
    
    # Create DSS user
    if ! id dataiku_user >/dev/null 2>&1; then
        sudo useradd -g dataiku_user_group -m -s /bin/bash dataiku_user || {
            log_error "Failed to create dataiku_user"
            return 1
        }
    fi
    
    # Configure sudoers
    echo "dataiku ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/dataiku-dss-uf-wrapper >/dev/null
    sudo chmod 440 /etc/sudoers.d/dataiku-dss-uf-wrapper
    
    # Set nofile limit
    echo "dataiku soft nofile 4096" | sudo tee /etc/security/limits.d/90-custom.conf >/dev/null
    sudo chmod 644 /etc/security/limits.d/90-custom.conf
    
    log_success "Users and groups created successfully"
}

# 4. install-selinux-firewalld
install_selinux_firewalld() {
    log "Configuring SELinux and firewalld..."
    
    # Set SELinux to permissive
    sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config
    sudo setenforce 0 || log_warning "Could not set SELinux to permissive (may require reboot)"
    
    # Install firewalld
    if ! rpm -q firewalld >/dev/null 2>&1; then
        sudo yum install -y firewalld || {
            log_error "Failed to install firewalld"
            return 1
        }
    fi
    
    # Enable and start firewalld
    sudo systemctl enable firewalld
    sudo systemctl start firewalld || {
        log_error "Failed to start firewalld"
        return 1
    }
    
    # Open port 10000 (default DSS port)
    sudo firewall-cmd --permanent --add-port=10000/tcp
    sudo firewall-cmd --reload
    
    log_success "SELinux and firewalld configured"
}

# 5. install-docker-config
install_docker_config() {
    log "Installing Docker and creating wrapper..."
    
    # Install prerequisites
    if ! command_exists docker; then
        sudo yum install -y yum-utils || {
            log_error "Failed to install yum-utils"
            return 1
        }
        
        # Add Docker repository
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || {
            log_error "Failed to add Docker repository"
            return 1
        }
        
        # Install Docker
        sudo yum install -y docker-ce docker-ce-cli containerd.io || {
            log_error "Failed to install Docker"
            return 1
        }
    fi
    
    # Create docker-wrapper.py
    sudo tee /usr/local/bin/docker-wrapper.py > /dev/null << 'EOF'
#!/usr/bin/env python3
import subprocess
import sys
subprocess.run(['docker'] + sys.argv[1:])
EOF
    
    sudo chmod +x /usr/local/bin/docker-wrapper.py
    sudo chown root:root /usr/local/bin/docker-wrapper.py
    
    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker || {
        log_error "Failed to start Docker service"
        return 1
    }
    
    # Verify Docker
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
    
    # Download kubectl
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" || {
        log_error "Failed to download kubectl"
        return 1
    }
    
    chmod +x kubectl
    sudo mv kubectl /usr/bin/kubectl
    
    # Verify installation
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
    
    # Install pip if not available
    if ! command_exists pip3; then
        sudo yum install -y python3-pip || {
            log_error "Failed to install python3-pip"
            return 1
        }
    fi
    
    # Install NLTK
    sudo pip3 install nltk || {
        log_error "Failed to install NLTK"
        return 1
    }
    
    # Create NLTK data directory
    sudo mkdir -p /opt/dataiku/nltk_data
    sudo chmod 755 /opt/dataiku/nltk_data
    
    # Download NLTK data packages
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
    
    # Download and install Ops Agent
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh || {
        log_error "Failed to download Ops Agent installer"
        return 1
    }
    
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install || {
        log_error "Failed to install Ops Agent"
        return 1
    }
    
    # Create config directory
    sudo mkdir -p /etc/google-cloud-ops-agent
    
    # Create basic config
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
    
    # Restart Ops Agent
    sudo systemctl restart google-cloud-ops-agent || {
        log_warning "Could not restart Ops Agent (may not be installed)"
    }
    
    # Set timezone
    sudo timedatectl set-timezone America/New_York || log_warning "Could not set timezone"
    
    # Configure SSH settings
    sudo sed -i 's/^#*ClientAliveInterval.*/ClientAliveInterval 86400/' /etc/ssh/sshd_config
    sudo sed -i 's/^#*ClientAliveCountMax.*/ClientAliveCountMax 0/' /etc/ssh/sshd_config
    sudo systemctl restart sshd || log_warning "Could not restart sshd"
    
    log_success "Ops Agent configured"
}

# 9. install-cleanup
install_cleanup() {
    log "Cleaning up system..."
    
    # Install yum-utils if not available
    if ! command_exists package-cleanup; then
        sudo yum install -y yum-utils || {
            log_warning "Could not install yum-utils"
        }
    fi
    
    # Clean up old kernels
    if command_exists package-cleanup; then
        sudo package-cleanup --oldkernels --count=1 -y || {
            log_warning "Could not clean up old kernels"
        }
    fi
    
    # Clean yum cache
    sudo yum clean all || {
        log_warning "Could not clean yum cache"
    }
    
    log_success "System cleanup completed"
}

# Main execution
main() {
    echo "=========================================="
    echo "Role Installation Script"
    echo "Project: ${PROJECT_ID}"
    echo "Log file: ${LOG_FILE}"
    echo "=========================================="
    echo ""
    
    # Check if running on GCP VM
    if ! curl -H "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/instance/zone >/dev/null 2>&1; then
        log_warning "Not running on GCP VM. Some features may not work."
    fi
    
    # List of roles to install
    ROLES=(
        "install-metadata"
        "install-pyhton-runtime"
        "install-users-group"
        "install-selinux-firewalld"
        "install-docker-config"
        "install-kubectl"
        "install-nltk-data"
        "install-ops-agent-logging"
        "install-cleanup"
    )
    
    FAILED_ROLES=()
    
    # Install each role
    for role in "${ROLES[@]}"; do
        if install_role "${role}"; then
            log_success "Role ${role} installed successfully"
        else
            log_error "Role ${role} installation failed"
            FAILED_ROLES+=("${role}")
        fi
        echo ""
    done
    
    # Summary
    echo "=========================================="
    echo "Installation Summary"
    echo "=========================================="
    echo "Total roles: ${#ROLES[@]}"
    echo "Successful: $((${#ROLES[@]} - ${#FAILED_ROLES[@]}))"
    echo "Failed: ${#FAILED_ROLES[@]}"
    
    if [ ${#FAILED_ROLES[@]} -gt 0 ]; then
        echo ""
        echo "Failed roles:"
        for role in "${FAILED_ROLES[@]}"; do
            echo "  - ${role}"
        done
        echo ""
        log_error "Some roles failed to install. Check log: ${LOG_FILE}"
        exit 1
    else
        echo ""
        log_success "All roles installed successfully!"
        echo "Log file: ${LOG_FILE}"
        exit 0
    fi
}

# Run main function
main "$@"

