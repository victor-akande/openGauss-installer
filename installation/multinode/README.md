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
├── one_click_install.sh        # Database configuration generator
├── cm_install.sh               # Cluster Manager installer
├── README.md                   # This file
└── cluster_config.xml          # Generated configuration (created by script)
```

## Quick Start

### 1. List Available Topologies

```bash
cd installation/multinode
./one_click_install.sh --list
```

### 2. Generate Configuration for Your Topology

Generate a configuration file for a 1-primary-2-standby topology:

```bash
./one_click_install.sh --topology 1-primary-2-standby --output my-cluster.xml
```

### 3. Customize the Configuration

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

### 4. Deploy the Database Cluster

Use the standard openGauss installation tool:

```bash
gs_install -X my-cluster.xml
```

### 5. Deploy Cluster Manager (Optional but Recommended)

After successful database installation, deploy CM for automatic failover:

```bash
# Interactive mode (prompts for CA certificate password)
./cm_install.sh --config my-cluster.xml --package /path/to/openGauss-CM-6.0.0-*.tar.gz

# Or automated mode
./cm_install.sh --config my-cluster.xml \
                --package /path/to/openGauss-CM-6.0.0-*.tar.gz \
                --ca-password 'MySecurePass@123'
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

### Example 1: Simple 2-Node Cluster with CM

```bash
# Generate config
./one_click_install.sh --topology 1-primary-1-standby --output prod-2node.xml

# Edit prod-2node.xml with actual hostnames and IPs

# Deploy database
gs_install -X prod-2node.xml

# Deploy CM
./cm_install.sh --config prod-2node.xml \
                --package /opt/software/openGauss/openGauss-CM-*.tar.gz
```

### Example 2: 4-Node Cluster with CM

```bash
# Generate config
./one_click_install.sh --topology 1-primary-3-standby --output prod-4node.xml

# Customize with production details

# Deploy database
gs_install -X prod-4node.xml

# Deploy CM
./cm_install.sh --config prod-4node.xml \
                --package /path/to/openGauss-CM-*.tar.gz
```

### Example 3: 3-Node Cascaded Cluster with CM

```bash
# Generate config
./one_click_install.sh --topology 1-primary-1-standby-cascaded --output prod-cascaded.xml

# Deploy database
gs_install -X prod-cascaded.xml

# Deploy CM
./cm_install.sh --config prod-cascaded.xml \
                --package /path/to/openGauss-CM-*.tar.gz
```

## Troubleshooting

### List Available Templates
```bash
./one_click_install.sh --list
```

### Get Help
```bash
./one_click_install.sh --help
./cm_install.sh --help
```

### Configuration Validation
```bash
# Check XML syntax
xmllint --noout prod-cluster.xml

# Verify node count
grep -o "node[0-9]*_hostname" prod-cluster.xml | sort -u | wc -l
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
