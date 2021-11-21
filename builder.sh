#!/bin/bash

#--------------------------------------
# Debian arm raspberry pi builder
# LICENSE: MIT
# By: Kyb3r Vizsla <kyb3rvizsla.com>
#---------------------------------------

source example.conf
source custom.conf 2> /dev/null

# Variables
base_packages="ca-certificates wget curl gnupg cron init dbus rsyslog tzdata locales"
compile_packages="sudo cmake build-essential binutils"
debootstrap_include_packages="eatmydata gnup"
packages="$base_packages $compile_packages $custom_packages"

# Preparation
rm -rf $word_dir 2> /dev/null
mkdir $work_dir

# First stage
debootstrap --foreign --arch="$architecture" --include="$debootstrap_include_packages" $debian_release $rootfs

# Second stage
cp /usr/bin/qemu-aarch64-static $rootfs/usr/bin # copy qemu bin for chroot
chroot $rootfs /debootstrap/debootstrap --second-stage

# Set users
chroot $rootfs <<_EOF
echo "root:${root_password}" | chpasswd
_EOF

# Set mounting system files
cat >$rootfs/etc/fstab <<EOM
# <file system>   <dir>           <type>  <options>         <dump>  <pass>
proc              /proc           proc    defaults          0       0
/dev/mmcblk0p1    /boot           vfat    defaults          0       2
/dev/mmcblk0p2    /               $fstype    defaults,noatime  0       1
EOM

# Set hosts file
cat >$rootfs/etc/hosts <<EOM
127.0.1.1       ${host_name}
127.0.0.1       localhost
::1             localhostnet.ifnames=0 ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOM

# Install packages
chroot $rootfs <<_EOF
apt update
apt install -y $packages
_EOF

# Set timezone
chroot $rootf <<_EOF
ln -nfs /usr/share/zoneinfo/$timezone /etc/localtime
dpkg-reconfigure -fnoninteractive tzdata
_EOF

# Set locales
#sed -i "s/^# *\($locale\)/\1/" $rootfs/etc/locale.gen
#chroot $rootfs locale-gen
#echo "LANG=$locale" > $rootfs/etc/locale.conf
#cat <<'EOM' > $rootfs/etc/profile.d/default-lang.sh
#if [ -z "$LANG" ]; then
#source /etc/locale.conf
#export LANG
#fi
#EOM

# Install kernel
#wget https://raw.githubusercontent.com/raspberrypi/rpi-update/master/rpi-update -O $rootfs/usr/local/sbin/rpi-update
#chmod +x $rootfs/usr/local/sbin/rpi-update
#SKIP_WARNING=1 SKIP_BACKUP=1 ROOT_PATH=$rootfs BOOT_PATH=$rootfs/boot $rootfs/usr/local/sbin/rpi-update
#
# Install raspberry userland firmware
#git clone https://github.com/raspberrypi/userland.git $rootfs/tmp/userland
#chroot $rootfs <<_EOF
#cd /tmp/userland
#./buildme --aarch64
#_EOF
