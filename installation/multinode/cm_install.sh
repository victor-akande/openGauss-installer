#!/bin/bash
#############################################################################
# Copyright (c): 2021-2023, openGauss Community
#
# Cluster Manager (CM) installation script for openGauss
# Run this script AFTER successful database installation
#############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/cm_install.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#############################################################################
# Functions
#############################################################################

print_header() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -c, --config FILE          Path to cluster XML configuration file
                               (Required)
    
    -p, --package FILE         Path to CM package 
                               (openGauss-CM-*.tar.gz)
                               (Required)
    
    -d, --deploy-dir DIR       CM deployment directory
                               Default: /opt/software/openGauss/cm
    
    -a, --ca-password PASS     CA certificate password
                               If not provided, will prompt interactively
    
    -h, --help                 Display this help message

Examples:
    # Interactive mode (prompts for password)
    $0 --config /path/to/cluster.xml --package /path/to/openGauss-CM-*.tar.gz

    # Automated mode (provide password)
    $0 --config cluster.xml --package CM.tar.gz --ca-password 'MyPass@123'

EOF
    exit 1
}

validate_inputs() {
    local config=$1
    local package=$2
    
    if [ ! -f "$config" ]; then
        print_error "Configuration file not found: $config"
        return 1
    fi
    
    if [ ! -f "$package" ]; then
        print_error "CM package not found: $package"
        return 1
    fi
    
    return 0
}

extract_cm_package() {
    local package=$1
    local deploy_dir=$2
    
    print_info "Extracting CM package to $deploy_dir"
    
    mkdir -p "$deploy_dir"
    tar -zxf "$package" -C "$deploy_dir"
    
    print_success "CM package extracted"
}

setup_permissions() {
    local deploy_dir=$1
    
    print_info "Setting up permissions for omm:dbgrp"
    chown -R omm:dbgrp "$deploy_dir"
    
    print_success "Permissions configured"
}

install_cm() {
    local config=$1
    local deploy_dir=$2
    local ca_password=$3
    
    print_info "Preparing CM installation"
    
    local cm_tool_dir="${deploy_dir}/tool/cm_tool"
    
    if [ ! -x "${cm_tool_dir}/cm_install" ]; then
        print_error "cm_install script not found or not executable"
        return 1
    fi
    
    # Create expect script for CM installation
    local expect_script="/tmp/cm_install_${RANDOM}.exp"
    
    cat > "$expect_script" <<'EXPECT_EOF'
#!/usr/bin/expect
set timeout 30

set config [lindex $argv 0]
set cm_install [lindex $argv 1]
set ca_password [lindex $argv 2]
set deploy_dir [lindex $argv 3]

set cm_pkg_path "${deploy_dir}/openGauss-CM-*.tar.gz"
if {[catch {glob ${deploy_dir}/openGauss-CM-*.tar.gz} cm_pkg]} {
    set cm_pkg "[glob ${deploy_dir}/openGauss-CM*.tar.gz]"
}

spawn su omm -c "$cm_install -X $config --cmpkg '$cm_pkg'"

expect {
    "Please input the password for ca cert:" {
        send "$ca_password\r"
        exp_continue
    }
    "Please input the password for ca cert again:" {
        send "$ca_password\r"
        exp_continue
    }
    "The password must contain at least three kinds of characters" {
        send_user "\n${RED}Error: Password doesn't meet requirements${NC}\n"
        send_user "Password must contain at least 3 types of characters:\n"
        send_user "  - Uppercase letters\n"
        send_user "  - Lowercase letters\n"
        send_user "  - Numbers\n"
        send_user "  - Special characters\n"
        exit 1
    }
    "Install CM tool success" {
        send_user "\n${GREEN}✓ CM installation succeeded${NC}\n"
        exp_continue
    }
    eof {
        catch wait result
        exit [lindex $result 3]
    }
}
EXPECT_EOF

    chmod +x "$expect_script"
    
    # Run expect script with CM password
    print_info "Running CM installation..."
    
    if ! expect "$expect_script" "$config" "${cm_tool_dir}/cm_install" "$ca_password" "$deploy_dir"; then
        rm -f "$expect_script"
        print_error "CM installation failed"
        return 1
    fi
    
    rm -f "$expect_script"
    print_success "CM installation completed"
    return 0
}

#############################################################################
# Main script
#############################################################################

CONFIG_FILE=""
PACKAGE_FILE=""
DEPLOY_DIR="/opt/software/openGauss/cm"
CA_PASSWORD=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -p|--package)
            PACKAGE_FILE="$2"
            shift 2
            ;;
        -d|--deploy-dir)
            DEPLOY_DIR="$2"
            shift 2
            ;;
        -a|--ca-password)
            CA_PASSWORD="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [ -z "$CONFIG_FILE" ] || [ -z "$PACKAGE_FILE" ]; then
    print_error "Configuration file and package file are required"
    usage
fi

# Validate inputs
if ! validate_inputs "$CONFIG_FILE" "$PACKAGE_FILE"; then
    exit 1
fi

# Prompt for CA password if not provided
if [ -z "$CA_PASSWORD" ]; then
    echo ""
    read -sp "Enter CA certificate password (min 3 character types: uppercase, lowercase, numbers, symbols): " CA_PASSWORD
    echo ""
    
    if [ -z "$CA_PASSWORD" ]; then
        print_error "CA password cannot be empty"
        exit 1
    fi
fi

print_header "openGauss Cluster Manager Installation"
print_info "Configuration: $CONFIG_FILE"
print_info "Package: $PACKAGE_FILE"
print_info "Deploy Directory: $DEPLOY_DIR"

# Execution steps
print_info "Step 1: Extracting CM package..."
if ! extract_cm_package "$PACKAGE_FILE" "$DEPLOY_DIR"; then
    exit 1
fi

print_info "Step 2: Setting up permissions..."
if ! setup_permissions "$DEPLOY_DIR"; then
    exit 1
fi

print_info "Step 3: Installing CM..."
if ! install_cm "$CONFIG_FILE" "$DEPLOY_DIR" "$CA_PASSWORD"; then
    exit 1
fi

echo ""
print_success "Cluster Manager installation completed successfully!"

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Verify CM status:"
echo "   su - omm"
echo "   gs_om -t status --detail"
echo ""
echo "2. If needed, restart the cluster:"
echo "   cm_ctl stop"
echo "   cm_ctl start"
echo ""

# Log the action
{
    echo "$(date): CM installation completed"
    echo "Config: $CONFIG_FILE"
    echo "Package: $PACKAGE_FILE"
    echo ""
} >> "$LOG_FILE"

exit 0
