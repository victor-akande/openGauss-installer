# openGauss Multinode (Primary/Standby) One-Click Installer

## Overview

The `one_click_install.sh` script provides an automated installation process for deploying an openGauss Primary/Standby multinode cluster. It handles system preparation, package download, cluster configuration, and installation steps across both the primary and standby nodes.

## Features

- **Automated System Preparation**: Configures hostname, `/etc/hosts`, firewall, and SELinux settings on both primary and standby nodes.
- **Dependency Installation**: Installs required OS packages and libraries on both nodes.
- **Package Download & Extraction**: Downloads the openGauss package and extracts it on the primary node.
- **User Management**: Creates the necessary `omm` user and `dbgrp` group on the primary node.
- **Cluster Configuration**: Generates the XML file for a 1-primary-1-standby deployment.
- **Pre-installation Setup**: Runs `gs_preinstall` to prepare the environment and build mutual trust.
- **Database Installation**: Executes `gs_install` to deploy the cluster with automated password handling.
- **Architecture Detection**: Supports both `x86_64` and `aarch64` architectures.
- **Interactive Prompts**: Guides the user through required inputs with sensible defaults.

## Prerequisites

- **Operating System**: openEuler 20.03 or 22.03 (detected automatically).
- **Architecture**: `x86_64` or `aarch64`.
- **Permissions**: Must be run as root (use `sudo`).
- **Network**: Internet connection for package download and SSH access from primary to standby.
- **SSH Access**: Password-based SSH login must be available from primary to standby for `root`.
- **Disk Space**: Sufficient space in `/opt` for installation (around 2-3 GB recommended).

## Usage

1. **Navigate to the script directory**:
   ```bash
   cd /path/to/openGauss-installer/installation/multinode
   ```

2. **Make the script executable** (if not already):
   ```bash
   chmod +x one_click_install.sh
   ```

3. **Run the installer as root**:
   ```bash
   sudo ./one_click_install.sh
   ```

4. **Follow the interactive prompts**:
   - Primary server IP address (detected automatically)
   - Primary server hostname (detected automatically)
   - Standby server IP address
   - Standby server hostname
   - Root password for SSH to standby
   - OS password for `omm` user (default: `openGauss@123`)
   - Database admin password (default: `openGauss@123`)

## What Gets Installed

- openGauss database version `6.0.0`.
- Required system dependencies on both primary and standby.
- Multinode cluster deployment with one primary and one standby node.
- Default paths:
  - Application: `/opt/huawei/install/app`
  - Logs: `/var/log/omm`
  - Tools: `/opt/huawei/install/om`
  - Core files: `/opt/huawei/install/corefile`

## Post-Installation

Once installation completes successfully, verify cluster status:

```bash
su - omm
gs_om -t status --detail
```

To connect to the database from the `omm` user:

```bash
gsql -d postgres -p 15400
```

## Default Configuration

- **Cluster Name**: `dbCluster`
- **Primary Node**: Primary server hostname entered during setup
- **Standby Node**: Standby server hostname entered during setup
- **Database Port**: `15400`
- **User**: `omm` (database administrator)
- **Database**: `postgres`

## Troubleshooting

- Check installation logs in `/var/log/omm/`.
- Ensure SSH connectivity from the primary node to the standby node.
- Confirm the standby node has root access available and the same root password.
- Verify network access for package downloads.
- Confirm available disk space and correct OS version.

## Best Practices

- Use a dedicated network or VLAN for database node communication.
- Ensure the primary and standby hostnames are unique and resolvable.
- Change default passwords after installation.
- Re-enable firewall and SELinux after installation once the cluster is validated.

## Security Notes

- The script disables the firewall and SELinux for installation convenience.
- Review and re-enable security controls in production environments.
- Change default passwords after installation.
- Secure SSH access between nodes and limit root login as needed.

## Support

For issues or questions about openGauss, refer to the official documentation at [opengauss.org](https://opengauss.org).