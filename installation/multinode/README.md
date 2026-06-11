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
├── deploy_cluster.sh           # 🌟 Main entry point: End-to-end deployment
├── configure_cluster.sh        # Interactive cluster configuration helper
├── one_click_install.sh        # Quick template-based configuration
├── cm_install.sh               # Cluster Manager installer
├── README.md                   # This file
└── *-cluster.xml               # Generated configurations (created by scripts)
```

**Script Descriptions:**

- **deploy_cluster.sh** 🌟 (RECOMMENDED): Complete end-to-end orchestration from bare-metal to production-ready
  - Guides users through all deployment steps
  - Collects configuration interactively
  - Performs pre-deployment validation
  - Deploys database and Cluster Manager
  - Verifies cluster health
  - Generates deployment summary
  
- **configure_cluster.sh**: Interactive configuration helper (used by deploy_cluster.sh)
  - Guides users through cluster topology and node details
  - Validates all input in real-time
  - Generates customized configuration files
  
- **one_click_install.sh**: Quick configuration generator (for experienced users)
  - Fast template-based configuration selection
  - Suitable for users who want to manually edit configs
  
- **cm_install.sh**: Cluster Manager installer (for advanced use cases)
  - Automates CM installation and configuration
  - Supports interactive or automated modes

## Quick Start

### 🌟 Recommended: Complete End-to-End Deployment

For users who want the entire process automated from bare-metal to production-ready:

```bash
cd installation/multinode
./deploy_cluster.sh
```

This single command will:
1. ✅ Collect cluster configuration interactively
2. ✅ Validate all prerequisites
3. ✅ Deploy the database cluster
4. ✅ Deploy Cluster Manager for high availability
5. ✅ Verify the cluster is operational
6. ✅ Provide a deployment summary

**Estimated time:** 15-45 minutes depending on cluster size and network speed

### Alternative Options

If you prefer more control, use these specialized tools:

#### Option A: Interactive Configuration Only

For collecting cluster details without immediate deployment:

```bash
./configure_cluster.sh
```

Then manually deploy using openGauss tools:
```bash
gs_install -X generated-cluster.xml
./cm_install.sh --config generated-cluster.xml --package CM.tar.gz
```

#### Option B: Quick Template Selection

For experienced users who want to manually edit configuration:

```bash
./one_click_install.sh --list
./one_click_install.sh --topology 1-primary-2-standby --output my-cluster.xml
# Edit my-cluster.xml as needed
gs_install -X my-cluster.xml
./cm_install.sh --config my-cluster.xml --package CM.tar.gz
```

#### Option C: Manual CM Installation

If you've already deployed the database:

```bash
./cm_install.sh --config cluster-config.xml --package CM.tar.gz
```

## Configuration & Deployment Tools

### 🌟 End-to-End Deployment Orchestrator: deploy_cluster.sh

The `deploy_cluster.sh` script provides complete orchestration from bare-metal to production-ready cluster.

**Features:**
- Integrated workflow combining configuration, validation, database deployment, and CM installation
- Interactive guidance at each step
- Pre-deployment validation (prerequisites, SSH, configuration)
- Automatic error handling and recovery suggestions
- Post-deployment verification and health checks
- Comprehensive deployment summary and next steps

**Usage:**

```bash
./deploy_cluster.sh                      # Standard deployment
./deploy_cluster.sh --dry-run            # Preview without executing
./deploy_cluster.sh --config file.xml    # Use existing config
./deploy_cluster.sh --help               # Show all options
```

**Deployment Flow:**
```
Step 1: Configuration Collection
  ↓ (calls configure_cluster.sh interactively)
Step 2: Pre-Deployment Validation
  ├─ Check prerequisites (gs_install, SSH, network)
  ├─ Validate configuration file
  └─ Collect CM package location
  ↓
Step 3: Database Deployment
  ├─ Run gs_preinstall
  ├─ Run gs_install
  └─ Verify cluster status
  ↓
Step 4: Cluster Manager Deployment
  ├─ Collect CA certificate password
  ├─ Run cm_install.sh
  └─ Verify CM status
  ↓
Step 5: Post-Deployment Verification
  ├─ Health checks
  ├─ Status verification
  └─ Generate summary
```

### Interactive Configuration: configure_cluster.sh

The `configure_cluster.sh` script provides step-by-step cluster configuration collection (used by deploy_cluster.sh but can also run standalone).

**Features:**
- Menu-driven topology selection
- Real-time input validation
- Configuration collection for all topologies
- Automatic XML generation
- Quality assurance and validation

**Usage:**

```bash
./configure_cluster.sh
```

### Quick Configuration: one_click_install.sh

For users who prefer template-based configuration with manual editing:

```bash
./one_click_install.sh --list
./one_click_install.sh --topology 1-primary-2-standby --output my-cluster.xml
```

### Help

Get usage information for any script:

```bash
./deploy_cluster.sh --help           # Full deployment orchestrator
./configure_cluster.sh               # Interactive configuration helper
./one_click_install.sh --help        # Quick template selector
./cm_install.sh --help               # CM installer options
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

### Example 1: Complete End-to-End Deployment (Recommended)

Deploy a fully operational cluster with a single command:

```bash
./deploy_cluster.sh
```

The script will interactively:
1. Collect cluster configuration (topology, node names, IPs)
2. Validate all prerequisites
3. Deploy database cluster
4. Deploy Cluster Manager
5. Verify everything is operational

**No additional configuration needed!**

### Example 2: Rapid 2-Node Production Deployment

Deploy a production 2-node cluster quickly:

```bash
# Run end-to-end deployment
./deploy_cluster.sh

# When prompted:
# - Select topology: 1 (1 Primary + 1 Standby)
# - Cluster name: prod_db
# - Primary: db-primary / 10.0.1.10
# - Standby: db-standby / 10.0.1.11
# - CM Package: /path/to/openGauss-CM-6.0.0-*.tar.gz
# - CA Password: SecurePass123!

# Cluster is ready in 15-20 minutes!
```

### Example 3: Multi-Node Production Cluster (4 Nodes)

Deploy a 4-node cluster with 3 standbys:

```bash
./deploy_cluster.sh

# When prompted:
# - Select topology: 4 (1 Primary + 3 Standby)
# - Cluster name: prod_cluster_4
# - Primary: db-primary / 10.0.1.10
# - Standby 1: db-standby1 / 10.0.1.11
# - Standby 2: db-standby2 / 10.0.1.12
# - Standby 3: db-standby3 / 10.0.1.13
# - CM Package: /opt/software/openGauss-CM-*.tar.gz
# - CA Password: MySecure@Pass123

# High-availability cluster ready!
```

### Example 4: Cascaded Cluster Deployment

Deploy a cascaded cluster for reduced network load:

```bash
./deploy_cluster.sh

# When prompted:
# - Select topology: 9 (1 Primary + 1 Standby + 1 Cascaded)
# - Cluster name: cascaded_cluster
# - Primary: db-primary / 10.0.1.10
# - Standby: db-standby / 10.0.1.11
# - Cascaded: db-cascaded / 10.0.1.12
# - CM Package: /path/to/CM.tar.gz
# - CA Password: CascadeCluster@123

# Cluster with cascaded replication ready!
```

### Example 5: Dry Run (Preview Without Executing)

Preview what would be deployed without making changes:

```bash
./deploy_cluster.sh --dry-run
```

This shows:
- Deployment steps
- Configuration that would be collected
- Commands that would be executed
- No actual changes made

### Example 6: Reuse Configuration and CM Package

Deploy using previously saved configuration and CM package:

```bash
./deploy_cluster.sh --config prod-cluster.xml --package CM.tar.gz
```

Skips configuration collection and uses provided files directly.

### Example 7: Manual Approach (Advanced)

For experienced users who want more control:

```bash
# Step 1: Generate configuration interactively
./configure_cluster.sh

# Step 2: Edit configuration if needed
vi prod-cluster-cluster.xml

# Step 3: Deploy database manually
gs_install -X prod-cluster-cluster.xml

# Step 4: Deploy CM manually
./cm_install.sh --config prod-cluster-cluster.xml \
                --package /path/to/CM.tar.gz \
                --ca-password 'MyPassword@123'
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
