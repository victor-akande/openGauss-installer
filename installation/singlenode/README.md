# Single-Node openGauss Configuration

## Installation Options

For a streamlined deployment, consider using the [one-click installer script](./one_click_install.sh) which automates the entire installation process. This script handles system preparation, dependency installation, package download, and database setup in a single run.

- **[one_click_install.sh](./one_click_install.sh)**: Interactive installer script for openGauss single-node deployment
- **[README_one_click_install.sh.md](./README_one_click_install.sh.md)**: Detailed documentation for the one-click installer

The installer script is recommended for most users as it simplifies the setup process while maintaining flexibility through interactive prompts.

- **Source:** [installation/singlenode/1-node.xml](./1-node.xml)

**Overview**
- **Purpose:** A minimal XML template for deploying openGauss on a single node.
- **Scope:** Contains deployment settings (paths, IPs, ports, and node details) used by the installer scripts in this folder.

**Header (simplified & rephrased)**
- This file is a basic template for deploying openGauss on one server.
- Do not use it as-is you must review and adapt the values to your environment.
- Change configuration options as required to meet your deployment needs.
- Replace placeholder values (for example, entries like {{192.168.0.1}}) with the real IPs and settings for your system.

**Why this matters**
- **Safety:** Placeholders may point to generic or insecure defaults, leaving them unchanged can break the install or expose resources.
- **Correctness:** Paths, ports, and AZ/priority values must reflect your topology or the cluster will not start correctly.
- **Troubleshooting:** The header documents expectations for the rest of the XML; incorrect header values cause cascading errors during install.

**How to use this file**
1. Make a working copy: 
```bash
cp installation/singlenode/1-node.xml installation/singlenode/1-node.custom.xml
```
2. Replace every `{{...}}` placeholder with your actual values (IP addresses, hostnames, base ports, paths).
3. Verify paths exist and permissions are correct for directories like `/opt/huawei/install` and `/var/log/omm`.
4. Confirm `dataPortBase` and other ports do not conflict with existing services.
5. Run the installer script in this repo (`installation/init.sh`) according to its instructions.

**Important warnings**
- **Back up** configuration files before editing.
- **Do not commit** files with environment-specific secrets or real production IPs to public repos.
- Validate changes in a staging environment before production.

**Notes & References**
- Installer entry: [installation/init.sh](../init.sh)
- Single-node template: [installation/singlenode/1-node.xml](./1-node.xml)

**Placeholders to Replace (from `1-node.xml`)**
- **Line 6:** `{{huawei}}` : Replace with your cluster name (example: `mycluster` or `prod-cluster`). Use a short, unique identifier (no spaces).
- **Line 8:** `{{db}}` : Replace with the database node hostname (example: `db1.example.com` or `db1`). Ensure this name resolves via DNS or `/etc/hosts`.
- **Line 20:** `{{192.168.0.1}}` : Replace with the node's internal/back-end IP used for database traffic (must be reachable from other cluster nodes).
- **Line 25:** `{{db}}` (in `DEVICE sn`) : Same as node hostname; keep consistent with `nodeNames` and `name`.
- **Line 27:** `{{db}}` : Hostname used by the installer; replace with the server's hostname.
- **Line 32:** `{{192.168.0.1}}` : `backIp1` for the node: set to the management/internal NIC IP.
- **Line 33:** `{{192.168.0.1}}` : `sshIp1` for the node: set to the IP used for SSH access (can be same as `backIp1`).
- **Line 37:** `{{15400}}` : `dataPortBase`: set an available base port for data node instances (example: `15400`, `15410`); ensure it does not conflict with other services and is consistent across nodes.

Tips:
- Use consistent hostnames and IPs across all config files and DNS/hosts entries.
- Prefer private/internal IPs for `backIp1`/`backIp1s` and `sshIp1`.
- Verify ports are open and not blocked by firewalls.

**Next steps: Run preinstall**
- Ensure the `omm` user and `dbgrp` group exist on the target host and you have appropriate privileges (usually root).
- Change to the installer script directory and run the `gs_preinstall` utility, pointing it at your cluster XML:

```bash
cd /opt/software/openGauss/script/
./gs_preinstall -U omm -G dbgrp -X /path/to/your/cluster/config/file.xml
```

- Example (replace with your actual config path):

```bash
./gs_preinstall -U omm -G dbgrp -X /opt/software/openGauss/cluster_config.xml
```

- Notes:
  - Use the full path to your config XML (for single-node this might be `installation/singlenode/1-node.xml` or a customized copy).
  - Verify the script is executable (`chmod +x ./gs_preinstall`) and that required ports and directories are ready.
  - Run the preinstall from a host that can reach the target node IPs listed in the XML.

**Install: Run installer and verify**
- Switch to the installer directory and become the `omm` user, then run the installer and check status:

```bash
su - omm
cd /opt/software/openGauss/script/
./gs_install -X /opt/software/openGauss/cluster_config.xml --gsinit-parameter="--encoding=UTF8"
gs_om -t status --detail
```

- Notes:
  - `su - omm` runs the rest of the commands as the `omm` installation user (use the login shell to load environment variables).
  - Replace `/opt/software/openGauss/cluster_config.xml` with the actual path to your cluster XML (for single-node this may be `installation/singlenode/1-node.custom.xml`).
  - If `gs_install` or `gs_om` are not found, ensure the OpenGauss script directory is correct and the tools are executable (`chmod +x`).
  - After `gs_install` completes, `gs_om -t status --detail` reports node status and any post-install issues to address.
