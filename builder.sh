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
debootstrap_include_packages="eatmydata gnupg"
packages="$base_packages $custom_packages"

# Preparation
rm -rf $word_dir 2> /dev/null
mkdir $work_dir

# First stage
debootstrap --foreign --arch="$architecture" --include="$debootstrap_include_packages" $debian_release $rootfs

# Second stage
cp /usr/bin/qemu-aarch64-static $rootfs/usr/bin # copy qemu bin for chroot
chroot $rootfs /debootstrap/debootstrap --second-stage
chroot $rootfs apt update

# Install packages
chroot $rootfs <<_EOF
apt install -y $packages
_EOF

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

# Configure networking
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

# Set timezone
apt install -y tzdata
chroot $rootfs <<_EOF
ln -nfs /usr/share/zoneinfo/$timezone /etc/localtime
dpkg-reconfigure -fnoninteractive tzdata
_EOF

# Set locales
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
