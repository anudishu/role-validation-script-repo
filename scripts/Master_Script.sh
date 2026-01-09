#!/bin/bash
# ==============================================================================
# CHANGE #1: Fixed shebang (Lines 1-2)
# ==============================================================================
# Master script (under scripts folder validate.sh, global validation)
# Fixed on: January 9, 2026 - Moved comment to proper bash comment format
# ==============================================================================

# Master Runtime Validation Script

# Orchestrates all runtime validation scripts with per-runtime strategy

# Exit Codes: 0 = All validations passed, 1 = One or more validations failed

 

set -euo pipefail

 

# Color codes for output

RED='\033[0;31m'

GREEN='\033[0;32m'

YELLOW='\033[1;33m'

BLUE='\033[0;34m'

PURPLE='\033[0;35m'

CYAN='\033[0;36m'

NC='\033[0m' # No Color

 

# Configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VALIDATION_LOG="${SCRIPT_DIR}/validation_results_$(date +%Y%m%d_%H%M%S).log"

TEMP_DIR="/tmp/validate_all_$$"

 

# ==============================================================================

# REPO_ROOT DETECTION FOR EPHEMERAL VM

# ==============================================================================

REPO_ROOT=""

if [[ -d "/tmp/repo/roles" ]]; then

    # Path used by the startup script on the RHEL9 VM

    REPO_ROOT="/opt/repo"

elif [[ -d "${SCRIPT_DIR}/../../roles" ]]; then

    REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

elif [[ -d "/workspace/roles" ]]; then

    REPO_ROOT="/workspace"

else

    # Search upwards for 'roles' directory

    CURRENT_DIR="${SCRIPT_DIR}"

    while [[ "${CURRENT_DIR}" != "/" ]]; do

        if [[ -d "${CURRENT_DIR}/roles" ]]; then

            REPO_ROOT="${CURRENT_DIR}"

            break

        fi

        CURRENT_DIR="$(dirname "${CURRENT_DIR}")"

    done

fi

# ==============================================================================

 

# Runtime validation scripts - mapped to local repo paths
# ==============================================================================
# CHANGE #2: Added all 9 validation scripts (Lines 105-122)
# ==============================================================================
# Format: "relative_path:Display Name:Emoji:identifier"
# Added on: January 9, 2026
# ==============================================================================

VALIDATION_SCRIPTS=(

    "roles/install-metadata/validation/validate.sh:Metadata Access:📡:metadata"

    "roles/install-users-group/validation/validate.sh:Users and Groups:👥:users"

    "roles/install-selinux-firewalld/validation/validate.sh:SELinux and Firewalld:🔒:selinux"

    "roles/install-docker-config/validation/validate.sh:Docker Configuration:🐳:docker"

    "roles/install-kubectl/validation/validate.sh:Kubectl:☸️:kubectl"

    "roles/install-nltk-data/validation/validate.sh:NLTK Data:📚:nltk"

    "roles/install-ops-agent-logging/validation/validate.sh:Ops Agent Logging:📊:ops-agent"

    "roles/install-cleanup/validation/validate.sh:System Cleanup:🧹:cleanup"

    "roles/install-pyhton-runtime/validation/validate.sh:Python Runtime:🐍:python"

)

 

# Logging functions

log_info() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$VALIDATION_LOG"; }

log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$VALIDATION_LOG"; }

log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$VALIDATION_LOG"; }

log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$VALIDATION_LOG"; }

log_step() {

    echo -e "\n${CYAN}======================================${NC}" | tee -a "$VALIDATION_LOG"

    echo -e "${CYAN}$1${NC}" | tee -a "$VALIDATION_LOG"

    echo -e "${CYAN}======================================${NC}" | tee -a "$VALIDATION_LOG"

}

 

# ==============================================================================

# ARGUMENT PARSING (Handles --verbose flag from Startup Script)

# ==============================================================================

parse_arguments() {

    VERBOSE=false

    CONTINUE_ON_FAILURE=false

    SKIP_SETUP=false

 

    while [[ $# -gt 0 ]]; do

        case $1 in

            -v|--verbose) VERBOSE=true; shift ;;

            -c|--continue) CONTINUE_ON_FAILURE=true; shift ;;

            --skip-setup) SKIP_SETUP=true; shift ;;

            *) shift ;; # Ignore unknown for compatibility

        esac

    done

 

    if [[ "$VERBOSE" == "true" ]]; then

        log_info "Verbose mode enabled."

        set -x # Enable shell trace for deep debugging

    fi

}

# ==============================================================================

 

setup_environment() {

    if [[ "${SKIP_SETUP:-false}" == "true" ]]; then return 0; fi

    mkdir -p "$TEMP_DIR"

   

    if [[ -z "${REPO_ROOT}" ]]; then

        log_error "CRITICAL: Could not determine REPO_ROOT. Ensure 'roles' folder exists."

        return 1

    fi

   

    log_info "Detected Repository Root: ${REPO_ROOT}"

 

    local missing_count=0

    for script_info in "${VALIDATION_SCRIPTS[@]}"; do

        local rel_path=$(echo "$script_info" | cut -d: -f1)

        if [[ ! -f "${REPO_ROOT}/${rel_path}" ]]; then

            log_error "Validation script not found: ${REPO_ROOT}/${rel_path}"

            ((missing_count++))

        fi

    done

 

    if [[ $missing_count -gt 0 ]]; then

        log_error "Missing $missing_count validation script(s). Aborting."

        return 1

    fi

    return 0

}

 

cleanup() {

    if [[ -d "$TEMP_DIR" ]]; then rm -rf "$TEMP_DIR"; fi

}

trap cleanup EXIT

 

run_validation() {

    local relative_path="$1"

    local runtime_name="$2"

    local emoji="$3"

    local validation_script="${REPO_ROOT}/${relative_path}"

    local runtime_lower=$(echo "$runtime_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

    local output_file="$TEMP_DIR/${runtime_lower}_validation.log"

   

    log_step "$emoji $runtime_name Validation"

    chmod +x "$validation_script"

   

    local exit_code=0

    # Execute and capture logs

    if "$validation_script" > "$output_file" 2>&1; then

        exit_code=0

        log_success "$emoji $runtime_name validation PASSED"

    else

        exit_code=$?

        log_error "$emoji $runtime_name validation FAILED (Exit: $exit_code)"

        cat "$output_file" | tee -a "$VALIDATION_LOG"

    fi

    return $exit_code

}

 

run_per_runtime_validation() {

    local failed=0

    for script_info in "${VALIDATION_SCRIPTS[@]}"; do

        local relative_path=$(echo "$script_info" | cut -d: -f1)

        local runtime_name=$(echo "$script_info" | cut -d: -f2)

        local emoji=$(echo "$script_info" | cut -d: -f3)

       

        if ! run_validation "$relative_path" "$runtime_name" "$emoji"; then

            failed=1

            [[ "${CONTINUE_ON_FAILURE:-false}" != "true" ]] && break

        fi

    done

    return $failed

}

 

# ==============================================================================

# MAIN EXECUTION WITH FINAL SIGNALING

# ==============================================================================

main() {

    parse_arguments "$@"

   

    if ! setup_environment; then

        echo "RUNTIME_VALIDATION_RESULT=Fail"

        sync && sleep 5

        exit 1

    fi

 

    local validation_result=0

    run_per_runtime_validation || validation_result=$?

   

    echo -e "\n--- FINAL VALIDATION SUMMARY ---"

    if [[ $validation_result -eq 0 ]]; then

        log_success "🎉 ALL VALIDATIONS PASSED"

        echo "RUNTIME_VALIDATION_RESULT=Pass"

    else

        log_error "❌ VALIDATION FAILED"

        echo "RUNTIME_VALIDATION_RESULT=Fail"

    fi

   

    # Critical: Ensure serial console captures the Pass/Fail string before VM deletion

    sync

    sleep 10

    return $validation_result

}

 

main "$@"

# ==============================================================================
# CHANGE #3: Fixed syntax error (Lines 403-407)
# ==============================================================================
# STARTUP SCRIPT (Validate_ephemeral.sh) Rhel-9 under pipelines folder
# This section is for reference only - not executed as part of validate.sh
# Fixed on: January 9, 2026 - Commented out uncommented text that caused syntax error
# ==============================================================================

# #!/usr/bin/env bash

# Hardened for RHEL9 - Bypassing /tmp restrictions

set -u

set -x

 

VALIDATION_LOG="/var/log/runtime-validation.log"

REPO_ROOT="/opt/repo"  # Changed from /tmp to /opt for RHEL9 compatibility

 

log() { echo "[$(date -Is)] $*" | tee -a "${VALIDATION_LOG}"; }

 

echo "RUNTIME_VALIDATION_STATUS=STARTED"

 

# 1. Wait for Network Connectivity

log "Waiting for network..."

until curl -s -I http://www.google.com | grep "200 OK" > /dev/null; do

  sleep 5

done

 

# 2. Clean and Create Directory in /opt

log "Preparing workspace in ${REPO_ROOT}..."

rm -rf "${REPO_ROOT}"

mkdir -p "${REPO_ROOT}"

chmod 777 "${REPO_ROOT}"

 

# 3. Fetch Metadata and Auth (Verified working)

log "Fetching credentials..."

METADATA_URL="http://metadata.google.internal/computeMetadata/v1"

H_FLAVOR="Metadata-Flavor: Google"

 

REPO_URL_RAW=$(curl -s "${METADATA_URL}/instance/attributes/repo-url" -H "${H_FLAVOR}")

REPO_BRANCH=$(curl -s "${METADATA_URL}/instance/attributes/repo-branch" -H "${H_FLAVOR}" || echo "master")

ACCESS_TOKEN=$(curl -s "${METADATA_URL}/instance/service-accounts/default/token" -H "${H_FLAVOR}" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

 

REPO_URL_AUTH="${REPO_URL_RAW/https:\/\//https:\/\/oauth2:${ACCESS_TOKEN}@}"

 

# 4. Clone into /opt/repo

log "Cloning repository..."

if git clone -b "${REPO_BRANCH}" "${REPO_URL_AUTH}" "${REPO_ROOT}" 2>&1 | tee -a "${VALIDATION_LOG}"; then

    log "Clone Success."

else

    log "Clone Failed."

    echo "RUNTIME_VALIDATION_RESULT=Fail"

    exit 1

fi

 

# 5. Execute Masterscript

VALIDATION_SCRIPT="${REPO_ROOT}/scripts/validate.sh"

if [[ -f "${VALIDATION_SCRIPT}" ]]; then

    chmod +x "${VALIDATION_SCRIPT}"

    log "Executing: ${VALIDATION_SCRIPT}"

    /usr/bin/bash "${VALIDATION_SCRIPT}" --verbose 2>&1 | tee -a "${VALIDATION_LOG}"

    VALIDATION_EXIT_CODE=${PIPESTATUS[0]}

else

    log "Error: Masterscript not found at ${VALIDATION_SCRIPT}"

    VALIDATION_EXIT_CODE=1

fi

 

# 6. Final Status

if [ $VALIDATION_EXIT_CODE -eq 0 ]; then

    echo "RUNTIME_VALIDATION_RESULT=Pass"

else

    echo "RUNTIME_VALIDATION_RESULT=Fail"

fi

 

sync

sleep 10

 

dataiku-v13-startup-script(this is what client gave but we are not using this as startup script, the logic from this script is being converted in to ansible roles – so this is not useful for us I believe )
#!/bin/bash

# Name:         dataiku-startup-script.sh == DSS 13

# Description:  Startup script to be run Google startup service for GCE instances

# Author:       Jim Sasser

# Date:         12/16/2025

# Updates:      New version with additional logging and optimizations

#               Added setup for python keyring files and custom DSS script

# -------------------------------------------------------------------------------

# Variable Setup

# ------------------------------------------------------------------------------

STARTUP_BUCKET_NAME=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/STARTUP_BUCKET -H "Metadata-Flavor: Google")

GCP_PROJECT=`curl http://metadata.google.internal/computeMetadata/v1/project/project-id -H Metadata-Flavor:Google`

USER="dataiku"

OPT_DATAIKU="/opt/dataiku"

DSS_USER="dataiku_user"

GROUP_USERS="dataiku_user_group"

DSS_VERSION="13.5.7" # For new installs only

SPARK_VERSION="3.5.3" # For new installs only

ZONE=`uname -n | awk -F- '{print $(NF-1), $NF}' | sed 's/ /-/g'`

DSS_NODE=`uname -n | awk -F- '{print $2}'`

if [[ ${DSS_NODE} = "auto" ]]

then

   DSS_NODE="automation"

fi

DSS_INSTALLDIR="${OPT_DATAIKU}/installation"

DSS_BACKUP_DIR="${OPT_DATAIKU}/backups"

DSS_BACKUP_SCRIPT_DIR="${OPT_DATAIKU}/backup_scripts"

DEST_DIR=/tmp/install-packages

DEPEND_DIR=${DEST_DIR}/dataiku-pkgs/dependencies

DSS_PORT=$dssPORT

DSS_LICENSE="${OPT_DATAIKU}/installation/License-mark.greene@schwab.com-2025-12-31.json"

DSS_ENV=`echo ${GCP_PROJECT} | cut '-d-' -f4 | rev | cut -c5- | rev`

 

# Marker file for tracking SELinux reboot (on boot disk, ephemeral)

SELINUX_MARKER="/var/lib/selinux-configured"

SETUP_COMPLETE_MARKER="/var/lib/dataiku-setup-complete"

 

# Create output directory for logs

OUTDIR=/tmp/init-script-out

mkdir -p ${OUTDIR}

 

# Logging functions for better troubleshooting

LOG_FILE="${OUTDIR}/startup-script.log"

log_error() { echo "[ ERROR ] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}" >&2; }

log_info() { echo " [ INFO ] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"; }

log_warn() { echo " [ WARN ] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"; }

 

# Retry function for GCS operations with exponential backoff

retry_gsutil() {

  local max_attempts=3 attempt=1 delay=5

  while [ $attempt -le $max_attempts ]; do

    if "$@"; then return 0; fi

    [ $attempt -eq $max_attempts ] && { log_error "Command failed after $max_attempts attempts: $*"; return 1; }

    log_warn "Attempt $attempt failed, retrying in ${delay}s: $*"

    sleep $delay; delay=$((delay * 2)); attempt=$((attempt + 1))

  done

}

 

# Wait for disk/device with timeout

wait_for_disk() {

  local disk=$1 timeout=${2:-30} count=0

  while [ $count -lt $timeout ]; do

    [[ -L $disk ]] && { log_info "Disk $disk available"; return 0; }

    log_info "Waiting for $disk... ($count/$timeout)"

    sleep 2; count=$((count + 1))

  done

  log_error "Timeout waiting for $disk"; return 1

}

 

# Configure firewalld with trusted zone

configure_firewalld() {

  log_info "Configuring firewalld"

 

  # Check if firewalld is already configured

  if systemctl is-active --quiet firewalld && grep -q "trusted" /etc/firewalld/firewalld.conf 2>/dev/null; then

    log_info "Firewalld already configured and running"

    return 0

  fi

 

  # Install firewalld if not present

  if ! rpm -q firewalld >/dev/null 2>&1; then

    yum -y --disablerepo=rhui* install --disablerepo=goog* --enablerepo=Char* firewalld || { log_error "Failed to install firewalld"; return 1; }

  fi

 

  systemctl stop firewalld

 

  # Configure firewalld to use trusted zone

  if [ -f /etc/firewalld/firewalld.conf.old ]; then

    cp /etc/firewalld/firewalld.conf.old /etc/firewalld/firewalld.conf

  fi

  sed -i 's/public/trusted/g' /etc/firewalld/firewalld.conf

 

  systemctl unmask firewalld && systemctl start firewalld || { log_error "Failed to start firewalld"; return 1; }

  log_info "Firewalld configured successfully"

}

 

# Create local users/groups and update sudoers

create_local_groups ()

{

  log_info "Creating local users and groups"

 

  # Create user and groups only if they don't exist (commands fail gracefully if they exist)

  id -u dataiku >/dev/null 2>&1 || useradd dataiku -s /bin/bash -p '*' || return 1

  getent group dataiku >/dev/null 2>&1 || groupadd dataiku -g 1010 || return 1

  usermod --append --groups dataiku dataiku

  getent group dataiku_user_group >/dev/null 2>&1 || groupadd dataiku_user_group -g 1011 || return 1

  id -u dataiku_user >/dev/null 2>&1 || useradd dataiku_user -s /bin/bash -p '*' || return 1

  usermod --append --groups dataiku_user_group dataiku_user

 

  chown ${USER}:${USER} /home/${USER}/.bashrc /home/${USER}/.bash_profile &&\

  chmod 750 /home/${USER}/.bash_profile /home/${USER}/.bashrc || return 1

 

  [ -f /etc/sudoers.d/dataiku-dss-uif-wrapper ] || \

    echo "dataiku ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dataiku-dss-uif-wrapper

 

  echo "  # Added increase in open files for dss user

  dataiku soft nofile 4096" | sudo tee /etc/security/limits.d/90-custom.conf > /dev/null

 

  log_info "Local users and groups created successfully"

}

 

# Create filesystem on persistent disk, if needed, and mount

persistent_disk ()

{

   log_info "Setting up persistent disk mount"

   local MOUNTDIR="/opt/dataiku" DISK1=disk/by-id/google-dataikudir

 

   wait_for_disk "/dev/$DISK1" 30 || return 1

 

   local UUID_VALUE=$(sudo blkid /dev/$DISK1 -o value -s UUID | head -n 1)

   [[ -z ${UUID_VALUE} ]] && { log_error "Could not get UUID for disk"; return 1; }

 

   mount | grep -q "$MOUNTDIR" && { log_info "$MOUNTDIR already mounted"; return 0; }

 

   sudo mkdir -p $MOUNTDIR

   if ! grep -q $UUID_VALUE /etc/fstab; then

     sudo mount -o discard,defaults /dev/$DISK1 $MOUNTDIR || return 1

     sudo chmod a+w $MOUNTDIR

     sudo cp /etc/fstab /etc/fstab.backup

     echo "UUID=$UUID_VALUE $MOUNTDIR ext4 discard,defaults,nofail 0 2" | sudo tee -a /etc/fstab

     log_info "Persistent disk mounted at $MOUNTDIR"

   else

     sudo mount $MOUNTDIR || return 1

     log_info "Mounted $MOUNTDIR from fstab"

   fi

}

 

mount_shared_resources ()

{

   ## Mount /opt/shared_resources if it exists on the automation nodes and assuming it is 100GB in size

 

 

 

   log_info "Mounting shared resources"

   MOUNTDIR="/opt/shared_resources"

 

   if [ `uname -n | awk -F- '{print $2}'` != govern ] && [ `uname -n | awk -F- '{print $2}'` != api ]

   then

     # Check if already mounted

     if mount | grep -q "$MOUNTDIR"; then

       log_info "$MOUNTDIR already mounted"

       systemctl daemon-reload

       return 0

     fi

 

     if [ ! -d ${MOUNTDIR} ]

     then

       sudo mkdir -p /opt/shared_resources

       sudo chown ${USER}:${USER} /opt/shared_resources

       SR_DISK=`fdisk -l | grep -v sda | grep "100 GiB" | awk '{print $2}' | sed -e 's/://g'`

       if [[ -n ${SR_DISK}  ]]

       then

          UUID_VALUE=`sudo blkid ${SR_DISK} -o value -s UUID | head -n 1`

          sudo mount -o discard,defaults ${SR_DISK} ${MOUNTDIR} || { log_error "Failed to mount shared resources"; return 1; }

          echo "UUID=${UUID_VALUE} ${MOUNTDIR} ext4 discard,defaults,nofail 0 2" | sudo tee -a /etc/fstab > /dev/null

          log_info "Shared resources mounted from existing disk"

       elif [[ ! -L /dev/disk/by-id/google-shared-resdir ]]

       then

          DISKNAME=`uname -n | rev | cut -d'-' -f2- | rev | sed 's/automation/auto/g' | sed 's/-ce/-sr-ce/g'`

          log_info "Attaching shared resources disk: ${DISKNAME}"

          gcloud compute instances attach-disk `uname -n` --project=${GCP_PROJECT} --zone=us-${ZONE} --disk=${DISKNAME} --disk-scope=regional --device-name="shared-resdir" || { log_error "Failed to attach shared-resdir"; return 1; }

 

          # Wait for disk link to appear (up to 60 seconds)

          local wait_count=0

          while [ $wait_count -lt 30 ]; do

            if [[ -L /dev/disk/by-id/google-shared-resdir ]]; then

              log_info "Shared resources disk link appeared"

              break

            fi

            log_info "Waiting for shared-resdir disk attachment... ($wait_count/30)"

            sleep 2

            wait_count=$((wait_count + 1))

          done

 

          if [[ ! -L /dev/disk/by-id/google-shared-resdir ]]; then

            log_error "Timeout waiting for shared-resdir disk attachment"

            return 1

          fi

 

          LINK_TARGET=$(readlink /dev/disk/by-id/google-shared-resdir)

          TEMP=$(basename "$LINK_TARGET")

          NEW_DISK_DEVICE_PATH="/dev/$TEMP"

          UUID_VALUE=`sudo blkid ${NEW_DISK_DEVICE_PATH} -o value -s UUID | head -n 1`

          sudo mount -o discard,defaults ${NEW_DISK_DEVICE_PATH} ${MOUNTDIR} || { log_error "Failed to mount ${NEW_DISK_DEVICE_PATH}"; return 1; }

          echo "UUID=${UUID_VALUE} ${MOUNTDIR} ext4 discard,defaults,nofail 0 2" | sudo tee -a /etc/fstab > /dev/null

          log_info "Shared resources disk attached and mounted successfully"

       fi

     fi

   fi

   systemctl daemon-reload

   return 0

}

 

# Downloading packages from GCS bucket

package_download ()

{

    log_info "Downloading packages from GCS"

    local RPM_BUCKET="gs://${STARTUP_BUCKET_NAME}/compute-startup-scripts/packages"

    local PKG_DIR="${DEST_DIR}/dataiku-pkgs"

 

    # Check if packages already downloaded (filesystem-based check)

    if [[ -d "$PKG_DIR" ]]; then

      log_info "Packages already exist at $PKG_DIR, skipping download"

      return 0

    fi

 

    mkdir -p "$PKG_DIR" || { log_error "Failed to create $PKG_DIR"; return 1; }

 

    retry_gsutil gsutil -m cp -r ${RPM_BUCKET}/rpm-repo.tar ${DEST_DIR} || return 1

    retry_gsutil gsutil -m cp -r ${RPM_BUCKET}/dataiku-pkgs/v13/* "$PKG_DIR/" || return 1

    retry_gsutil gsutil -m cp ${RPM_BUCKET}/yum-setup.tar /tmp || return 1

 

    (cd / && cp /tmp/yum-setup.tar . && tar -xvf yum-setup.tar) || { log_error "Failed to extract yum-setup.tar"; return 1; }

    (cd ${DEST_DIR} && tar -xvf rpm-repo.tar) || { log_error "Failed to extract rpm-repo.tar"; return 1; }

    (cd "$PKG_DIR" && tar -xvf dependencies.tar) || { log_error "Failed to extract dependencies.tar"; return 1; }

 

    log_info "Package download completed successfully"

}

 

 

# Install rpm packages as needed

rpm_package_install ()

{

    log_info "Installing RPM packages"

 

    cat > /etc/yum.repos.d/local.repo << 'EOF'

[local]

name=GCP local repo

baseurl=file:///tmp/install-packages/rpm-repo

enabled=1

gpgcheck=0

module_hotfixes=1

EOF

 

    # YUM automatically skips already-installed packages

    yum -y --disablerepo=rhui* --disablerepo=goog* --enablerepo=Char* --allowerasing --skip-broken install \

    git unzip zip createrepo drpm ncurses-compat-libs java-1.8.0-openjdk java-17-openjdk-headless \

    libgfortran libicu-devel libcurl-devel gtk3 libXScrnSaver openssl-devel openssl mesa-libgbm \

    libX11-xcb gcc bzip2-devel libffi-devel zlib-devel xz-devel make wget gcc-c++ jq nc yum-utils \

    sqlite-devel kubectl policycoreutils-python-utils libpq-devel postgresql nginx nodejs rsync libcgroup libcgroup-tools \

    google-cloud-cli-gke-gcloud-auth-plugin @development gdbm-devel libuuid-devel ncurses-devel python39 \

    readline-devel dejavu-sans-fonts > ${OUTDIR}/yum.out 2>&1 || { log_error "YUM install failed - check ${OUTDIR}/yum.out"; return 1; }

 

    log_info "RPM packages installed successfully"

}

 

misc_setup ()

{

    log_info "Running miscellaneous setup tasks"

 

    # Install Python from source tarballs (3.10, 3.11) - no RHEL Python binaries are used

    # Only python3-devel, python3.10-devel, python3.11-devel are installed for headers

    # Python binaries are installed to /usr/local/bin via make altinstall

    cd /usr/local/bin

    cp ${DEST_DIR}/dataiku-pkgs/python-envs.tar.gz . && tar -xvf python-envs.tar.gz && rm python-envs.tar.gz

    cp ${DEST_DIR}/dataiku-pkgs/Python-3.*.tgz .

 

    # Capture tarball list before extraction (needed for build loop)

    local PYTHON_TARBALLS=($(ls Python-3.*.tgz 2>/dev/null))

 

    if [ ${#PYTHON_TARBALLS[@]} -eq 0 ]; then

      log_error "No Python tarballs found in ${DEST_DIR}/dataiku-pkgs/"

      return 1

    fi

 

    log_info "Starting parallel Python compilation for: ${PYTHON_TARBALLS[*]}"

    log_info "Build logs will be written to: ${OUTDIR}/Python-*.{configure,make,install}.out"

 

    # Extract all tarballs and derive directory names

    local PYTHON_DIRS=()

    for tarfile in "${PYTHON_TARBALLS[@]}"; do

      local dir_name=${tarfile%.tgz}

      tar xvf "$tarfile" && rm "$tarfile"

      PYTHON_DIRS+=("$dir_name")

    done

 

    # Phase 1: Configure and compile in parallel (CPU-intensive, no file conflicts)

    log_info "Phase 1: Configuring and compiling Python versions in parallel..."

    local pids=()

    local -A pid_to_version  # Map PID to Python version for error reporting

 

    for PYTHON_DIR in "${PYTHON_DIRS[@]}"; do

      (

        # Redirect all output to per-build log files to avoid interleaving

        exec > ${OUTDIR}/${PYTHON_DIR}.build.log 2>&1

 

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting build for ${PYTHON_DIR}"

        cd "${PYTHON_DIR}" || exit 1

 

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running configure..."

        LD_RUN_PATH=/usr/lib ./configure --enable-ipv6 --enable-optimizations --enable-loadable-sqlite-extensions > ${OUTDIR}/${PYTHON_DIR}.configure.out 2>&1 || exit 1

 

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running make (this may take several minutes)..."

        LD_RUN_PATH=/usr/lib make -j$(nproc) > ${OUTDIR}/${PYTHON_DIR}.make.out 2>&1 || exit 1

 

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Compilation completed for ${PYTHON_DIR}"

      ) &

      local pid=$!

      pids+=($pid)

      pid_to_version[$pid]=$PYTHON_DIR

      log_info "Started build for ${PYTHON_DIR} (PID: $pid)"

    done

 

    # Wait for all builds to complete and check for failures

    log_info "Waiting for ${#pids[@]} Python build(s) to complete..."

    local failed=0

    local failed_versions=()

 

    for pid in "${pids[@]}"; do

      if wait $pid; then

        log_info "Build completed successfully: ${pid_to_version[$pid]} (PID: $pid)"

      else

        log_error "Build FAILED: ${pid_to_version[$pid]} (PID: $pid) - check ${OUTDIR}/${pid_to_version[$pid]}.build.log"

        failed=1

        failed_versions+=("${pid_to_version[$pid]}")

      fi

    done

 

    if [ $failed -eq 1 ]; then

      log_error "Python build failures: ${failed_versions[*]}"

      log_error "Check individual build logs in ${OUTDIR}/ for details"

      return 1

    fi

 

    # Phase 2: Install serially to avoid race conditions on shared /usr/local/bin

    log_info "Phase 2: Installing Python versions serially to avoid file conflicts..."

    for PYTHON_DIR in "${PYTHON_DIRS[@]}"; do

      log_info "Installing ${PYTHON_DIR}..."

      (

        cd "${PYTHON_DIR}" || exit 1

        LD_RUN_PATH=/usr/lib make altinstall > ${OUTDIR}/${PYTHON_DIR}.install.out 2>&1

      ) || { log_error "Installation failed for ${PYTHON_DIR}"; return 1; }

      log_info "${PYTHON_DIR} installed successfully"

    done

 

    log_info "All Python versions installed successfully to /usr/local/bin/"

    cd /usr/local/bin

 

    # Setup NLTK data

    mkdir -p /usr/local/share/nltk_data/corpora/ && chmod -R 755 /usr/local/share/nltk_data/corpora

    cp $DEST_DIR/dataiku-pkgs/stopwords.zip /usr/local/share/nltk_data/corpora/

    (cd /usr/local/share/nltk_data/corpora && unzip -o stopwords.zip && find stopwords/ -type f -not -name 'english' -delete && rm stopwords.zip)

 

    # Update certificates

    retry_gsutil gsutil cp gs://${STARTUP_BUCKET_NAME}/compute-startup-scripts/certs/* /etc/pki/ca-trust/source/anchors || return 1

    /usr/bin/update-ca-trust extract || { log_error "Failed to update CA trust"; return 1; }

 

    log_info "Miscellaneous setup completed successfully"

}

 

update_selinux ()

{

   log_info "Checking SELinux configuration"

 

   # Check if we've completed SELinux update and reboot cycle

   if [ -f "${SELINUX_MARKER}" ]; then

     log_info "SELinux already configured and system rebooted"

     configure_firewalld || return 1

     return 0

   fi

 

   if ! grep -q "SELINUX=permissive" /etc/selinux/config; then

     log_info "SELinux is in enforcing mode, changing to permissive"

     sed -i "s/=enforcing/=permissive/g" /etc/selinux/config || { log_error "Failed to update SELinux config"; return 1; }

     touch "${SELINUX_MARKER}" || log_warn "Failed to create SELinux marker file"

     log_info "SELinux configuration updated, attaching drive and rebooting"

     attach_drive || log_warn "Drive attachment failed, but continuing with reboot"

     reboot

   else

     log_info "SELinux already in permissive mode"

     touch "${SELINUX_MARKER}" || log_warn "Failed to create SELinux marker file"

     configure_firewalld || return 1

   fi

}

 

attach_drive ()

{

   log_info "Checking if drive needs to be attached"

 

   # Only attach drive for specific zone

   if [[ ${ZONE} != "central1-a" ]]; then

     log_info "Zone is not central1-a, skipping drive attachment"

     return 0

   fi

 

   local DISKNAME=$(uname -n | rev | cut -d'-' -f2- | rev)

 

   if [[ -L /dev/disk/by-id/google-dataikudir ]]; then

     log_info "Dataiku disk already attached"

     return 0

   fi

 

   log_info "Attaching dataiku disk: ${DISKNAME}"

   cp $DEPEND_DIR/sae-keys/$DSS_ENV/* /root/ || { log_error "Failed to copy service account keys"; return 1; }

   gcloud auth activate-service-account --key-file=/root/${DSS_ENV}.json || { log_error "Failed to activate service account"; return 1; }

   gcloud compute instances attach-disk `uname -n` --project=${GCP_PROJECT} --zone=us-${ZONE} --disk=${DISKNAME} --disk-scope=regional --device-name="dataikudir" || { log_error "Failed to attach disk ${DISKNAME}"; return 1; }

 

   wait_for_disk "/dev/disk/by-id/google-dataikudir" 30 || { log_error "Timeout waiting for disk ${DISKNAME} to attach"; return 1; }

   log_info "Disk ${DISKNAME} attached successfully"

}

 

kubectl_setup ()

{

   log_info "Setting up kubectl configuration"

 

   local GCP_REGION=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/zone -H Metadata-Flavor:Google | cut '-d/' -f4 | cut '-d-' -f1,2)

   local GKE_REGION=$([[ ${GCP_REGION} = "us-west1" ]] && echo "usw1" || echo "usc1")

   local GKE_CLUSTER=$(retry_gsutil gsutil cat gs://${STARTUP_BUCKET_NAME}/compute-startup-scripts/k8s_proxy_url.txt | grep ${GKE_REGION})

   local GKE_CLUSTER_NAME=$(echo ${GKE_CLUSTER} | awk '{print $2}')

   local K8S_PROXY_IP=$(echo ${GKE_CLUSTER} | awk '{print $1}')

   local K8S_PROXY_URL="http://${K8S_PROXY_IP}:443"

 

   su - dataiku -c "gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region ${GCP_REGION} --project ${GCP_PROJECT}" || return 1

   su - dataiku -c "kubectl config set clusters.gke_${GCP_PROJECT}_${GCP_REGION}_${GKE_CLUSTER_NAME}.proxy-url ${K8S_PROXY_URL}" || return 1

 

   log_info "kubectl configuration completed successfully"

}

 

qualys_install ()

{

   log_info "Installing Qualys cloud agent"

 

   # YUM will skip if already installed

   yum -y --disablerepo=rhui* install --disablerepo=goog* --enablerepo=Char* qualys-cloud-agent

   sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh ActivationId=354e6a95-e887-47db-b4a3-cf32e21c57d4 CustomerId=9c0e25d4-d91f-5af6-e040-10ac13043f6a || log_warn "Qualys activation failed, continuing anyway"

 

   # Ensure hostid is carried over from previous install (stored in GCS, survives instance recreation)

   retry_gsutil gcloud storage cp gs://${STARTUP_BUCKET_NAME}/instance-config-files/`uname -n`/hostid /tmp/hostid

   if [ ! -f /tmp/hostid ] || [ ! -s /tmp/hostid ]; then

      systemctl restart qualys-cloud-agent.service && sleep 15

      retry_gsutil gcloud storage cp /etc/qualys/hostid gs://${STARTUP_BUCKET_NAME}/instance-config-files/`uname -n`/hostid || log_warn "Failed to backup qualys hostid"

   else

      cp /tmp/hostid /etc/qualys/hostid && systemctl restart qualys-cloud-agent.service

   fi

 

   log_info "Qualys installation completed"

}

 

docker_config ()

{

   log_info "Configuring Docker wrapper"

 

   # elasticAI is on persistent disk (/opt/dataiku), always ensure it exists and download files

   mkdir -p ${DSS_INSTALLDIR}/elasticAI || { log_error "Failed to create elasticAI directory"; return 1; }

   retry_gsutil gsutil -m cp gs://${STARTUP_BUCKET_NAME}/scripts/* ${DSS_INSTALLDIR}/elasticAI || return 1

   chown ${USER}:${USER} ${DSS_INSTALLDIR}/elasticAI/*

 

   # Always copy wrapper to /usr/bin (boot disk, ephemeral)

   cp ${DSS_INSTALLDIR}/elasticAI/docker-wrapper.py /usr/bin/docker || return 1

   chmod 755 /usr/bin/docker

   log_info "Docker wrapper configured successfully"

}

 

systemctl_dataiku ()

{

   log_info "Setting up systemctl for Dataiku"

 

   retry_gsutil gsutil cp gs://${STARTUP_BUCKET_NAME}/compute-startup-scripts/scripts/add_systemctl_dss.sh /tmp || return 1

   chmod 755 /tmp/add_systemctl_dss.sh && sh -vx /tmp/add_systemctl_dss.sh || { log_error "Failed to execute add_systemctl_dss.sh"; return 1; }

 

   log_info "Systemctl configuration completed successfully"

}

 

# Cleanup/remove extra kernels, enhance logging and update crontab

cleanup_and_logging ()

{

    log_info "Running cleanup and logging configuration"

 

    # Remove old kernels

    OLD_KERNEL=`rpm -q kernel | sort -r | grep -v $(uname -r)`

    if [ `echo $OLD_KERNEL | wc -w` -ne 0 ]; then

      for kernel in $OLD_KERNEL; do

        rpm -e $kernel || log_warn "Failed to remove kernel: $kernel"

      done

      log_info "Old kernels removed"

    fi

 

    # Add config for Cloud Ops Agent for logging

    sudo cat << EOF > /etc/google-cloud-ops-agent/config.yaml

global:

  default_self_log_file_collection: false

 

 

logging:

  receivers:

    dataiku-audit:

      type: files

      include_paths:

      - /opt/dataiku/*/run/audit/audit.log

    dataiku-backend:

      type: files

      include_paths:

      - /opt/dataiku/*/run/backend.log

      - /opt/dataiku/*/run/governserver.log

    dataiku-unified-monitoring:

      type: files

      include_paths:

      - /opt/dataiku/*/run/unified-monitoring/unified-monitoring.log

    dataiku-frontend:

      type: files

      include_paths:

      - /opt/dataiku/*/run/frontend.log.0

    dataiku-ipython:

      type: files

      include_paths:

      - /opt/dataiku/*/run/ipython.log

    dataiku-nginx:

      type: files

      include_paths:

      - /opt/dataiku/*/run/nginx.log

    dataiku-nginx-access:

      type: files

      include_paths:

      - /opt/dataiku/*/run/nginx/access.log

  processors:

    dataiku-parse-audit:

      type: parse_json

      time_key: timestamp

      time_format: "%Y-%m-%dT%H:%M:%S.%L%z" # 2025-04-15T14:45:06.282-0400

      field: message

    move-severity:

      type: modify_fields

      fields:

        severity:

          move_from: jsonPayload.severity

    parse-java-multiline:

      type: parse_multiline

      match_any:

        - type: language_exceptions

          language: java

    extract-dataiku-java-log-format:

      type: parse_regex

      field: message

      regex: '^\[(?<timestamp>.*?)\] \[(?<thread>.*?)\] \[(?<severity>.*?)\] \[(?<logger>.*?)\]  - (?<message>.*)'

    extract-dataiku-ipython-log-format:

      type: parse_regex

      field: message

      regex: '^\[(?<timestamp>[^\]]+)\] \[(?<pid>\d+)\/(?<thread>[^\]]+)\] \[(?<severity>[^\]]+)\] \[(?<logger>[^\]]+)\] (?<message>.*)$'

    extract-nginx-log-format:

      type: parse_regex

      field: message

      regex: '^(?<timestamp>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[(?<severity>\w+)\] (?<pid>\d+)#(?<worker>\d+): \*(?<request_id>\d+) (?<message>.+?), client: (?<client_ip>[\d\.]+), server: (?<server>[^,]*), request: "(?<request>[^"]+)", host: "(?<host>[^"]+)"'

    extract-nginx-access-log-format:

      type: parse_regex

      field: message

      regex: '^(?<remote_addr>\S+) - (?<remote_user>\S+) \[(?<time_local>[^\]]+)\] "(?<request>[^"]*)" (?<status>\d{3}) (?<body_bytes_sent>\d+) "(?<http_referer>[^"]*)" "(?<http_user_agent>[^"]*)"'

    drop-googlehc-user-agent:

      type: exclude_logs

      match_any:

        - 'jsonPayload.http_user_agent = "GoogleHC/1.0"'

    dataiku-frontend-parse-timestamp:

      type: parse_json

      time_key: timestamp

      time_format: "%Y/%m/%d-%H:%M:%S" # 2025/06/23-22:18:47

      field: message

    dataiku-ipython-parse-timestamp:

      type: parse_json

      time_key: timestamp

      time_format: "%Y/%m/%d-%H:%M:%S.%L" # 2025/06/23-22:20:51.786

      field: message

    dataiku-nginx-parse-timestamp:

      type: parse_json

      time_key: timestamp

      time_format: "%Y/%m/%d %H:%M:%S" # 2025/06/18 10:52:06

      field: message

    dataiku-nginx-access-parse-timestamp:

      type: parse_json

      time_key: time_local

      time_format: "%d/%b/%Y:%H:%M:%S %z" # 23/Jun/2025:22:25:17 -0400

      field: message

  service:

    pipelines:

      dataiku-audit:

        receivers: [dataiku-audit]

        processors: [dataiku-parse-audit, move-severity]

      dataiku-backend:

        receivers: [dataiku-backend]

        processors: [parse-java-multiline, extract-dataiku-java-log-format, move-severity]

      dataiku-unified-monitoring:

        receivers: [dataiku-unified-monitoring]

        processors: [parse-java-multiline, extract-dataiku-java-log-format, move-severity]

      dataiku-frontend:

        receivers: [dataiku-frontend]

        processors: [parse-java-multiline, extract-dataiku-java-log-format, dataiku-frontend-parse-timestamp, move-severity]

      dataiku-ipython:

        receivers: [dataiku-ipython]

        processors: [parse-java-multiline, extract-dataiku-ipython-log-format, dataiku-ipython-parse-timestamp, move-severity]

      dataiku-nginx:

        receivers: [dataiku-nginx]

        processors: [extract-nginx-log-format, dataiku-nginx-parse-timestamp, move-severity]

      dataiku-nginx-access:

        receivers: [dataiku-nginx-access]

        processors: [extract-nginx-access-log-format, drop-googlehc-user-agent, dataiku-nginx-access-parse-timestamp, move-severity]

EOF

    ## setting server timezone to EST

    unlink /etc/localtime

    ln -s /usr/share/zoneinfo/America/New_York /etc/localtime

    ## update ssh settings to time out sessions after 24 hours - will only execute if default parameters are in place

    sed -i "s/.*ClientAliveInterval.*/ClientAliveInterval 84600/g" /etc/ssh/sshd_config

    sed -i "s/.*ClientAliveCountMax.*/ClientAliveCountMax 0/g" /etc/ssh/sshd_config

 

    # Restart ops agent to apply new configuration

    sudo systemctl restart google-cloud-ops-agent || log_warn "Failed to restart google-cloud-ops-agent"

 

    log_info "Cleanup and logging configuration completed"

}

 

# Main driver function - orchestrates the entire setup process

# Handles both initial setup and post-reboot continuation

main()

{

  log_info "========== Starting Dataiku startup script =========="

  log_info "Hostname: $(uname -n)"

  log_info "Zone: ${ZONE}"

  log_info "DSS Node Type: ${DSS_NODE}"

 

  # Check if this is a post-reboot execution after SELinux update

  if [ -f "${SELINUX_MARKER}" ] && [ ! -f "${SETUP_COMPLETE_MARKER}" ]; then

    log_info "Resuming after SELinux reboot - running post-reboot setup"

 

    # Ensure drive is attached and mounted

    attach_drive || { log_error "Failed to attach drive on post-reboot"; return 1; }

    persistent_disk || { log_error "Failed to mount persistent disk on post-reboot"; return 1; }

 

    # Mount shared resources

    mount_shared_resources || log_warn "Failed to mount shared resources, continuing anyway"

 

    # Check if disk is mounted

    MOUNT_CHECK=`mount | grep dataiku | wc -l`

    if [[ ${MOUNT_CHECK} -eq 0 ]]; then

      log_error "CRITICAL: Dataiku disk not mounted after post-reboot setup"

      return 1

    fi

  fi

  # First run - execute full setup

  log_info "Running initial setup"

 

  # Validate GCS bucket accessibility early

  log_info "Validating GCS bucket accessibility"

  if ! gsutil ls "gs://${STARTUP_BUCKET_NAME}/" >/dev/null 2>&1; then

    log_error "Cannot access GCS bucket: gs://${STARTUP_BUCKET_NAME}/ - check permissions and network"

    return 1

  fi

 

  # Download packages first (fail fast if this doesn't work)

  package_download || { log_error "Package download failed - cannot proceed"; return 1; }

 

  # Update SELinux (may trigger reboot)

  update_selinux || { log_error "SELinux update failed"; return 1; }

 

  # If we get here, SELinux didn't need a reboot

  log_info "SELinux configuration complete, continuing with setup"

 

 

  attach_drive || { log_error "Drive attachment failed"; return 1; }

  create_local_groups || { log_error "Failed to create local groups"; return 1; }

  persistent_disk || { log_error "Persistent disk setup failed"; return 1; }

  rpm_package_install || { log_error "RPM package installation failed"; return 1; }

  qualys_install || log_warn "Qualys installation had issues, continuing anyway"

  misc_setup || { log_error "Miscellaneous setup failed"; return 1; }

  systemctl_dataiku || { log_error "Systemctl setup failed"; return 1; }

  cleanup_and_logging

 

  # Verify disk is mounted before proceeding

  MOUNT_CHECK=`mount | grep dataiku | wc -l`

  if [[ ${MOUNT_CHECK} -eq 0 ]]; then

    log_error "CRITICAL: Dataiku disk not mounted after initial setup"

    log_error "Attempting to remount..."

    persistent_disk

    MOUNT_CHECK=`mount | grep dataiku | wc -l`

    if [[ ${MOUNT_CHECK} -eq 0 ]]; then

      log_error "FATAL: Unable to mount dataiku disk. Exiting."

      return 1

    fi

  fi

 

  log_info "Dataiku disk verified as mounted"

 

  # Continue with remaining setup

  mount_shared_resources || log_warn "Failed to mount shared resources, continuing anyway"

  kubectl_setup || log_warn "kubectl setup failed, continuing anyway"

  docker_config || log_warn "docker config failed, continuing anyway"

 

  # Setup Dataiku if already installed

  if [ ! -d ${DSS_INSTALLDIR} ]; then

    log_info "No existing Dataiku installation found at ${DSS_INSTALLDIR}"

  else

    log_info "Existing Dataiku installation detected, running installer update"

    DSS_VERSION=`cat /opt/dataiku/${DSS_NODE}/dss-version.json | grep product_version | awk -F\" '{print $4}'`

    su - dataiku -c "${DSS_INSTALLDIR}/dataiku-dss-${DSS_VERSION}/installer.sh -d ${OPT_DATAIKU}/${DSS_NODE} -t ${DSS_NODE} -u -y" || { log_error "Failed to run Dataiku installer"; return 1; }

    systemctl start dataiku || { log_error "Failed to start Dataiku service"; return 1; }

    log_info "Dataiku service started successfully"

  fi

 

  touch "${SETUP_COMPLETE_MARKER}" || log_warn "Failed to create setup complete marker"

  log_info "========== Initial setup completed successfully =========="

  return 0

}

 

# Execute main function and exit with its return code

main

exit $?