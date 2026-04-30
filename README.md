# openGauss-installer

A collection of installation and deployment scripts for openGauss, Huawei's enterprise database. This repository provides both single-node and multinode installer workflows, along with environment preparation utilities for openEuler systems.

## Repository Structure

- `installation/`
  - `init.sh` - Prepares the Linux environment for openGauss installation (SELinux, firewall, SSH, Python, swap, etc.).
  - `singlenode/`
    - `one_click_install.sh` - Interactive installer for a single-node openGauss deployment.
    - `1-node.xml` - Single-node cluster XML template.
    - `README_one_click_install.sh.md` - Detailed documentation for the single-node installer.
    - `README.md` - Overview of the single-node configuration folder.
  - `multinode/`
    - `one_click_install.sh` - Interactive installer for a primary/standby multinode openGauss deployment.
    - `1-primary-1-standby.xml` - Primary/standby cluster XML template.
    - `README_one_click_install.sh.md` - Detailed documentation for the multinode installer.
    - `README.md` - Overview of the multinode configuration folder.

## What This Repository Is For

This repository is intended to help automate openGauss deployments on openEuler-based systems by:

- Preparing the host environment for openGauss installation.
- Installing dependencies required for openGauss.
- Generating basic cluster configuration files.
- Automating the `gs_preinstall` and `gs_install` steps.
- Providing both single-node and multinode deployment workflows.

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/victor-akande/openGauss-installer.git
   cd openGauss-installer
   ```

2. Review the environment preparation script:
   ```bash
   cat installation/init.sh
   ```

3. Choose your deployment type:
   - Single-node: `installation/singlenode`
   - Multinode: `installation/multinode`

4. Follow the README in the chosen folder:
   - `installation/singlenode/README.md`
   - `installation/multinode/README.md`

## Prerequisites

- openEuler operating system (20.03 or 22.03 recommended).
- Root access to all target nodes.
- For multinode deployments, SSH connectivity from the primary node to the standby node.
- Internet access for package download or a local package mirror.
- Sufficient disk space in `/opt`.

## Usage

### Prepare the Environment

The repository includes `installation/init.sh` to perform common system preparation tasks.

```bash
sudo bash installation/init.sh
```

> Note: `init.sh` reboots the system at the end of execution.

### Single-Node Deployment

Use the single-node installer:

```bash
cd installation/singlenode
chmod +x one_click_install.sh
sudo ./one_click_install.sh
```

Read the single-node installer documentation:

- `installation/singlenode/README_one_click_install.sh.md`

### Multinode Deployment

Use the multinode installer:

```bash
cd installation/multinode
chmod +x one_click_install.sh
sudo ./one_click_install.sh
```

Read the multinode installer documentation:

- `installation/multinode/README_one_click_install.sh.md`

## Best Practices

- Validate all hostnames and IP addresses before running the installer.
- Use consistent naming and network configuration across nodes.
- Change default passwords after installation.
- Re-enable firewall and SELinux after the cluster is validated in production.
- Keep environment-specific secrets out of version control.

## Notes

- The installer scripts assume a basic openEuler environment and may need adjustment for custom setups.
- The XML templates are provided as examples and should be reviewed before use.

## Support

For openGauss help and documentation, visit [https://opengauss.org/en/](https://opengauss.org/en/).
