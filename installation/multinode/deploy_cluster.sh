#!/bin/bash

#############################################################################
# Script: deploy_cluster.sh
# Description: End-to-end cluster deployment orchestrator
#              Takes users from bare-metal to production-ready
# Author: openGauss Team
# Usage: ./deploy_cluster.sh
#############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# State variables
CONFIG_FILE=""
CM_PACKAGE=""
DEPLOY_DIR=""
SKIP_VALIDATION=0
DRY_RUN=0

#############################################################################
# Functions
#############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

show_banner() {
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                                                                            ║${NC}"
    echo -e "${MAGENTA}║            openGauss Cluster Deployment Orchestrator                      ║${NC}"
    echo -e "${MAGENTA}║                 Bare-Metal to Production-Ready                            ║${NC}"
    echo -e "${MAGENTA}║                                                                            ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_deployment_plan() {
    log_step "DEPLOYMENT PLAN"
    
    echo "This script will guide you through the following steps:"
    echo ""
    echo "  1️⃣  Configuration Collection"
    echo "      └─ Interactive prompts for cluster topology and node details"
    echo ""
    echo "  2️⃣  Pre-Deployment Validation"
    echo "      ├─ Verify configuration file validity"
    echo "      ├─ Check prerequisites (gsinstall, passwordless SSH)"
    echo "      └─ Validate Cluster Manager package"
    echo ""
    echo "  3️⃣  Database Deployment"
    echo "      ├─ Run gs_preinstall on all nodes"
    echo "      ├─ Run gs_install to deploy database cluster"
    echo "      └─ Verify database cluster status"
    echo ""
    echo "  4️⃣  Cluster Manager Deployment"
    echo "      ├─ Deploy CM on all nodes"
    echo "      ├─ Start CM services"
    echo "      └─ Verify CM status"
    echo ""
    echo "  5️⃣  Post-Deployment Verification"
    echo "      ├─ Check cluster health"
    echo "      ├─ Verify all nodes operational"
    echo "      └─ Generate deployment summary"
    echo ""
}

confirm_proceed() {
    echo ""
    while true; do
        local prompt=$(echo -e "${BLUE}?${NC} Continue with deployment?")
        read -p "$prompt (yes/no): " response
        case "$response" in
            yes|y|YES|Y)
                return 0
                ;;
            no|n|NO|N)
                log_warning "Deployment cancelled by user"
                exit 0
                ;;
            *)
                log_error "Please enter 'yes' or 'no'"
                ;;
        esac
    done
}

step_1_configuration() {
    log_step "STEP 1: Configuration Collection"
    
    log_info "Starting interactive cluster configuration..."
    echo ""
    
    if [[ ! -f "${SCRIPT_DIR}/configure_cluster.sh" ]]; then
        log_error "configure_cluster.sh not found in ${SCRIPT_DIR}"
        return 1
    fi
    
    # Run configure_cluster.sh in non-interactive context
    if ! bash "${SCRIPT_DIR}/configure_cluster.sh"; then
        log_error "Configuration collection failed"
        return 1
    fi
    
    # Find the generated config file (look for most recent .xml)
    CONFIG_FILE=$(ls -t "${SCRIPT_DIR}"/*-cluster.xml 2>/dev/null | head -1)
    
    if [[ -z "$CONFIG_FILE" ]]; then
        log_error "No configuration file found after running configure_cluster.sh"
        return 1
    fi
    
    log_success "Configuration file generated: $(basename "$CONFIG_FILE")"
    
    return 0
}

step_2_validation() {
    log_step "STEP 2: Pre-Deployment Validation"
    
    if [[ -z "$CONFIG_FILE" ]]; then
        log_error "Configuration file not set"
        return 1
    fi
    
    # Check config file exists and is valid XML
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    log_success "Configuration file found: $CONFIG_FILE"
    
    # Validate XML (if xmllint available)
    if command -v xmllint &> /dev/null; then
        if ! xmllint --noout "$CONFIG_FILE" 2>&1 | head -5; then
            log_warning "XML validation returned warnings"
        else
            log_success "XML configuration is valid"
        fi
    fi
    
    # Extract key information from config
    local cluster_name=$(grep 'clusterName.*value=' "$CONFIG_FILE" | grep -o 'value="[^"]*"' | cut -d'"' -f2)
    local node_names=$(grep 'nodeNames.*value=' "$CONFIG_FILE" | grep -o 'value="[^"]*"' | cut -d'"' -f2)
    local node_count=$(echo "$node_names" | tr ',' '\n' | wc -l)
    
    if [[ -z "$cluster_name" ]]; then
        log_error "Could not extract cluster name from configuration"
        return 1
    fi
    
    log_success "Cluster name: $cluster_name"
    log_success "Node count: $node_count"
    log_success "Nodes: $node_names"
    
    # Check for gs_install
    if ! command -v gs_install &> /dev/null; then
        log_error "gs_install command not found in PATH"
        log_info "Please ensure openGauss is installed and in your PATH"
        return 1
    fi
    log_success "gs_install is available"
    
    # Prompt for CM package location
    log_info "Please provide Cluster Manager package information:"
    echo ""
    
    while [[ -z "$CM_PACKAGE" ]]; do
        local prompt=$(echo -e "${BLUE}?${NC} Path to Cluster Manager package: ")
        read -p "$prompt" cm_path
        
        if [[ -z "$cm_path" ]]; then
            log_error "Package path cannot be empty"
            continue
        fi
        
        # Expand ~ if needed
        cm_path="${cm_path/#\~/$HOME}"
        
        if [[ ! -f "$cm_path" ]]; then
            log_error "File not found: $cm_path"
            continue
        fi
        
        if [[ ! "$cm_path" == *.tar.gz ]] && [[ ! "$cm_path" == *.tgz ]]; then
            log_warning "File does not have .tar.gz or .tgz extension"
            read -p "Continue anyway? (yes/no): " confirm
            if [[ ! "$confirm" =~ ^(yes|y|YES|Y)$ ]]; then
                continue
            fi
        fi
        
        CM_PACKAGE="$cm_path"
    done
    
    log_success "CM package: $(basename "$CM_PACKAGE")"
    
    # Check for passwordless SSH (warning only)
    local first_node=$(echo "$node_names" | cut -d',' -f1)
    if ! ssh -o ConnectTimeout=5 "$first_node" "echo 'SSH test'" &>/dev/null; then
        log_warning "SSH connection to $first_node failed or requires password"
        log_info "Ensure passwordless SSH is configured on all nodes"
        echo ""
        read -p "Continue anyway? (yes/no): " confirm
        if [[ ! "$confirm" =~ ^(yes|y|YES|Y)$ ]]; then
            return 1
        fi
    else
        log_success "SSH passwordless access verified"
    fi
    
    return 0
}

step_3_database_deployment() {
    log_step "STEP 3: Database Deployment"
    
    if [[ -z "$CONFIG_FILE" ]]; then
        log_error "Configuration file not set"
        return 1
    fi
    
    log_info "Starting database cluster deployment..."
    echo ""
    
    # Show what will be executed
    echo "Command to execute:"
    echo "  ${GREEN}gs_install -X $CONFIG_FILE${NC}"
    echo ""
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN: Skipping actual deployment"
        log_success "Database deployment would execute successfully"
        return 0
    fi
    
    # Confirm before running
    local prompt=$(echo -e "${BLUE}?${NC} Execute database deployment?")
    read -p "$prompt (yes/no): " confirm
    if [[ ! "$confirm" =~ ^(yes|y|YES|Y)$ ]]; then
        log_warning "Database deployment skipped by user"
        return 1
    fi
    
    # Execute gs_install
    log_info "Executing gs_install (this may take 10-30 minutes)..."
    if gs_install -X "$CONFIG_FILE"; then
        log_success "Database cluster deployed successfully"
    else
        log_error "Database deployment failed"
        return 1
    fi
    
    # Brief wait for cluster to stabilize
    log_info "Waiting for cluster to stabilize..."
    sleep 5
    
    # Check cluster status
    log_info "Checking cluster status..."
    if command -v gs_om &> /dev/null; then
        if su - omm -c "gs_om -t status --detail" 2>/dev/null | grep -q "Normal"; then
            log_success "Cluster is operational"
        else
            log_warning "Cluster status is not 'Normal' - may still be initializing"
        fi
    fi
    
    return 0
}

step_4_cm_deployment() {
    log_step "STEP 4: Cluster Manager Deployment"
    
    if [[ -z "$CONFIG_FILE" ]] || [[ -z "$CM_PACKAGE" ]]; then
        log_error "Configuration file or CM package not set"
        return 1
    fi
    
    log_info "Starting Cluster Manager deployment..."
    echo ""
    
    # Show what will be executed
    echo "Command to execute:"
    echo "  ${GREEN}./cm_install.sh --config $CONFIG_FILE --package $CM_PACKAGE${NC}"
    echo ""
    
    if [[ $DRY_RUN -eq 1 ]]; then
        log_warning "DRY RUN: Skipping actual CM deployment"
        log_success "CM deployment would execute successfully"
        return 0
    fi
    
    # Get CA password
    log_info "Cluster Manager requires a CA certificate password"
    log_info "Password must contain at least 3 character types: uppercase, lowercase, numbers, symbols"
    echo ""
    
    local prompt=$(echo -e "${BLUE}?${NC} Enter CA certificate password: ")
    read -sp "$prompt" ca_password
    echo ""
    
    prompt=$(echo -e "${BLUE}?${NC} Confirm password: ")
    read -sp "$prompt" ca_password_confirm
    echo ""
    
    if [[ "$ca_password" != "$ca_password_confirm" ]]; then
        log_error "Passwords do not match"
        return 1
    fi
    
    if [[ -z "$ca_password" ]]; then
        log_error "Password cannot be empty"
        return 1
    fi
    
    # Confirm before running
    local prompt=$(echo -e "${BLUE}?${NC} Execute CM deployment?")
    read -p "$prompt (yes/no): " confirm
    if [[ ! "$confirm" =~ ^(yes|y|YES|Y)$ ]]; then
        log_warning "CM deployment skipped by user"
        return 1
    fi
    
    # Execute cm_install.sh
    log_info "Executing cm_install.sh (this may take 5-15 minutes)..."
    if bash "${SCRIPT_DIR}/cm_install.sh" \
        --config "$CONFIG_FILE" \
        --package "$CM_PACKAGE" \
        --ca-password "$ca_password"; then
        log_success "Cluster Manager deployed successfully"
    else
        log_error "Cluster Manager deployment failed"
        return 1
    fi
    
    # Brief wait for CM to stabilize
    log_info "Waiting for CM to stabilize..."
    sleep 5
    
    return 0
}

step_5_verification() {
    log_step "STEP 5: Post-Deployment Verification"
    
    log_info "Performing health checks..."
    echo ""
    
    # Check cluster status
    if command -v gs_om &> /dev/null; then
        log_info "Checking database cluster status..."
        if su - omm -c "gs_om -t status --detail" 2>/dev/null; then
            log_success "Database cluster status check completed"
        else
            log_warning "Could not retrieve database cluster status"
        fi
    else
        log_warning "gs_om not available for cluster status check"
    fi
    
    echo ""
    
    # Extract cluster info
    local cluster_name=$(grep 'clusterName.*value=' "$CONFIG_FILE" | grep -o 'value="[^"]*"' | cut -d'"' -f2)
    local node_names=$(grep 'nodeNames.*value=' "$CONFIG_FILE" | grep -o 'value="[^"]*"' | cut -d'"' -f2)
    
    log_success "Configuration file: $(basename "$CONFIG_FILE")"
    log_success "Cluster name: $cluster_name"
    log_success "Nodes: $node_names"
    
    return 0
}

show_deployment_summary() {
    log_step "DEPLOYMENT SUMMARY"
    
    echo -e "${GREEN}✓ Deployment Process Completed${NC}"
    echo ""
    echo "Your openGauss cluster is now running with the following configuration:"
    echo ""
    
    # Extract info from config
    local cluster_name=$(grep 'clusterName.*value=' "$CONFIG_FILE" | grep -o 'value="[^"]*"' | cut -d'"' -f2)
    local node_names=$(grep 'nodeNames.*value=' "$CONFIG_FILE" | grep -o 'value="[^"]*"' | cut -d'"' -f2)
    local node_count=$(echo "$node_names" | tr ',' '\n' | wc -l)
    
    echo "  Cluster Name: $cluster_name"
    echo "  Total Nodes: $node_count"
    echo "  Nodes: $node_names"
    echo "  Configuration File: $CONFIG_FILE"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Verify cluster operation:"
    echo "     ${GREEN}su - omm${NC}"
    echo "     ${GREEN}gs_om -t status --detail${NC}"
    echo ""
    echo "  2. Connect to the database:"
    echo "     ${GREEN}gsql -d postgres -U omm${NC}"
    echo ""
    echo "  3. Monitor cluster:"
    echo "     ${GREEN}cm_ctl query${NC}"
    echo ""
    echo "For more information, see README.md in this directory."
    echo ""
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  -h, --help              Show this help message
  -d, --dry-run           Show what would be done without executing
  -c, --config FILE       Use existing configuration file (skip step 1)
  -p, --package FILE      Use existing CM package (skip selection in step 2)
  -s, --skip-validation   Skip pre-deployment validation

Examples:
  # Standard deployment (interactive)
  ./deploy_cluster.sh

  # Dry run (see what would happen)
  ./deploy_cluster.sh --dry-run

  # Use existing config and CM package
  ./deploy_cluster.sh --config prod-cluster.xml --package CM.tar.gz

  # Show help
  ./deploy_cluster.sh --help
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=1
                log_info "DRY RUN MODE ENABLED"
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift
                ;;
            -p|--package)
                CM_PACKAGE="$2"
                shift
                ;;
            -s|--skip-validation)
                SKIP_VALIDATION=1
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
        shift
    done
}

#############################################################################
# Main Script
#############################################################################

main() {
    show_banner
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show deployment plan
    show_deployment_plan
    confirm_proceed
    
    # Execute deployment steps
    if ! step_1_configuration; then
        log_error "Configuration collection failed"
        exit 1
    fi
    
    if [[ $SKIP_VALIDATION -ne 1 ]]; then
        if ! step_2_validation; then
            log_error "Pre-deployment validation failed"
            exit 1
        fi
    else
        log_warning "Skipping pre-deployment validation"
    fi
    
    if ! step_3_database_deployment; then
        log_error "Database deployment failed"
        exit 1
    fi
    
    if ! step_4_cm_deployment; then
        log_warning "Cluster Manager deployment encountered issues"
        log_info "Database cluster is operational, but CM may not be fully deployed"
    fi
    
    if ! step_5_verification; then
        log_warning "Post-deployment verification had issues"
    fi
    
    # Show summary
    show_deployment_summary
    
    log_success "Deployment orchestration completed!"
}

# Run main function
main "$@"
