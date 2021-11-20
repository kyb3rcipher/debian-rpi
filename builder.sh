#!/bin/bash

#---------------------------------
# Debian arm raspberry pi builder
# LICENSE: MIT
# By: Kyb3r Vizsla <kyb3rvizsla.com>
#---------------------------------

source example.conf
source custom.conf 2> /dev/null

# Preparation
mkdir $work_dir

# First stage
debootstrap --foreign --arch="$architecture" --include="ifupdown openresolv net-tools init dbus rsyslog cron eatmydata wget gnupg" $debian_release $rootfs

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
