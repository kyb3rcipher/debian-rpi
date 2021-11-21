#!/bin/bash

#--------------------------------------
# Debian arm raspberry pi builder
# LICENSE: MIT
# By: Kyb3r Vizsla <kyb3rvizsla.com>
#---------------------------------------

source example.conf
source custom.conf 2> /dev/null

# Variables
base_packages="ca-certificates wget curl gnupg cron rsyslog"
packages="$base_packages $custom_packages"
# Colors
endColor="\e[0m\e[0m"
redColor="\e[0;31m\e[1m"
blueColor="\e[0;34m\e[1m"
cyanColor="\e[01;96m\e[1m"
grayColor="\e[0;37m\e[1m"
greenColor="\e[0;32m\e[1m"
purpleColor="\e[0;35m\e[1m"
yellowColor="\e[0;33m\e[1m"
turquoiseColor="\e[0;36m\e[1m"
dot="${redColor}[${endColor}${yellowColor}*${endColor}${redColor}]${endColor}"

# Preparation
rm -rf $word_dir 2> /dev/null
mkdir $work_dir

# First stage
echo -e "\n$dot$greenColor Starting first stage...$endColor"
eatmydata debootstrap --foreign --arch="$architecture" $debian_release $rootfs
echo "$(date +"DAY: %d MONTH: %b HOUR: %I MINUTE: %M SECOND: %S")" > $work_dir/build-date.txt

# Second stage
echo -e "\n$dot$greenColor Starting second stage...$endColor"
if [ "$architecture" == "arm64" ]
then
    cp /usr/bin/qemu-aarch64-static $rootfs/usr/bin
else
    cp /usr/bin/qemu-arm-static $rootfs/usr/bin
fi
chroot $rootfs apt update
chroot $rootfs apt install -y eatmydata
chroot $rootfs eatmydata /debootstrap/debootstrap --second-stage

# Install packages
chroot $rootfs <<_EOF
echo -e "\n$dot$green Installing packages...$endColor"
apt install -y $packages
_EOF

# Set mounting system files
echo -e "\n${yellowColor}Setting mounting systm files...$endColor"
cat >$rootfs/etc/fstab <<EOM
# <file system>   <dir>           <type>  <options>         <dump>  <pass>
proc              /proc           proc    defaults          0       0
/dev/mmcblk0p1    /boot           vfat    defaults          0       2
/dev/mmcblk0p2    /               $fstype    defaults,noatime  0       1
EOM

# Configure networking
echo -e "\n${yellowColor}Configuring netorking...$endColor"
chroot $rootfs apt install -y resolvconf
chroot $rootfs systemctl enable resolvconf
chroot $rootfs systemctl enable NetworkManager
rm -rf $rootfs/etc/resolv.conf
cat >$rootfs/etc/resolv.conf <<EOM
nameserver $name_server

# Examples:
# Google
nameserver 8.8.8.8

# Cloudflare
#nameserver 1.1.1.1
EOM

# Setting...
echo -e "\n$dot$greenColor Starting settings...$endColor"

# Set hosts files
echo -e "\n${yellowColor}Setting hosts...$endColor"
cat >$rootfs/etc/hosts <<EOM
127.0.1.1       ${host_name}
127.0.0.1       localhost
::1             localhostnet.ifnames=0 ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOM
rm $rootfs/hostname
 echo "$host_name" > $ROOTFS/etc/hostname

# Set users
echo -e "${yellowColor}Setting users$endColor"
chroot $rootfs <<_EOF
echo "root:${root_password}" | chpasswd
_EOF

# Set timezone
echo -e "${yellowColor}Setting timezone$endColor"
apt install -y tzdata
chroot $rootfs <<_EOF
ln -nfs /usr/share/zoneinfo/$timezone /etc/localtime
dpkg-reconfigure -fnoninteractive tzdata
_EOF

# Set locales
echo -e "${yellowColor}Setting locales$endColor"
apt install -y locales
sed -i "s/^# *\($locale\)/\1/" $rootfs/etc/locale.gen
chroot $rootfs locale-gen
echo "LANG=$locale" > $rootfs/etc/locale.conf
cat <<'EOM' > $rootfs/etc/profile.d/default-lang.sh
if [ -z "$LANG" ]; then
source /etc/locale.conf
export LANG
fi
EOM

# Install kernel
echo -e "\n$dot$greenColor Installing kernel...$endColor"
chroot $rootfs apt install -y curl
wget https://raw.githubusercontent.com/raspberrypi/rpi-update/master/rpi-update -O $rootfs/usr/local/sbin/rpi-update
chmod +x $rootfs/usr/local/sbin/rpi-update
chroot $rootfs <<_EOF
SKIP_WARNING=1 SKIP_BACKUP=1 /usr/local/sbin/rpi-update
_EOF

# Install raspberry userland firmware
#chroot $rootfs apt install -y curl binutils cmake build-essential
#git clone https://github.com/raspberrypi/userland.git $rootfs/tmp/userland
#chroot $rootfs <<_EOF
#cd /tmp/userland
#./buildme --aarch64
#_EOF
