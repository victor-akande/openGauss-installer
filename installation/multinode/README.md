# Multinode openGauss Configuration

## Installation Options

For a multinode deployment, use the [one-click installer script](./one_click_install.sh) to automate the setup of a primary and standby openGauss cluster.

- **[one_click_install.sh](./one_click_install.sh)**: Interactive installer script for openGauss Primary/Standby multinode deployment
- **[README_one_click_install.sh.md](./README_one_click_install.sh.md)**: Detailed documentation for the multinode one-click installer

The installer is recommended for most users because it simplifies system preparation, package deployment, and cluster installation across both nodes.

- **Source:** [installation/multinode/1-primary-1-standby.xml](./1-primary-1-standby.xml)

**Overview**
- **Purpose:** A minimal XML template for deploying openGauss with one primary and one standby node.
- **Scope:** Contains deployment settings (paths, IPs, ports, and node details) used by the installer script in this folder.

**Header (simplified & rephrased)**
- This file is a basic template for deploying openGauss across two servers.
- Do not use it as-is; review and adapt values to your environment.
- Change configuration options as required to meet your deployment needs.
- Replace placeholder values with real IPs, hostnames, and settings for your system.

**Why this matters**
- **Safety:** Placeholders may point to generic defaults; leaving them unchanged can break the install or expose resources.
- **Correctness:** Paths, ports, and host mapping must reflect your topology or the cluster will not start correctly.
- **Troubleshooting:** The header documents expectations for the rest of the XML; incorrect values can cause cascading errors.

**How to use this file**
1. Make a working copy:
   ```bash
   cp installation/multinode/1-primary-1-standby.xml installation/multinode/1-primary-1-standby.custom.xml
   ```
2. Replace every placeholder with actual values (IP addresses, hostnames, base ports, paths).
3. Verify paths exist and permissions are correct for directories like `/opt/huawei/install` and `/var/log/omm`.
4. Confirm `dataPortBase` and other ports do not conflict with existing services.
5. Run the multinode installer script in this folder following its documentation.

**Important warnings**
- **Back up** configuration files before editing.
- **Do not commit** files containing environment-specific secrets or real production IPs to public repositories.
- Validate changes in a staging environment before production.

**Notes & References**
- Installer entry: [installation/init.sh](../init.sh)
- Multinode template: [installation/multinode/1-primary-1-standby.xml](./1-primary-1-standby.xml)

**Placeholders to Replace (from `1-primary-1-standby.xml`)**
- **clusterName**: Replace with your cluster identifier (example: `dbCluster` or `prod-cluster`).
- **nodeNames**: Replace with your primary and standby hostnames separated by a comma.
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
