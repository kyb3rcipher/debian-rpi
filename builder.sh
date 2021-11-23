#!/bin/bash

#--------------------------------------
# Parrot OS arm builder
# LICENSE: MIT
# By: Kyb3r Vizsla <kyb3rvizsla.com>
#---------------------------------------

source example.conf
source custom.conf 2> /dev/null

# Variables
# Packages
base_packages="ca-certificates binutils wget curl git gnupg cron"
compiler_packages="sudo binutils cmake build-essential"
zone_packages="locales tzdata"
packages="$base_packages $compiler_packages $zone_packages $custom_packages"
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
roseColor="\e[38;5;200m\e[1m"
dot="${redColor}[${endColor}${yellowColor}*${endColor}${redColor}]${endColor}"

function banner(){
clear
echo -e "${roseColor} __   ___  __                 ${redColor} __   __       ${yellowColor} __               __   ___  __  ${endColor}"
echo -e "${roseColor}|  \ |__  |__) |  /\  |\ |    ${redColor}|__) |__) |    ${yellowColor}|__) |  | | |    |  \ |__  |__) ${endColor}"
echo -e "${roseColor}|__/ |___ |__) | /~~\ | \|    ${redColor}|  \ |    |    ${yellowColor}|__) \__/ | |___ |__/ |___ |  \ ${endColor}"
}

function init_script(){
banner

# Create base directories
rm -rf $work_dir
mkdir $work_dir

# First stage
echo -e "\n$dot$greenColor Starting first stage...$endColor"
debootstrap --foreign --arch="$architecture" $debian_release $rootfs
echo "$(date +"DAY: %d MONTH: %b HOUR: %I MINUTE: %M SECOND: %S")" > $work_dir/build-date.txt

# Second stage
echo -e "\n$dot$greenColor Starting second stage...$endColor"
if [ "$architecture" == "arm64" ]
then
    cp /usr/bin/qemu-aarch64-static $rootfs/usr/bin
else
    cp /usr/bin/qemu-arm-static $rootfs/usr/bin
fi
chroot $rootfs /debootstrap/debootstrap --second-stage
chroot $rootfs apt update

# Install packages
echo -e "\n$dot$green Installing packages...$endColor"
chroot $rootfs apt install -y $packages

# Set mounting system files
echo -e "\n${yellowColor}Setting mounting systm files...$endColor"
cat >$rootfs/etc/fstab <<EOM
# <file system>   <dir>           <type>  <options>         <dump>  <pass>
proc              /proc           proc    defaults          0       0
/dev/mmcblk0p1    /boot           vfat    defaults          0       2
/dev/mmcblk0p2    /               $fstype    defaults,noatime  0       1
EOM

# Configure networking
echo -e "\n${yellowColor}Configuring networking...$endColor"
chroot $rootfs apt install -y resolvconf
chroot $rootfs systemctl enable resolvconf
rm -rf $rootfs/etc/resolv.conf
echo "nameserver $name_server" > $rootfs/etc/resolv.conf

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
echo "$host_name" > $rootfs/etc/hostname

# Set users
echo -e "${yellowColor}Setting users$endColor"
chroot $rootfs <<_EOF
echo "root:${root_password}" | chpasswd
_EOF

# Set timezone
echo -e "${yellowColor}Setting timezone$endColor"
chroot $rootfs <<_EOF
ln -nfs /usr/share/zoneinfo/$timezone /etc/localtime
dpkg-reconfigure -fnoninteractive tzdata
_EOF

# Set locales
echo -e "${yellowColor}Setting locales$endColor"
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
chroot $rootfs apt install -y curl binutils
wget https://raw.githubusercontent.com/raspberrypi/rpi-update/master/rpi-update -O $rootfs/usr/local/sbin/rpi-update
chmod +x $rootfs/usr/local/sbin/rpi-update
chroot $rootfs <<_EOF
SKIP_WARNING=1 SKIP_BACKUP=1 /usr/local/sbin/rpi-update
_EOF

# Install raspberry userland firmware
git clone https://github.com/raspberrypi/userland.git $rootfs/tmp/userland
chroot $rootfs <<_EOF
cd /tmp/userland
if [ "$architecture" == "arm64" ]
then
    ./buildme --aarch64
else
    ./buildme
fi
_EOF

# Clean system
rm -rf /tmp/*

# Create image
echo -e "\n$dot$greenColor Creating image...$endColor"

# Create out image directory
rm -rf $out_dir
mkdir $out_dir

# Delete work directory
if [ "$delete_work_dir" == "yes" ]
then
    echo -e "${yellowColor}Deleting working directory$endColor"
    rm -rf $work_dir
fi
}

#---------- Installer ----------
if [ `whoami` == "root" ]; then
    banner;
    init_script;
else
    echo -e "${yellowColor}R U Drunk? This script needs to be run as ${endColor}${redColor}root${endColor}${yellowColor}!${endColor}";
fi
