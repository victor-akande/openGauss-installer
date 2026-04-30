#!/bin/bash
# ==============================================================================
# openGauss Single-Node Interactive Installation Script
# Based on the Official Enterprise Deployment Guide
# ==============================================================================

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31mError: Please run this script as root.\e[0m"
  exit 1
fi

echo -e "\e[34m=================================================================\e[0m"
echo -e "\e[34m      openGauss Single-Node Interactive Installer                \e[0m"
echo -e "\e[34m=================================================================\e[0m"
echo ""

# ------------------------------------------------------------------------------
# 1. Gather User Inputs
# ------------------------------------------------------------------------------
# Detect default IP and Hostname
DEFAULT_IP=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{print $7}' | tr -d '\n')
if [ -z "$DEFAULT_IP" ]; then
    DEFAULT_IP=$(hostname -I | awk '{print $1}')
fi
DEFAULT_HOSTNAME=$(hostname)

read -p "Enter server IP address [$DEFAULT_IP]: " IP_ADDR
IP_ADDR=${IP_ADDR:-$DEFAULT_IP}

read -p "Enter server hostname [$DEFAULT_HOSTNAME]: " HOST_NAME
HOST_NAME=${HOST_NAME:-$DEFAULT_HOSTNAME}

read -p "Enter the OS password for the 'omm' user [openGauss@123]: " OS_PASSWORD
OS_PASSWORD=${OS_PASSWORD:-openGauss@123}

read -p "Enter Database Admin Password (Must contain upper/lower case, numbers, and symbols) [openGauss@123]: " DB_PASSWORD
DB_PASSWORD=${DB_PASSWORD:-openGauss@123}

# Determine System Architecture automatically
SYS_ARCH=$(uname -m)
if [ "$SYS_ARCH" == "x86_64" ]; then
    DIR_ARCH="x86"
    PKG_ARCH="x86_64"
elif [ "$SYS_ARCH" == "aarch64" ]; then
    DIR_ARCH="arm"
    PKG_ARCH="aarch64"
else
    echo -e "\e[31mError: Unsupported architecture $SYS_ARCH. Only x86_64 and aarch64 are supported.\e[0m"
    exit 1
fi

# Determine openEuler version (>= 22 uses 22.03, < 22 uses 20.03)
ACTUAL_VER=$(grep -E '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d '=' -f 2 | tr -d '"')
MAJOR_VER=$(echo "$ACTUAL_VER" | cut -d '.' -f 1)

if [[ -z "$MAJOR_VER" || ! "$MAJOR_VER" =~ ^[0-9]+$ ]]; then
    # Fallback if parsing fails
    OS_VER="20.03"
elif [ "$MAJOR_VER" -ge 22 ]; then
    OS_VER="22.03"
else
    OS_VER="20.03"
fi
OS_NAME="openEuler${OS_VER}"

# Default parameters for openGauss minimum version 6.0.0
OG_VERSION="6.0.0"
DEFAULT_URL="https://opengauss.obs.cn-south-1.myhuaweicloud.com/${OG_VERSION}/${OS_NAME}/${DIR_ARCH}/openGauss-All-${OG_VERSION}-${OS_NAME}-${PKG_ARCH}.tar.gz"

echo ""
echo -e "\e[36mDetected Architecture: $SYS_ARCH\e[0m"
echo -e "\e[36mTarget OS: $OS_NAME\e[0m"
echo -e "\e[36mTarget Version: $OG_VERSION\e[0m"
read -p "Enter openGauss package download URL [Press Enter to use default]: " OG_URL
OG_URL=${OG_URL:-$DEFAULT_URL}

echo -e "\n\e[33m>>> Starting Installation Process...\e[0m"

# ------------------------------------------------------------------------------
# 2. System Preparation (Hostname, Hosts, Firewall, SELinux)
# ------------------------------------------------------------------------------
echo -e "\e[32m[1/8] Configuring system basics (Hostname, Firewall, SELinux)...\e[0m"

# Set Hostname
hostnamectl set-hostname "$HOST_NAME"

# Update /etc/hosts (Remove old entries of the IP to avoid duplicates, then append)
sed -i "/$IP_ADDR/d" /etc/hosts
sed -i "/$HOST_NAME/d" /etc/hosts
echo "$IP_ADDR $HOST_NAME" >> /etc/hosts

# Disable Firewall
systemctl stop firewalld 2>/dev/null
systemctl disable firewalld 2>/dev/null

# Disable SELinux
if [ -f /etc/selinux/config ]; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0 2>/dev/null
fi

# ------------------------------------------------------------------------------
# 3. Install Dependencies
# ------------------------------------------------------------------------------
echo -e "\e[32m[2/8] Installing required OS packages...\e[0m"
# Removed 'redhat-lsb-core' and silent output so it successfully installs on openEuler
yum install -y bzip2 bzip2-devel curl libaio libaio-devel flex bison \
               ncurses-devel glibc-devel patch readline-devel \
               python3 expect zlib-devel tar wget

# Explicitly ensure libaio.so symlinks exist for gs_checkos if it gets picky
if [ -f /usr/lib64/libaio.so.1 ] && [ ! -f /usr/lib64/libaio.so ]; then
    ln -sf /usr/lib64/libaio.so.1 /usr/lib64/libaio.so
fi
if [ -f /usr/lib/libaio.so.1 ] && [ ! -f /usr/lib/libaio.so ]; then
    ln -sf /usr/lib/libaio.so.1 /usr/lib/libaio.so
fi

# ------------------------------------------------------------------------------
# 4. Download and Extract openGauss
# ------------------------------------------------------------------------------
echo -e "\e[32m[3/8] Downloading and extracting openGauss package...\e[0m"
INSTALL_DIR="/opt/software/openGauss"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

# Download the tarball
echo "Downloading openGauss from: $OG_URL"
wget -q --show-progress -O openGauss-all.tar.gz "$OG_URL"

# Extract all package
tar -zxf openGauss-all.tar.gz

# Find and extract the OM (Operations Management) package inside
OM_TAR=$(find . -maxdepth 1 -iname "*om*.tar.gz" | head -n 1)
if [ -n "$OM_TAR" ]; then
    echo -e "Found OM Package: $OM_TAR"
    tar -zxf "$OM_TAR"
else
    echo -e "\e[31mError: OM package not found in the downloaded tarball.\e[0m"
    exit 1
fi

chmod -R 755 "$INSTALL_DIR"

# ------------------------------------------------------------------------------
# 5. Pre-create omm user (Bypasses gs_preinstall password prompt)
# ------------------------------------------------------------------------------
echo -e "\e[32m[4/8] Creating 'omm' user and 'dbgrp' group...\e[0m"
groupadd dbgrp 2>/dev/null
useradd -g dbgrp -d /home/omm -m -s /bin/bash omm 2>/dev/null
echo "$OS_PASSWORD" | passwd --stdin omm >/dev/null 2>&1

# ------------------------------------------------------------------------------
# 6. Generate 1-node.xml Configuration
# ------------------------------------------------------------------------------
echo -e "\e[32m[5/8] Generating 1-node.xml configuration...\e[0m"
XML_FILE="$INSTALL_DIR/1-node.xml"

cat > "$XML_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<ROOT>
    <!-- openGauss cluster information -->
    <CLUSTER>
        <PARAM name="clusterName" value="dbCluster" />
        <PARAM name="nodeNames" value="$HOST_NAME" />
        <PARAM name="backIp1s" value="$IP_ADDR"/>
        <PARAM name="gaussdbAppPath" value="/opt/huawei/install/app" />
        <PARAM name="gaussdbLogPath" value="/var/log/omm" />
        <PARAM name="gaussdbToolPath" value="/opt/huawei/install/om" />
        <PARAM name="corePath" value="/opt/huawei/install/corefile"/>
        <PARAM name="clusterType" value="single-inst"/>
    </CLUSTER>
    <!-- Node deployment information -->
    <DEVICELIST>
        <DEVICE sn="$HOST_NAME">
            <PARAM name="name" value="$HOST_NAME"/>
            <PARAM name="azName" value="AZ1"/>
            <PARAM name="azPriority" value="1"/>
            <PARAM name="backIp1" value="$IP_ADDR"/>
            <PARAM name="sshIp1" value="$IP_ADDR"/>
            <!-- dn -->
            <PARAM name="dataNum" value="1"/>
            <PARAM name="dataPortBase" value="15400"/>
            <PARAM name="dataNode1" value="/opt/huawei/install/data/dn"/>
            <PARAM name="dataNode1_syncNum" value="0"/>
        </DEVICE>
    </DEVICELIST>
</ROOT>
EOF

chmod 644 "$XML_FILE"

# ------------------------------------------------------------------------------
# 7. Execute gs_preinstall
# ------------------------------------------------------------------------------
echo -e "\e[32m[6/8] Executing gs_preinstall...\e[0m"
cd "$INSTALL_DIR/script" || exit

# Piping yes "yes" handles the "Are you sure you want to create the user[omm] (yes/no)?" prompt automatically
yes "yes" | python3 gs_preinstall -U omm -G dbgrp -X "$XML_FILE"

if [ $? -ne 0 ]; then
    echo -e "\e[31mError: gs_preinstall failed. Please check the logs.\e[0m"
    exit 1
fi

# ------------------------------------------------------------------------------
# 8. Execute gs_install
# ------------------------------------------------------------------------------
echo -e "\e[32m[7/8] Executing gs_install...\e[0m"

# The enterprise version of gs_install uses interactive prompts for the password
# instead of the -w parameter. We use 'expect' to automate this securely.
EXPECT_SCRIPT="/home/omm/run_install.exp"
PASS_FILE="/home/omm/.dbpass"

printf "%s" "$DB_PASSWORD" > "$PASS_FILE"
chown omm:dbgrp "$PASS_FILE"
chmod 600 "$PASS_FILE"

cat > "$EXPECT_SCRIPT" <<'EOF'
#!/usr/bin/expect
set timeout -1

# Read the password securely
set fp [open "/home/omm/.dbpass" r]
set DB_PASSWORD [read -nonewline $fp]
close $fp

# Retrieve XML file from arguments
set XML_FILE [lindex $argv 0]

spawn gs_install -X $XML_FILE
expect {
    "Please enter password for database:" {
        send "$DB_PASSWORD\r"
        exp_continue
    }
    "Please repeat for database:" {
        send "$DB_PASSWORD\r"
        exp_continue
    }
    eof
}
catch wait result
exit [lindex $result 3]
EOF

chmod +x "$EXPECT_SCRIPT"
chown omm:dbgrp "$EXPECT_SCRIPT"

su - omm -c "$EXPECT_SCRIPT $XML_FILE"
INSTALL_EXIT_CODE=$?

# Cleanup sensitive files
rm -f "$EXPECT_SCRIPT" "$PASS_FILE"

if [ $INSTALL_EXIT_CODE -ne 0 ]; then
    echo -e "\e[31mError: gs_install failed. Please check the logs in /var/log/omm.\e[0m"
    exit 1
fi

# ------------------------------------------------------------------------------
# 9. Finalization
# ------------------------------------------------------------------------------
echo -e "\e[32m[8/8] Installation Complete!\e[0m"
echo -e "\e[34m=================================================================\e[0m"
echo -e "Database is successfully installed and running!"
echo -e "To access the database, run the following commands:"
echo -e "  \e[33msu - omm\e[0m"
echo -e "  \e[33mgsql -d postgres -p 15400\e[0m"
echo -e "\e[34m=================================================================\e[0m"