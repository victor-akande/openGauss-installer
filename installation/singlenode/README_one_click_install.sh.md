# openGauss Single-Node One-Click Installer

## Overview

The `one_click_install.sh` script provides a streamlined, automated installation process for deploying the openGauss database on a single node. Designed for simplicity and efficiency, this script handles the entire setup from system configuration to database initialization, making it a true "one-click" solution for getting openGauss up and running quickly.

## Features

- **Automated System Preparation**: Configures hostname, hosts file, firewall, and SELinux settings
- **Dependency Installation**: Automatically installs all required OS packages and libraries
- **Package Download & Extraction**: Downloads the latest openGauss package and extracts it
- **User Management**: Creates the necessary 'omm' user and 'dbgrp' group
- **Configuration Generation**: Generates the XML configuration file for single-node deployment
- **Pre-installation Setup**: Runs gs_preinstall to prepare the environment
- **Database Installation**: Executes gs_install with automated password handling
- **Architecture Detection**: Supports both x86_64 and aarch64 architectures
- **Interactive Prompts**: Guides users through required inputs with sensible defaults

## Prerequisites

- **Operating System**: openEuler 20.03 or 22.03 (automatically detected)
- **Architecture**: x86_64 or aarch64
- **Permissions**: Must be run as root (sudo)
- **Network**: Internet connection for downloading packages
- **Disk Space**: Sufficient space in /opt for installation (approximately 2-3 GB recommended)

## Usage

1. **Navigate to the script directory**:
   ```bash
   cd /path/to/openGauss-installer/installation/singlenode
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
   - Server IP address (detected automatically)
   - Server hostname (detected automatically)
   - OS password for 'omm' user (default: openGauss@123)
   - Database admin password (default: openGauss@123, must meet complexity requirements)

## What Gets Installed

- openGauss database version 6.0.0
- All necessary system dependencies
- Database cluster with single node configuration
- Default database paths:
  - Application: `/opt/huawei/install/app`
  - Logs: `/var/log/omm`
  - Data: `/opt/huawei/install/data/dn`
  - Tools: `/opt/huawei/install/om`

## Post-Installation

Once installation completes successfully, you can access the database:

```bash
# Switch to the omm user
su - omm

# Connect to the database
gsql -d postgres -p 15400
```

## Default Configuration

- **Database Port**: 15400
- **Cluster Name**: dbCluster
- **Node Name**: Your hostname
- **User**: omm (database administrator)
- **Database**: postgres (default database)

## Troubleshooting

- Check installation logs in `/var/log/omm/`
- Ensure all prerequisites are met before running
- Verify network connectivity for package downloads
- Confirm sufficient disk space and permissions

## Security Notes

- Change default passwords after installation
- Review firewall and SELinux settings for production environments
- The script disables firewall and SELinux for installation convenience; re-enable as needed

## Support

For issues or questions about openGauss, refer to the official documentation at [opengauss.org](https://opengauss.org).</content>
<parameter name="filePath">/workspaces/openGauss-installer/installation/singlenode/README_install.sh.md