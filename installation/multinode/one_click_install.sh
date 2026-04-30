#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31mError: Please run this script as root.\e[0m"
  exit 1
fi

echo -e "\e[32m=================================================================\e[0m"
echo -e "\e[32m    openGauss Primary/Standby Interactive Installer              \e[0m"
echo -e "\e[32m=================================================================\e[0m"
echo ""

# ------------------------------------------------------------------------------
# 1. Gather User Inputs
# ------------------------------------------------------------------------------
DEFAULT_IP=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{print $7}' | tr -d '\n')
if [ -z "$DEFAULT_IP" ]; then
    DEFAULT_IP=$(hostname -I | awk '{print $1}')
fi
DEFAULT_HOSTNAME=$(hostname)

echo -e "\e[33m--- Primary Node Details ---\e[0m"
read -p "Enter Primary server IP address [$DEFAULT_IP]: " PRIMARY_IP
PRIMARY_IP=${PRIMARY_IP:-$DEFAULT_IP}

read -p "Enter Primary server hostname [$DEFAULT_HOSTNAME]: " PRIMARY_HOST
PRIMARY_HOST=${PRIMARY_HOST:-$DEFAULT_HOSTNAME}

echo -e "\n\e[33m--- Standby Node Details ---\e[0m"
read -p "Enter Standby server IP address: " STANDBY_IP
read -p "Enter Standby server hostname (e.g., node2): " STANDBY_HOST

echo -e "\n\e[33m--- Passwords ---\e[0m"
read -p "Enter the Root password (Must be the SAME on both Primary and Standby): " ROOT_PASSWORD
read -p "Enter the OS password for the 'omm' user [openGauss@123]: " OS_PASSWORD
OS_PASSWORD=${OS_PASSWORD:-openGauss@123}
read -p "Enter Database Admin Password (Upper/lower case, numbers, symbols) [openGauss@123]: " DB_PASSWORD
DB_PASSWORD=${DB_PASSWORD:-openGauss@123}

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

ACTUAL_VER=$(grep -E '^VERSION_ID=' /etc/os-release 2>/dev/null | cut -d '=' -f 2 | tr -d '"')
MAJOR_VER=$(echo "$ACTUAL_VER" | cut -d '.' -f 1)

if [[ -z "$MAJOR_VER" || ! "$MAJOR_VER" =~ ^[0-9]+$ ]]; then
    OS_VER="20.03"
elif [ "$MAJOR_VER" -ge 22 ]; then
    OS_VER="22.03"
else
    OS_VER="20.03"
fi
OS_NAME="openEuler${OS_VER}"

OG_VERSION="6.0.0"
DEFAULT_URL="https://opengauss.obs.cn-south-1.myhuaweicloud.com/${OG_VERSION}/${OS_NAME}/${DIR_ARCH}/openGauss-All-${OG_VERSION}-${OS_NAME}-${PKG_ARCH}.tar.gz"

echo ""
echo -e "\e[36mDetected Architecture: $SYS_ARCH\e[0m"
echo -e "\e[36mTarget OS: $OS_NAME\e[0m"
echo -e "\e[36mTarget Version: $OG_VERSION\e[0m"
read -p "Enter openGauss package download URL [Press Enter to use default]: " OG_URL
OG_URL=${OG_URL:-$DEFAULT_URL}

echo -e "\n\e[33m>>> Starting Multinode Installation Process...\e[0m"

# ------------------------------------------------------------------------------
# 2. Local System Preparation (Primary Node)
# ------------------------------------------------------------------------------
echo -e "\e[32m[1/8] Configuring local system (Primary) basics and dependencies...\e[0m"

hostnamectl set-hostname "$PRIMARY_HOST"

sed -i "/$PRIMARY_IP/d" /etc/hosts
sed -i "/$STANDBY_IP/d" /etc/hosts
echo "$PRIMARY_IP $PRIMARY_HOST" >> /etc/hosts
echo "$STANDBY_IP $STANDBY_HOST" >> /etc/hosts

systemctl stop firewalld 2>/dev/null
systemctl disable firewalld 2>/dev/null

if [ -f /etc/selinux/config ]; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0 2>/dev/null
fi

yum install -y bzip2 bzip2-devel curl libaio libaio-devel flex bison \
               ncurses-devel glibc-devel patch readline-devel \
               python3 expect zlib-devel tar wget >/dev/null 2>&1

if [ -f /usr/lib64/libaio.so.1 ] && [ ! -f /usr/lib64/libaio.so ]; then
    ln -sf /usr/lib64/libaio.so.1 /usr/lib64/libaio.so
fi
if [ -f /usr/lib/libaio.so.1 ] && [ ! -f /usr/lib/libaio.so ]; then
    ln -sf /usr/lib/libaio.so.1 /usr/lib/libaio.so
fi

# ------------------------------------------------------------------------------
# 3. Remote System Preparation (Standby Node)
# ------------------------------------------------------------------------------
echo -e "\e[32m[2/8] Configuring remote system (Standby) basics and dependencies...\e[0m"

cat > /tmp/prep_standby.exp <<EOF
#!/usr/bin/expect
set timeout -1
spawn ssh -o StrictHostKeyChecking=no root@$STANDBY_IP "hostnamectl set-hostname $STANDBY_HOST ; sed -i '/$PRIMARY_IP/d' /etc/hosts ; sed -i '/$STANDBY_IP/d' /etc/hosts ; echo '$PRIMARY_IP $PRIMARY_HOST' >> /etc/hosts ; echo '$STANDBY_IP $STANDBY_HOST' >> /etc/hosts ; systemctl stop firewalld ; systemctl disable firewalld ; sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config ; setenforce 0 ; rm -rf /opt/huawei/install /var/log/omm ; userdel -r omm 2>/dev/null ; groupdel dbgrp 2>/dev/null ; yum install -y bzip2 bzip2-devel curl libaio libaio-devel flex bison ncurses-devel glibc-devel patch readline-devel python3 expect zlib-devel tar wget ; if test -f /usr/lib64/libaio.so.1 && test ! -f /usr/lib64/libaio.so; then ln -sf /usr/lib64/libaio.so.1 /usr/lib64/libaio.so; fi ; if test -f /usr/lib/libaio.so.1 && test ! -f /usr/lib/libaio.so; then ln -sf /usr/lib/libaio.so.1 /usr/lib/libaio.so; fi"
expect {
    "password:" {
        send "$ROOT_PASSWORD\r"
        exp_continue
    }
    eof
}
EOF

chmod +x /tmp/prep_standby.exp
/tmp/prep_standby.exp
rm -f /tmp/prep_standby.exp

echo -e "\e[32m[3/8] Downloading and extracting openGauss package...\e[0m"
INSTALL_DIR="/opt/software/openGauss"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

wget -q --show-progress -O openGauss-all.tar.gz "$OG_URL"
tar -zxf openGauss-all.tar.gz

OM_TAR=$(find . -maxdepth 1 -iname "*om*.tar.gz" | head -n 1)
if [ -n "$OM_TAR" ]; then
    tar -zxf "$OM_TAR"
else
    echo -e "\e[31mError: OM package not found in the downloaded tarball.\e[0m"
    exit 1
fi

chmod -R 755 "$INSTALL_DIR"

# ------------------------------------------------------------------------------
# 5. Generate Multinode XML Configuration
# ------------------------------------------------------------------------------
echo -e "\e[32m[4/8] Generating 1-primary-1-standby.xml configuration...\e[0m"
XML_FILE="$INSTALL_DIR/1-primary-1-standby.xml"

cat > "$XML_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<ROOT>
    <!-- openGauss cluster information -->
    <CLUSTER>
        <PARAM name="clusterName" value="dbCluster" />
        <PARAM name="nodeNames" value="$PRIMARY_HOST,$STANDBY_HOST" />
        <PARAM name="backIp1s" value="$PRIMARY_IP,$STANDBY_IP"/>
        <PARAM name="gaussdbAppPath" value="/opt/huawei/install/app" />
        <PARAM name="gaussdbLogPath" value="/var/log/omm" />
        <PARAM name="gaussdbToolPath" value="/opt/huawei/install/om" />
        <PARAM name="corePath" value="/opt/huawei/install/corefile"/>
        <PARAM name="clusterType" value="single-inst"/>
    </CLUSTER>
    <!-- Node deployment information -->
    <DEVICELIST>
        <DEVICE sn="$PRIMARY_HOST">
            <PARAM name="name" value="$PRIMARY_HOST"/>
            <PARAM name="azName" value="AZ1"/>
            <PARAM name="azPriority" value="1"/>
            <PARAM name="backIp1" value="$PRIMARY_IP"/>
            <PARAM name="sshIp1" value="$PRIMARY_IP"/>
            <!-- dn -->
            <PARAM name="dataNum" value="1"/>
            <PARAM name="dataPortBase" value="15400"/>
            <PARAM name="dataNode1" value="/opt/huawei/install/data/dn,$STANDBY_HOST,/opt/huawei/install/data/dn"/>
            <PARAM name="dataNode1_syncNum" value="0"/>
        </DEVICE>
        <!-- Standby Node strictly defines host mapping, avoiding local primary reassignment conflicts -->
        <DEVICE sn="$STANDBY_HOST">
            <PARAM name="name" value="$STANDBY_HOST"/>
            <PARAM name="azName" value="AZ1"/>
            <PARAM name="azPriority" value="1"/>
            <PARAM name="backIp1" value="$STANDBY_IP"/>
            <PARAM name="sshIp1" value="$STANDBY_IP"/>
        </DEVICE>
    </DEVICELIST>
</ROOT>
EOF

chmod 644 "$XML_FILE"

# ------------------------------------------------------------------------------
# 6. Pre-create omm user (Primary Node)
# ------------------------------------------------------------------------------
echo -e "\e[32m[5/8] Creating 'omm' user locally...\e[0m"
rm -rf /opt/huawei/install /var/log/omm
userdel -r omm 2>/dev/null
groupdel dbgrp 2>/dev/null

groupadd dbgrp 2>/dev/null
useradd -g dbgrp -d /home/omm -m -s /bin/bash omm 2>/dev/null
echo "$OS_PASSWORD" | passwd --stdin omm >/dev/null 2>&1

# ------------------------------------------------------------------------------
# 7. Execute gs_preinstall (Automated Mutual Trust)
# ------------------------------------------------------------------------------
echo -e "\e[32m[6/8] Executing gs_preinstall and building mutual trust...\e[0m"
cd "$INSTALL_DIR/script" || exit

cat > /tmp/run_preinstall.exp <<EOF
#!/usr/bin/expect
set timeout -1
spawn python3 gs_preinstall -U omm -G dbgrp -X $XML_FILE
expect {
    "Are you sure you want to create trust for root" {
        send "yes\r"
        exp_continue
    }
    "Please enter password for root" {
        send "$ROOT_PASSWORD\r"
        exp_continue
    }
    -ex "current user\[root\]" {
        expect "assword:"
        send "$ROOT_PASSWORD\r"
        exp_continue
    }
    "Are you sure you want to create the user" {
        send "yes\r"
        exp_continue
    }
    "password for cluster user" {
        expect "assword:"
        send "$OS_PASSWORD\r"
        exp_continue
    }
    -ex "current user\[omm\]" {
        expect "assword:"
        send "$OS_PASSWORD\r"
        exp_continue
    }
    "The password is incorrect" {
        send_user "\n\n\033\[33m>>> Interactive Fallback: Automation Paused! Please type the password manually. <<<\033\[0m\n\n"
        interact
    }
    eof
}
catch wait result
exit [lindex \$result 3]
EOF

chmod +x /tmp/run_preinstall.exp
/tmp/run_preinstall.exp
PREINSTALL_EXIT_CODE=$?
rm -f /tmp/run_preinstall.exp

if [ $PREINSTALL_EXIT_CODE -ne 0 ]; then
    echo -e "\e[31mError: gs_preinstall failed. Please check the logs.\e[0m"
    exit 1
fi

# ------------------------------------------------------------------------------
# 8. Execute gs_install
# ------------------------------------------------------------------------------
echo -e "\e[32m[7/8] Executing gs_install to deploy the cluster...\e[0m"

EXPECT_SCRIPT="/home/omm/run_install.exp"
PASS_FILE="/home/omm/.dbpass"

printf "%s" "$DB_PASSWORD" > "$PASS_FILE"
chown omm:dbgrp "$PASS_FILE"
chmod 600 "$PASS_FILE"

cat > "$EXPECT_SCRIPT" <<'EOF'
#!/usr/bin/expect
set timeout -1

set fp [open "/home/omm/.dbpass" r]
set DB_PASSWORD [read -nonewline $fp]
close $fp

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
    "The password is incorrect" {
        send_user "\n\n\033\[33m>>> Interactive Fallback: Automation Paused! Please type the password manually. <<<\033\[0m\n\n"
        interact
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

rm -f "$EXPECT_SCRIPT" "$PASS_FILE"

if [ $INSTALL_EXIT_CODE -ne 0 ]; then
    echo -e "\e[31mError: gs_install failed. Please check the logs in /var/log/omm.\e[0m"
    exit 1
fi

# ------------------------------------------------------------------------------
# 9. Finalization
# ------------------------------------------------------------------------------
echo -e "\e[32m[8/8] Cluster Installation Complete!\e[0m"
echo -e "\e[32m=================================================================\e[0m"
echo -e "Primary/Standby Database Cluster is successfully installed and running!"
echo -e "To access the database or check cluster status, run:"
echo -e "  \e[33msu - omm\e[0m"
echo -e "  \e[33mgs_om -t status --detail\e[0m"
echo -e "\e[32m=================================================================\e[0m"