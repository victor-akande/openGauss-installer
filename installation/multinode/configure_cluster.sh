#!/bin/bash

#############################################################################
# Script: configure_cluster.sh
# Description: Interactive cluster configuration helper for openGauss
#              Collects cluster details and generates deployment config
# Author: openGauss Team
# Usage: ./configure_cluster.sh
#############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

# Arrays to store configuration
declare -a NODE_NAMES
declare -a NODE_IPS
declare -a CASCADE_ROLES
declare -a IP_LIST

#############################################################################
# Functions
#############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

show_topology_menu() {
    show_header "Available Topologies"
    
    echo "Select deployment topology:"
    echo ""
    echo "  1) 1 Primary + 1 Standby (2 nodes)"
    echo "  2) 1 Primary + 2 Standby (3 nodes)"
    echo "  3) 1 Primary + 3 Standby (4 nodes)"
    echo "  4) 1 Primary + 4 Standby (5 nodes)"
    echo "  5) 1 Primary + 5 Standby (6 nodes)"
    echo "  6) 1 Primary + 6 Standby (7 nodes)"
    echo "  7) 1 Primary + 7 Standby (8 nodes)"
    echo "  8) 1 Primary + 8 Standby (9 nodes)"
    echo "  9) 1 Primary + 1 Standby + 1 Cascaded (3 nodes)"
    echo ""
}

validate_hostname() {
    local hostname="$1"
    # Allow alphanumeric, hyphens, and underscores
    if [[ $hostname =~ ^[a-zA-Z0-9._-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_ip() {
    local ip="$1"
    local octet="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
    if [[ $ip =~ ^${octet}\.${octet}\.${octet}\.${octet}$ ]]; then
        return 0
    else
        return 1
    fi
}

get_cluster_name() {
    show_header "Cluster Configuration"
    
    while true; do
        read -p "Enter cluster name: " CLUSTER_NAME
        if [[ -z "$CLUSTER_NAME" ]]; then
            log_error "Cluster name cannot be empty"
            continue
        fi
        if validate_hostname "$CLUSTER_NAME"; then
            log_success "Cluster name set to: $CLUSTER_NAME"
            break
        else
            log_error "Invalid cluster name. Use alphanumeric characters, hyphens, or underscores"
        fi
    done
}

get_topology_choice() {
    local choice
    while true; do
        show_topology_menu
        read -p "Enter topology choice (1-9): " choice
        
        case $choice in
            1) TOPOLOGY="1-primary-1-standby"; STANDBY_COUNT=1; CASCADED=0; break ;;
            2) TOPOLOGY="1-primary-2-standby"; STANDBY_COUNT=2; CASCADED=0; break ;;
            3) TOPOLOGY="1-primary-3-standby"; STANDBY_COUNT=3; CASCADED=0; break ;;
            4) TOPOLOGY="1-primary-4-standby"; STANDBY_COUNT=4; CASCADED=0; break ;;
            5) TOPOLOGY="1-primary-5-standby"; STANDBY_COUNT=5; CASCADED=0; break ;;
            6) TOPOLOGY="1-primary-6-standby"; STANDBY_COUNT=6; CASCADED=0; break ;;
            7) TOPOLOGY="1-primary-7-standby"; STANDBY_COUNT=7; CASCADED=0; break ;;
            8) TOPOLOGY="1-primary-8-standby"; STANDBY_COUNT=8; CASCADED=0; break ;;
            9) TOPOLOGY="1-primary-1-standby-cascaded"; STANDBY_COUNT=1; CASCADED=1; break ;;
            *)
                log_error "Invalid choice. Please enter 1-9"
                ;;
        esac
    done
    
    log_success "Topology selected: $TOPOLOGY"
}

get_node_details() {
    show_header "Node Configuration"
    
    local total_nodes=$((1 + STANDBY_COUNT + CASCADED))
    log_info "You will configure $total_nodes nodes"
    echo ""
    
    # Primary node
    log_info "Configuring PRIMARY node..."
    get_single_node_details "primary" 1 0
    
    # Standby nodes
    for ((i=1; i<=STANDBY_COUNT; i++)); do
        log_info "Configuring STANDBY node $i..."
        get_single_node_details "standby" $((i+1)) 0
    done
    
    # Cascaded node (if applicable)
    if [[ $CASCADED -eq 1 ]]; then
        log_info "Configuring CASCADED node..."
        get_single_node_details "cascaded" $((STANDBY_COUNT+2)) 1
    fi
    
    echo ""
    log_success "All node details collected"
}

get_single_node_details() {
    local node_type="$1"
    local node_index="$2"
    local is_cascaded="$3"
    
    echo ""
    echo "--- Node $node_index ($node_type) ---"
    
    # Get node name
    local node_name
    while true; do
        read -p "Enter node name: " node_name
        if [[ -z "$node_name" ]]; then
            log_error "Node name cannot be empty"
            continue
        fi
        if validate_hostname "$node_name"; then
            break
        else
            log_error "Invalid node name. Use alphanumeric characters, hyphens, or underscores"
        fi
    done
    NODE_NAMES[$((node_index-1))]="$node_name"
    
    # Get IP address
    local node_ip
    while true; do
        read -p "Enter IP address: " node_ip
        if validate_ip "$node_ip"; then
            break
        else
            log_error "Invalid IP address format"
        fi
    done
    NODE_IPS[$((node_index-1))]="$node_ip"
    IP_LIST+=("$node_ip")
    
    # Get cascade role for cascaded nodes
    if [[ $is_cascaded -eq 1 ]]; then
        CASCADE_ROLES[$((node_index-1))]="on"
        log_info "Cascade role set to: on"
    else
        CASCADE_ROLES[$((node_index-1))]="off"
    fi
    
    log_success "Node configuration complete: $node_name ($node_ip)"
}

show_summary() {
    show_header "Configuration Summary"
    
    echo "Cluster Name: $CLUSTER_NAME"
    echo "Topology: $TOPOLOGY"
    echo "Total Nodes: $((1 + STANDBY_COUNT + CASCADED))"
    echo ""
    echo "Nodes:"
    for ((i=0; i<$((1 + STANDBY_COUNT + CASCADED)); i++)); do
        local role="standby"
        if [[ $i -eq 0 ]]; then
            role="primary"
        elif [[ ${CASCADE_ROLES[$i]} == "on" ]]; then
            role="cascaded"
        fi
        echo "  ${NODE_NAMES[$i]}: ${NODE_IPS[$i]} ($role)"
    done
    echo ""
}

confirm_and_generate() {
    show_summary
    
    while true; do
        read -p "Is this configuration correct? (yes/no): " confirmation
        case "$confirmation" in
            yes|y|YES|Y)
                break
                ;;
            no|n|NO|N)
                log_warning "Configuration cancelled. Please run the script again."
                exit 0
                ;;
            *)
                log_error "Please enter 'yes' or 'no'"
                ;;
        esac
    done
}

get_output_filename() {
    local default_output="${CLUSTER_NAME}-cluster.xml"
    
    echo ""
    read -p "Enter output configuration filename [${default_output}]: " output_filename
    
    if [[ -z "$output_filename" ]]; then
        output_filename="$default_output"
    fi
    
    # Ensure .xml extension
    if [[ ! "$output_filename" == *.xml ]]; then
        output_filename="${output_filename}.xml"
    fi
    
    OUTPUT_FILE="$output_filename"
    log_success "Output file will be: $OUTPUT_FILE"
}

generate_config() {
    show_header "Generating Configuration"
    
    local template_file="${TEMPLATES_DIR}/${TOPOLOGY}.xml"
    
    if [[ ! -f "$template_file" ]]; then
        log_error "Template file not found: $template_file"
        return 1
    fi
    
    log_info "Using template: $template_file"
    
    # Copy template to output file
    cp "$template_file" "$OUTPUT_FILE"
    log_info "Template copied to: $OUTPUT_FILE"
    
    # Replace cluster name
    sed -i "s/Cluster_template/${CLUSTER_NAME}/g" "$OUTPUT_FILE"
    log_info "Updated cluster name"
    
    # Create comma-separated lists
    local node_names_csv=$(IFS=,; echo "${NODE_NAMES[*]}")
    local node_ips_csv=$(IFS=,; echo "${NODE_IPS[*]}")
    
    # Replace node names and IPs
    sed -i "s/nodeNames\" value=\"[^\"]*\"/nodeNames\" value=\"${node_names_csv}/g" "$OUTPUT_FILE"
    sed -i "s/backIp1s\" value=\"[^\"]*\"/backIp1s\" value=\"${node_ips_csv}/g" "$OUTPUT_FILE"
    log_info "Updated node names and IPs"
    
    # Replace individual node configurations
    for ((i=0; i<$((1 + STANDBY_COUNT + CASCADED)); i++)); do
        local node_name="${NODE_NAMES[$i]}"
        local node_ip="${NODE_IPS[$i]}"
        local node_placeholder="node$((i+1))_hostname"
        local ip_placeholder="192.168.0.$((i+1))"
        
        # Replace hostname placeholders
        sed -i "s/${node_placeholder}/${node_name}/g" "$OUTPUT_FILE"
        
        # Replace IP placeholders
        sed -i "s/${ip_placeholder}/${node_ip}/g" "$OUTPUT_FILE"
        
        # Replace cascade role for cascaded nodes
        if [[ ${CASCADE_ROLES[$i]} == "on" ]]; then
            # Find the node device section and add cascade role
            local node_section_marker="<PARAM name=\"name\" value=\"${node_name}\"/>"
            if grep -q "$node_section_marker" "$OUTPUT_FILE"; then
                # Add cascadeRole parameter after the name parameter
                sed -i "/${node_section_marker}/a\\            <PARAM name=\"cascadeRole\" value=\"on\"/>" "$OUTPUT_FILE"
            fi
        fi
    done
    log_info "Updated individual node configurations"
    
    log_success "Configuration file generated: $OUTPUT_FILE"
}

validate_config() {
    show_header "Validating Configuration"
    
    if [[ ! -f "$OUTPUT_FILE" ]]; then
        log_error "Configuration file not found: $OUTPUT_FILE"
        return 1
    fi
    
    # Check if xmllint is available
    if command -v xmllint &> /dev/null; then
        if xmllint --noout "$OUTPUT_FILE" 2>&1; then
            log_success "Configuration file is valid XML"
        else
            log_warning "Configuration file has XML validation warnings"
        fi
    else
        log_warning "xmllint not available - skipping XML validation"
    fi
    
    # Check key parameters
    if grep -q "clusterName.*${CLUSTER_NAME}" "$OUTPUT_FILE"; then
        log_success "Cluster name verified in config"
    else
        log_error "Cluster name not found in config"
        return 1
    fi
    
    # Verify all node names are in config
    local all_present=true
    for node_name in "${NODE_NAMES[@]}"; do
        if ! grep -q "$node_name" "$OUTPUT_FILE"; then
            log_warning "Node name '$node_name' not found in config"
            all_present=false
        fi
    done
    
    if $all_present; then
        log_success "All node names verified in config"
    fi
}

show_next_steps() {
    show_header "Next Steps"
    
    echo "1. Review the generated configuration file:"
    echo "   ${GREEN}cat $OUTPUT_FILE${NC}"
    echo ""
    echo "2. Deploy the database cluster:"
    echo "   ${GREEN}gs_install -X $OUTPUT_FILE${NC}"
    echo ""
    echo "3. After successful database deployment, install Cluster Manager:"
    echo "   ${GREEN}./cm_install.sh --config $OUTPUT_FILE --package /path/to/CM.tar.gz${NC}"
    echo ""
    echo "For more information, see the README.md in this directory."
    echo ""
}

#############################################################################
# Main Script
#############################################################################

main() {
    show_header "openGauss Cluster Configuration Helper"
    
    # Verify template directory exists
    if [[ ! -d "$TEMPLATES_DIR" ]]; then
        log_error "Templates directory not found: $TEMPLATES_DIR"
        exit 1
    fi
    
    # Collect configuration
    get_cluster_name
    get_topology_choice
    get_node_details
    
    # Confirm configuration
    confirm_and_generate
    
    # Generate output file
    get_output_filename
    generate_config
    
    # Validate generated config
    validate_config
    
    # Show summary and next steps
    show_header "Configuration Complete"
    show_summary
    show_next_steps
    
    log_success "Configuration helper completed successfully!"
}

# Run main function
main "$@"
