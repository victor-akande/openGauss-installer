# openGauss Multi-Node Installation

This directory contains flexible configuration templates and installation scripts for deploying openGauss in various multi-node topologies with optional Cluster Manager (CM) support.

## Supported Topologies

The following deployment topologies are supported:

### Standard Topologies (1 Primary + N Standby)
| Topology | Nodes | CM Support | Use Case |
|----------|-------|------------|----------|
| `1-primary-1-standby` | 2 | ✓ Yes | High availability with Cluster Manager |
| `1-primary-2-standby` | 3 | ✓ Yes | HA with two standby nodes + CM |
| `1-primary-3-standby` | 4 | ✓ Yes | HA with three standby nodes + CM |
| `1-primary-4-standby` | 5 | ✓ Yes | HA with four standby nodes + CM |
| `1-primary-5-standby` | 6 | ✓ Yes | HA with five standby nodes + CM |
| `1-primary-6-standby` | 7 | ✓ Yes | HA with six standby nodes + CM |
| `1-primary-7-standby` | 8 | ✓ Yes | HA with seven standby nodes + CM |
| `1-primary-8-standby` | 9 | ✓ Yes | HA with eight standby nodes + CM |

### Cascaded Topology
| Topology | Nodes | CM Support | Use Case |
|----------|-------|------------|----------|
| `1-primary-1-standby-cascaded` | 3 | ✓ Yes | Primary + direct standby + cascaded standby with CM |

**Notes:**
- All topologies now include **Cluster Manager (CM)** configuration for automatic failover and high availability
- CM enables automatic health monitoring and failover capabilities
- Cascaded topology allows a standby node to replicate from another standby, reducing network load

## Directory Structure

```
multinode/
├── templates/
│   ├── 1-primary-1-standby.xml
│   ├── 1-primary-2-standby.xml
│   ├── 1-primary-3-standby.xml
│   ├── 1-primary-4-standby.xml
│   ├── 1-primary-5-standby.xml
│   ├── 1-primary-6-standby.xml
│   ├── 1-primary-7-standby.xml
│   ├── 1-primary-8-standby.xml
│   └── 1-primary-1-standby-cascaded.xml
├── one_click_install.sh        # Flexible topology selector
├── configure_cluster.sh        # Interactive cluster configuration helper
├── cm_install.sh               # Cluster Manager installer
├── README.md                   # This file
└── *-cluster.xml               # Generated configurations (created by scripts)
```

**Script Descriptions:**

- **configure_cluster.sh**: Interactive helper that guides users through collecting cluster details (hostnames, IP addresses, cluster name, cascade roles) and generates a customized configuration file
- **one_click_install.sh**: Quick configuration generator for users who already know their topology and parameters
- **cm_install.sh**: Automates Cluster Manager installation after successful database deployment

## Quick Start

### Option 1: Interactive Configuration (Recommended for First-Time Users)

Use the interactive helper to be guided through cluster configuration step-by-step:

```bash
cd installation/multinode
./configure_cluster.sh
```

The script will:
1. Present available topology options
2. Ask for cluster name and node details (hostnames, IP addresses)
3. Optionally configure cascade replication
4. Generate a customized configuration file
5. Validate the configuration

### Option 2: Quick Configuration (For Experienced Users)

#### List Available Topologies

```bash
cd installation/multinode
./one_click_install.sh --list
```

#### Generate Configuration for Your Topology

Generate a configuration file for a 1-primary-2-standby topology:

```bash
./one_click_install.sh --topology 1-primary-2-standby --output my-cluster.xml
```

### Step 3: Customize the Configuration

Edit the generated XML file to set:
- **Cluster Name**: Update `clusterName` parameter
- **Node Hostnames**: Replace `node1_hostname`, `node2_hostname`, etc. with actual hostnames
- **IP Addresses**: Update `backIp1s` and individual node IPs
- **Installation Paths**: Customize `gaussdbAppPath`, `gaussdbLogPath`, etc. if needed
- **Ports**: Adjust port numbers if defaults conflict with existing services

#### Example Customization:
```xml
<!-- Update cluster name -->
<PARAM name="clusterName" value="prod_cluster" />

<!-- Update node names and IPs -->
<PARAM name="nodeNames" value="db-primary,db-standby1,db-standby2" />
<PARAM name="backIp1s" value="10.0.1.10,10.0.1.11,10.0.1.12"/>

<!-- Individual node IP assignments -->
<PARAM name="backIp1" value="10.0.1.10"/>
<PARAM name="sshIp1" value="10.0.1.10"/>
```

### Step 4: Deploy the Database Cluster

Use the standard openGauss installation tool:

```bash
gs_install -X my-cluster.xml
```

### Step 5: Deploy Cluster Manager (Optional but Recommended)

After successful database installation, deploy CM for automatic failover:

```bash
# Interactive mode (prompts for CA certificate password)
./cm_install.sh --config my-cluster.xml --package /path/to/openGauss-CM-6.0.0-*.tar.gz

# Or automated mode
./cm_install.sh --config my-cluster.xml \
                --package /path/to/openGauss-CM-6.0.0-*.tar.gz \
                --ca-password 'MySecurePass@123'
```

## Configuration Tools

### Interactive Configuration: configure_cluster.sh

The `configure_cluster.sh` script provides an interactive, step-by-step approach to cluster configuration. It's ideal for first-time users or complex deployments.

**Features:**
- Interactive topology selection menu
- Validation of hostnames and IP addresses
- Node-by-node configuration collection
- Automatic configuration file generation
- Configuration validation before output
- Support for cascaded replication setup

**Usage:**

```bash
./configure_cluster.sh
```

**Key Benefits:**
- Guided process prevents configuration errors
- Validates all input before generating config
- Automatically formats all node details
- Creates production-ready configuration files
- No manual XML editing required

### Quick Configuration: one_click_install.sh

For users who prefer a template-based approach with manual editing:

```bash
./one_click_install.sh --list
./one_click_install.sh --topology 1-primary-2-standby --output my-cluster.xml
```

Then edit the generated file manually to customize node details.

### Help

Get usage information for any script:

```bash
./configure_cluster.sh              # Run interactively
./one_click_install.sh --help
./cm_install.sh --help
```

## Configuration File Parameters

### Cluster Section
```xml
<CLUSTER>
    <!-- Database cluster name -->
    <PARAM name="clusterName" value="Cluster_template" />
    
    <!-- Comma-separated list of node hostnames -->
    <PARAM name="nodeNames" value="node1_hostname,node2_hostname,..." />
    
    <!-- Comma-separated list of node IPs (order matches nodeNames) -->
    <PARAM name="backIp1s" value="192.168.0.1,192.168.0.2,..." />
    
    <!-- Installation directories -->
    <PARAM name="gaussdbAppPath" value="/opt/huawei/install/app" />
    <PARAM name="gaussdbLogPath" value="/var/log/omm" />
    <PARAM name="gaussdbToolPath" value="/opt/huawei/install/om" />
    <PARAM name="corePath" value="/opt/huawei/corefile"/>
</CLUSTER>
```

### Primary Node Section (with CM)
Each primary `<DEVICE>` element includes CM and data node configuration:

```xml
<DEVICE sn="node1_hostname">
    <!-- Node identification -->
    <PARAM name="name" value="node1_hostname"/>
    
    <!-- Availability Zone and priority -->
    <PARAM name="azName" value="AZ1"/>
    <PARAM name="azPriority" value="1"/>
    
    <!-- Network interfaces -->
    <PARAM name="backIp1" value="192.168.0.1"/>
    <PARAM name="sshIp1" value="192.168.0.1"/>
    
    <!-- Cluster Manager (CM) configuration -->
    <PARAM name="cmsNum" value="1"/>
    <PARAM name="cmDir" value="/opt/huawei/install/cm"/>
    <PARAM name="cmServerPortBase" value="15300"/>
    <PARAM name="cmServerListenIp1" value="192.168.0.1,192.168.0.2"/>
    <PARAM name="cmServerHaIp1" value="192.168.0.1,192.168.0.2"/>
    <PARAM name="cmServerlevel" value="1"/>
    <PARAM name="cmServerRelation" value="node1_hostname,node2_hostname"/>
    
    <!-- Data node configuration -->
    <PARAM name="dataNum" value="1"/>
    <PARAM name="dataPortBase" value="15400"/>
    <!-- Format: local_path,remote_node,remote_path,... -->
    <PARAM name="dataNode1" value="/opt/huawei/install/data/dn,node2_hostname,/opt/huawei/install/data/dn"/>
</DEVICE>
```

### Standby Node Section (with CM)
```xml
<DEVICE sn="node2_hostname">
    <PARAM name="name" value="node2_hostname"/>
    <PARAM name="azName" value="AZ1"/>
    <PARAM name="azPriority" value="1"/>
    <PARAM name="backIp1" value="192.168.0.2"/>
    <PARAM name="sshIp1" value="192.168.0.2"/>
    
    <!-- Cluster Manager (CM) standby configuration -->
    <PARAM name="cmDir" value="/opt/huawei/install/cm"/>
    <PARAM name="cmServerPortStandby" value="15300"/>
</DEVICE>
```

### Cascaded Node Section
```xml
<DEVICE sn="node3_hostname">
    <PARAM name="name" value="node3_hostname"/>
    <!-- ... other parameters ... -->
    
    <!-- Mark this node as cascaded standby -->
    <PARAM name="cascadeRole" value="on"/>
    
    <!-- CM configuration also included -->
    <PARAM name="cmDir" value="/opt/huawei/install/cm"/>
    <PARAM name="cmServerPortStandby" value="15300"/>
</DEVICE>
```

## Cluster Manager Installation

### Prerequisites for CM Installation

Before installing CM, ensure:
1. Database cluster is installed and running successfully
2. CM package file is available: `openGauss-CM-*.tar.gz`
3. All nodes are accessible and cluster is in Normal state
4. CA certificate password meets requirements (min 3 character types)

### Verifying Database Installation

```bash
su - omm
gs_om -t status --detail

# Expected output shows cluster_state: Normal
```

### CM Installation with cm_install.sh

**Interactive Mode** (prompts for password):
```bash
./cm_install.sh \
    --config my-cluster.xml \
    --package /opt/software/openGauss/openGauss-CM-6.0.0-openEuler22.03-x86_64.tar.gz
```

**Automated Mode** (no prompts):
```bash
./cm_install.sh \
    --config my-cluster.xml \
    --package /opt/software/openGauss/openGauss-CM-6.0.0-openEuler22.03-x86_64.tar.gz \
    --ca-password 'Secure@Pass123'
```

**Custom Deployment Directory**:
```bash
./cm_install.sh \
    --config my-cluster.xml \
    --package /opt/software/openGauss/openGauss-CM-*.tar.gz \
    --deploy-dir /opt/custom/cm/path \
    --ca-password 'Secure@Pass123'
```

### Post-Installation Verification

After CM installation, verify the deployment:

```bash
# Check CM status
su - omm
gs_om -t status --detail

# Expected output shows both data nodes and CM nodes in Normal state
# Restart cluster if needed (as suggested by installer)
cm_ctl stop
cm_ctl start
```

## Pre-Installation Requirements

Before deploying, ensure:

1. **Network Setup**
   - All nodes can communicate with each other
   - SSH passwordless login is configured between nodes
   - Firewall allows required ports:
     - Data Node: 15400
     - Cluster Manager: 15300

2. **System Requirements**
   - Linux OS (openEuler recommended)
   - Python 3 installed
   - `expect` package installed (for interactive scripts)
   - Sufficient disk space for installation and data

3. **User Permissions**
   - Ensure `omm` system user doesn't already exist (will be created)
   - Run database installation with appropriate privileges
   - Run CM installation as root (uses `su omm` internally)

4. **Hostname Resolution**
   - Ensure all hostnames resolve via DNS or `/etc/hosts`

## Deployment Examples

### Example 1: Interactive Configuration for 2-Node Cluster with CM

**Step 1: Run the interactive configuration helper**
```bash
./configure_cluster.sh
```

**Expected interaction:**
```
Select topology: 1 (1 Primary + 1 Standby)
Enter cluster name: prod_cluster
Enter primary node name: db-primary
Enter primary node IP: 10.0.1.10
Enter standby node name: db-standby1
Enter standby node IP: 10.0.1.11
```

**Step 2: Deploy the database**
```bash
gs_install -X prod_cluster-cluster.xml
```

**Step 3: Deploy Cluster Manager**
```bash
./cm_install.sh --config prod_cluster-cluster.xml \
                --package /opt/software/openGauss/openGauss-CM-*.tar.gz
```

### Example 2: Quick Configuration for 4-Node Cluster

```bash
# Generate config
./one_click_install.sh --topology 1-primary-3-standby --output prod-4node.xml

# Edit prod-4node.xml and customize hostnames/IPs

# Deploy database
gs_install -X prod-4node.xml

# Deploy CM
./cm_install.sh --config prod-4node.xml \
                --package /path/to/openGauss-CM-*.tar.gz
```

### Example 3: Interactive Configuration for 3-Node Cascaded Cluster

**Run interactive setup**
```bash
./configure_cluster.sh
# Select topology 9 (1 Primary + 1 Standby + 1 Cascaded)
# Enter primary, standby, and cascaded node details
# Script automatically sets cascade role for the third node
```

**Deploy the cluster**
```bash
gs_install -X cluster-name-cluster.xml

./cm_install.sh --config cluster-name-cluster.xml \
                --package /path/to/openGauss-CM-*.tar.gz
```

### Example 4: Automated Deployment with CM Password

```bash
# Generate interactive config
./configure_cluster.sh

# Deploy database
gs_install -X cluster-name-cluster.xml

# Deploy CM with automated password
./cm_install.sh --config cluster-name-cluster.xml \
                --package /path/to/openGauss-CM-*.tar.gz \
                --ca-password 'Secure@Pass123'
```

## Troubleshooting

### Getting Help

Use these commands to get help for any script:

```bash
# Interactive configuration helper
./configure_cluster.sh

# Quick topology selector
./one_click_install.sh --help

# Cluster Manager installer
./cm_install.sh --help

# List all available topologies
./one_click_install.sh --list
```

### Configuration Issues

**Invalid input during configure_cluster.sh**
- Hostname validation accepts: alphanumeric, hyphens, underscores, dots
  - Valid: `db-primary`, `node_1`, `postgres.local`
  - Invalid: `db primary` (spaces), `db@primary` (special chars)
- IP address must be in standard dotted-decimal format: `192.168.1.1`

**configure_cluster.sh doesn't find templates**
- Ensure templates directory exists: `ls templates/`
- Run configure_cluster.sh from the multinode directory

**Generated config file not recognized**
- Verify file has `.xml` extension
- Check file was created: `ls -la config-name.xml`
- Validate XML syntax: `xmllint --noout config-name.xml`

### Configuration Validation

**Check XML syntax**
```bash
xmllint --noout prod-cluster.xml

# Verify node count
grep -o "node[0-9]*_hostname" prod-cluster.xml | sort -u | wc -l

# Check cluster name
grep "clusterName" prod-cluster.xml
```

### Common Issues

**CM Installation Password Error**
- Error: "The password must contain at least three kinds of characters"
- Solution: Use password with uppercase, lowercase, numbers, and symbols
  - Example: `Secure@Pass123` ✓
  - Example: `Password123` ✗ (no special character)

**CM Installation Fails After Database Install**
- Verify database cluster is in Normal state: `gs_om -t status --detail`
- Ensure CM package file exists and is readable
- Check that omm user can write to CM installation directory

**Connection refused when configuring**
- Ensure all nodes are reachable: `ping node-hostname`
- Check hostnames resolve: `nslookup node-hostname` or `cat /etc/hosts`
- Verify firewall doesn't block SSH (port 22)

## Related Documentation

- [Single-Node Installation](../singlenode/README.md)
- [Installation Scripts](../init.sh)
- [openGauss Official Documentation](https://opengauss.org)
- [Cluster Manager Documentation](https://opengauss.org)

---

For more information, visit the [openGauss Community](https://opengauss.org)
- **backIp1s**: Replace with the backend/internal IPs of primary and standby.
- **backIp1** / **sshIp1**: Set to the management/internal NIC IPs used for database and SSH traffic.
- **dataNode1**: Update the standby mapping and local data path as required.
- **dataPortBase**: Set an available base port for data node instances (example: `15400`); ensure consistency across nodes.

Tips:
- Use consistent hostnames and IPs across all config files and DNS/hosts entries.
- Prefer private/internal IPs for node communication.
- Verify ports are open and not blocked by firewalls.

**Next steps: Run preinstall**
- Ensure the `omm` user and `dbgrp` group exist on the target hosts and that you have root privileges.
- Run the installer script from the primary node and follow prompts to configure both nodes.

**Install: Run installer and verify**
- Execute the multinode installer script and verify cluster status once complete.

**Notes**
- If tools are not found, verify the openGauss script directory and file permissions.
- After installation completes, use `gs_om -t status --detail` to check the cluster.
