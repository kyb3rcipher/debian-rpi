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
base_packages="ca-certificates binutils wget curl wget gnupg cron rsyslog"
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
chroot $rootfs apt install -y curl binutils
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

# Create image
echo -e "\n$dot$greenColor Creating image...$endColor"

# Create out image directory
rm -rf $out_dir
mkdir $out_dir

# Calculate the space to create the image.
echo -e "${yellowColor}Calculation the space to create the image$endColor"

ROOT_SIZE=$(du -s -B1 "${rootfs}" --exclude="${rootfs}"/boot | cut -f1)
ROOT_EXTRA=$((ROOT_SIZE * 5 * 1024 / 5 / 1024 / 1000))
RAW_SIZE=$(($((FREE_SPACE * 1024)) + ROOT_EXTRA + $((BOOTSIZE * 1024)) + 4096))
IMG_SIZE=$(echo "${RAW_SIZE}"Ki | numfmt --from=iec-i --to=si)

# Create image
fallocate -l "${IMG_SIZE}" "${out_dir}/${image_name}.img"

# Create the disk partitions
echo -e "${yellowColor}Creation disk partitions$endColor"

parted -s "${out_dir}/${image_name}.img" mklabel msdos
parted -s "${out_dir}/${image_name}.img" mkpart primary fat32 1MiB "${BOOTSIZE}"MiB
parted -s -a minimal "${out_dir}/${out_dir}.img" mkpart primary "ext4" "${BOOTSIZE}"MiB 100%

# Set the partition variables
echo -e "${yellowColor}Setting partitions variables$endColor"

LOOP_DEVICE=$(losetup --show -fP "${out_dir}/${image_name}.img")
BOOTP="${LOOP_DEVICE}p1"
ROOTP="${LOOP_DEVICE}p2"

# Format partitions
echo -e "${yellowColor}Formatting partions$endColor"

mkfs.vfat -n BOOT -F 32 "${BOOTP}"
features="^64bit,^metadata_csum"
mkfs -O "$features" -t "ext4" -L ROOTFS "${ROOTP}"

# Create the dirs for the partitions and mount them
echo -e "${yellowColor}Create mount directories and mount them$endColor"

image_dir="$work_dir/mount"
mkdir -p "${image_dir}"/work_dir
mount "${ROOTP}" "${image_dir}"
mkdir -p "${image_dir}"/boot
mount "${BOOTP}" "${image_dir}"/boot

# Rsyn rootfs into image file
echo -e "${yellowColor}Rsyn system to image$endColor"

rsync -HPavz -q --exclude boot "${rootfs}/" "${image_dir}/"
sync
rsync -rtx -q "${rootfs}"/boot "${image_dir}/"
sync

# Unmount filesystem
echo -e "${yellowColor}Unmount filesystem$endColor"

umount -l "${BOOTP}"
umount -l "${ROOTP}"

# Check filesystem
dosfsck -w -r -a -t "$BOOTP"
e2fsck -y -f "${ROOTP}"

# Remove loop devices
echo -e "${yellowColor}Removing loop devices$endColor"

losetup -d "${LOOP_DEVICE}"

# Delete work directory
if [ "$delete_work_dir" == "yes" ]
then
    echo -e "${yellowColor}Deleting working directory$endColor"
    rm -rf $work_dir
fi
