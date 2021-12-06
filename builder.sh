#!/bin/bash

#--------------------------------------
# Debian raspberry pi builder
# LICENSE: MIT
# By: Kyb3r Kryze <kyb3rkryze.com>
#---------------------------------------

source example.conf
if [ -f custom.conf ];
then
    source custom.conf;
fi

# Variables
# Packages
base_packages="binutils wget curl git gnupg cron"
zone_packages="locales tzdata"
network_packages="ca-certificates resolvconf"
compiler_packages="sudo binutils cmake build-essential"
packages="$base_packages $zone_packages $network_packages $compiler_packages $custom_packages"
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
function finished() {
    echo -e "\n${greenColor}Finished${endColor} ✔️"
}

# Functions
# CTRL + C
trap ctrl_c INT

function ctrl_c() {
    echo -e "\n\n${dot}${yellowColor} Exiting...${endColor}"
    exit
}

function banner(){
clear
echo -e "${roseColor} __   ___  __                 ${redColor} __   __       ${yellowColor} __               __   ___  __  ${endColor}"
echo -e "${roseColor}|  \ |__  |__) |  /\  |\ |    ${redColor}|__) |__) |    ${yellowColor}|__) |  | | |    |  \ |__  |__) ${endColor}"
echo -e "${roseColor}|__/ |___ |__) | /~~\ | \|    ${redColor}|  \ |    |    ${yellowColor}|__) \__/ | |___ |__/ |___ |  \ ${endColor}"
}

function init_script(){
banner
echo -e "\nThe configuration is:"
echo -e " ${purpleColor}Hostname: ${cyanColor}$host_name"
echo -e " ${purpleColor}Architecture: ${cyanColor}$architecture"
echo -e " ${purpleColor}Out directory: ${cyanColor}$out_dir"
echo -e " ${purpleColor}Work directory: ${cyanColor}$work_dir"
sleep 4

# Create base directories
if [ -d $work_dir ];
then
    rm -rf $work_dir
fi
mkdir $work_dir

# First stage
echo -e "\n$dot$greenColor Starting first stage...$endColor"
debootstrap --foreign --arch="$architecture" $debian_release $rootfs
echo "$(date +"DAY: %d MONTH: %b HOUR: %I MINUTE: %M SECOND: %S")" > $work_dir/build-date.txt
finished

# Second stage
echo -e "\n$dot$greenColor Starting second stage...$endColor"
echo -e "\n${yellowColor}Installing QEMU binary...$endColor"
if [ "$architecture" == "arm64" ]
then
    cp /usr/bin/qemu-aarch64-static $rootfs/usr/bin
else
    cp /usr/bin/qemu-arm-static $rootfs/usr/bin
fi
finished
echo -e "\n${yellowColor}Executing second stage...$endColor"
chroot $rootfs /debootstrap/debootstrap --second-stage
finished
echo -e "\n${yellowColor}Updating repositories...$endColor"
chroot $rootfs apt update
finished

# Install packages
echo -e "\n$dot$green Installing packages...$endColor"
chroot $rootfs apt install -y $packages
finished

# Set mounting system files
echo -e "\n${yellowColor}Setting mounting system files...$endColor"
cat >$rootfs/etc/fstab <<EOM
# <file system>   <dir>           <type>  <options>         <dump>  <pass>
proc              /proc           proc    defaults          0       0
/dev/mmcblk0p1    /boot           vfat    defaults          0       2
/dev/mmcblk0p2    /               $fstype    defaults,noatime  0       1
EOM
finished

# Configure networking
echo -e "\n${yellowColor}Configuring networking...$endColor"
chroot $rootfs systemctl enable resolvconf
rm -rf $rootfs/etc/resolv.conf
echo "nameserver $name_server" > $rootfs/etc/resolv.conf
finished

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
echo "$host_name" > $rootfs/etc/hostname
finished

# Set users
echo -e "${yellowColor}Setting users$endColor"
chroot $rootfs <<_EOF
echo "root:${root_password}" | chpasswd
_EOF
finished

# Set timezone
echo -e "${yellowColor}Setting timezone$endColor"
chroot $rootfs <<_EOF
ln -nfs /usr/share/zoneinfo/$timezone /etc/localtime
dpkg-reconfigure -fnoninteractive tzdata
_EOF
finished

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
finished

# Install raspberry userland firmware
echo -e "\n$dot$greenColor Installing raspberry pi userland firmware...$endColor"
git clone https://github.com/raspberrypi/userland.git $rootfs/tmp/userland
if [ "$architecture" == "arm64" ]
then
chroot $rootfs <<_EOF
cd /tmp/userland
./buildme --aarch64
_EOF
else
chroot $rootfs <<_EOF
cd /tmp/userland
./buildme
_EOF
fi
finished

# Install raspberry pi repositorie
echo -e "\n$dot$greenColor Installing rasperry pi repo...$endColor"
echo "deb http://archive.raspberrypi.org/debian bullseye main" >> /etc/apt/sources.list.d/raspberry.list
chroot $rootfs apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7FA3303E
chroot $rootfs apt update
finished

# Install kernel
echo -e "\n$dot$greenColor Installing kernel...$endColor"
# Install kernel
chroot $rootfs apt install -y raspberrypi-kernel raspberrypi-bootloader
# Add boot config
echo "net.ifnames=0 console=tty1 root=/dev/mmcblk0p2 rw rootwait" >> $rootfs/boot/cmdline.txt
if [ "$architecure" = "arm64" ]; then
    echo "arm_64bit=1" >> $rootfs/boot/config.txt
fi
echo "hdmi_force_hotplug=1" >> $rootfs/boot/config.txt
finished

# Remove raspberry pi repo
echo -e "${yellowColor}Removing raspberry pi repo$endColor"
rm $rootfs/etc/apt/sources.list.d/rapsberry.list
apt update
finished

# Install desktop (xfce)
if [ "$install_desktop" = "yes" ]; then
    echo -e "\n$dot$greenColor Installing desktop...$endColor"
    chroot $roootfs apt install -y task-xfce-desktop
    finished
fi

# Clean system
echo -e "${yellowColor}Cleaning system$endColor"
# packages
chroot $rootfs apt-get -y remove --purge $compiler_packages
chroot $rootfs apt-get autoremove --purge -y
chroot $rootfs apt-get autoclean
chroot $rootfs apt-get clean
# build
rm -rf $rootfs/tmp/*
rm -rf $rootfs/usr/bin/qemu*
rm -rf $rootfs/root/.bash_history
rm -rf $rootfs/usr/local/sbin/rpi-update
# man pages
rm -rf $rootfs/usr/share/man/*
rm -rf $rootfs/usr/share/info/*
# apt
rm -rf $rootfs/var/lib/dpkg/*-old
rm -rf $rootfs/var/lib/apt/lists/*
rm -rf $rootfs/var/cache/apt/*.bin
rm -rf $rootfs/var/cache/debconf/*-old
rm -rf $rootfs/var/cache/apt/archives/*
# id
rm -rf $rootfs/etc/machine-id
rm -rf $rootfs/var/lib/dbus/machine-id
finished

# Create image
echo -e "\n$dot$greenColor Creating image...$endColor"
echo -e "\nFor Build Image execute image-creation.sh"

# Create out image directory
#rm -rf $out_dir
#mkdir $out_dir

# Delete work directory
if [ "$delete_work_dir" == "yes" ]
then
    echo -e "${yellowColor}Deleting working directory$endColor"
    rm -rf $work_dir
    finished
fi

# End script
#if [ -d $out_dir ];
#then
#    rm -rf $out_dir
#fi
#mkdir $out_dir
#mv $image_name $out_dir
sleep 2

echo -e "\n${purpleColor}[${endColor}${yellowColor}*${endColor}${purpleColor}]${endColor} ${greenColor}The image was created successfully, you can find it in: ${cyanColor}${out_dir}/${image_name}${endColor}"
}

#---------- Installer ----------
if [ `whoami` == "root" ]; then
    banner;
    init_script;
else
    echo -e "${yellowColor}R U Drunk? This script needs to be run as ${endColor}${redColor}root${endColor}${yellowColor}!${endColor}";
fi
