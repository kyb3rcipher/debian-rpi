#!/bin/bash

#--------------------------------------
# Parrot OS ARM - Raspberry pi builder
# LICENSE: MIT
# By: Kyb3r Kryze <kyb3rkryze.com>
#--------------------------------------

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

function text(){
	local set_text_color="$2"
	case $set_text_color in
		green) text_color=$greenColor ;;
		yellow) text_color=$yellowColor ;;
		cyan) text_color=$cyanColor ;;
		purple) text_color=$purpleColor ;;
		*) text_color="$endColor" ;;
	esac

	echo -e "${redColor}[${yellowColor}*${redColor}] ${text_color}${1}${endColor}"
}

# Exit
trap ctrl_c INT

function ctrl_c() {
	echo -e "\n\n${dot}${yellowColor} Exiting...${endColor}"
	exit
}

# Source config files
source base.conf
if [ -f custom.conf ];
then
	source custom.conf;
fi

#--------- Builder ---------

# Check requirements for builder
tmp_variable="jedi ghost"

# Check root user
if [ `whoami` == "root" ]; then
	tmp_variable="root"
else
	echo -e "${yellowColor}R U Drunk? This script needs to be run as ${endColor}${redColor}root${endColor}${yellowColor}!${endColor}"
	exit 1
fi

# Check debian
if [ -f /etc/debian_version ]; then
	tmp_variable="debian"
else
	echo -e "${yellowColor}R U Drunk? This script needs to be run on a ${roseColor}debian${endColor}${yellowColor} or derived system${yellowColor}!${endColor}"
	exit 1
fi

# Check dependeces
if [ -f .parrot-arm-builder-dependeces ]; then
	tmp_variable="yes"
else
	echo -e "${yellowColor}The dependencies needed for the constructor are missing I can install them by running: ${greenColor}./requirements.sh${endColor}"
	exit 1
fi


unset tmp_variable

# Banner
clear
echo -e "${greenColor} __        __   __   __  ___     ${redColor}     __           ${yellowColor} __               __   ___  __  ${endColor}"
echo -e "${greenColor}|__)  /\  |__) |__) /  \  |      ${redColor}/\  |__)  |\/|    ${yellowColor}|__) |  | | |    |  \ |__  |__) ${endColor}"
echo -e "${greenColor}|    /~~\ |  \ |  \ \__/  |     ${redColor}/~~\ |  \  |  |    ${yellowColor}|__) \__/ | |___ |__/ |___ |  \ ${endColor}"

echo -e "\nThe configuration is:"
echo -e " ${purpleColor}Hostname: ${cyanColor}$host_name"
echo -e " ${purpleColor}Architecture: ${cyanColor}$architecture"
echo -e " ${purpleColor}Out directory: ${cyanColor}$out_dir"
echo -e " ${purpleColor}Work directory: ${cyanColor}$work_dir"
sleep 4

# Create work directory
if [ -d $work_dir ];
then
	rm -rf $work_dir
fi
if [ -d $out_dir ];
then
	rm -rf $out_dir
fi
mkdir $work_dir

# Create rootfs
# Create rootfs system with debootstrap (first and second stage)
# First stage
echo -e "\n$dot$greenColor Creating rootfs system...$endColor"
debootstrap --foreign --arch="$architecture" bullseye $rootfs
echo "$(date +"DAY: %d MONTH: %b HOUR: %I MINUTE: %M SECOND: %S")" > $work_dir/build-date.txt
# Second stage
# Install QEMU binary (for chroot)
if [ "$architecture" == "arm64" ]
then
	cp /usr/bin/qemu-aarch64-static $rootfs/usr/bin
else
	cp /usr/bin/qemu-arm-static $rootfs/usr/bin
fi
chroot $rootfs /debootstrap/debootstrap --second-stage
finished

echo -e "\n${yellowColor}Updating repositories...$endColor"
chroot $rootfs apt update
finished

echo -e "\n$dot$green Installing base packages...$endColor"
chroot $rootfs apt install -y $base_packages
finished

# Install packages
chroot $rootfs apt install $packages -y

# Set system
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

# Set mounting system files
echo -e "\n${yellowColor}Setting mounting system files...$endColor"
cat >$rootfs/etc/fstab <<EOM
# <file system>   <dir>           <type>  <options>         <dump>  <pass>
proc              /proc           proc    defaults          0       0
/dev/mmcblk0p1    /boot           vfat    defaults          0       2
/dev/mmcblk0p2    /               $fstype    defaults,noatime  0       1
EOM
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

# Install rpi firmware
# Install userland
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

# Install raspberry pi repository
echo "deb http://archive.raspberrypi.org/debian bullseye main" >> $rootfs/etc/apt/sources.list.d/raspberry.list
chroot $rootfs apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7FA3303E
chroot $rootfs apt update
finished

# Install kernel
echo -e "\n$dot$greenColor Installing kernel...$endColor"
# Install kernel
chroot $rootfs apt install -y raspberrypi-kernel raspberrypi-bootloader
# Add boot config
echo "net.ifnames=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootwait" >> $rootfs/boot/cmdline.txt
if [ "$architecure" = "arm64" ]; then
	echo "arm_64bit=1" >> $rootfs/boot/config.txt
fi
echo "hdmi_force_hotplug=1" >> $rootfs/boot/config.txt
finished

# Remove raspberry pi repo
rm $rootfs/etc/apt/sources.list.d/rapsberry.list
chroot $rootfs apt update


# Install desktop
if [ "$install_desktop" == "yes" ] 
then
	text "Installing desktop..." green
	chroot $rootfs apt install -y task-xfce-desktop
	# For mate
	#chroot $rootfs apt install -y task-mate-desktop
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
function create_image(){
BOOT_MB=${BOOT_MB:-"136"}
FREE_SPACE=${FREE_SPACE:-"256"}

# Calcule el espacio para crear la imagen.
ROOTSIZE=$(du -s -B1 "$rootfs" --exclude="${rootfs}"/boot | cut -f1)
ROOTSIZE=$((ROOTSIZE * 5 * 1024 / 5 / 1000 / 1024))
RAW_SIZE=$(($((FREE_SPACE * 1024)) + ROOTSIZE + $((BOOT_MB * 1024)) + 4096))

fallocate -l "$(echo ${RAW_SIZE}Ki | numfmt --from=iec-i --to=si)" "${image_name}"
parted -s "${image_name}" mklabel msdos
parted -s "${image_name}" mkpart primary fat32 1MiB $((BOOT_MB + 1))MiB
parted -s -a minimal "${image_name}" mkpart primary $((BOOT_MB + 1))MiB 100%

# Establecer las variables de partición
LOOPDEVICE=$(losetup --show -fP "${image_name}")
BOOT_LOOP="${LOOPDEVICE}p1"
ROOT_LOOP="${LOOPDEVICE}p2"

mkfs.vfat -n BOOT -F 32 -v "$BOOT_LOOP"

features="-O ^64bit,^metadata_csum -E stride=2,stripe-width=1024 -b 4096"
# shellcheck disable=SC2086
mkfs $feautures -t "ext4" -L ROOTFS "$ROOT_LOOP"

# Crear los directorios para las particiones y montarlas
mkdir -p "$mount_dir"
mount "$ROOT_LOOP" "$mount_dir"
mkdir -p "$mount_dir/boot"
mount "$BOOT_LOOP" "$mount_dir/boot"

rsync -aHAXx --exclude boot "${rootfs}/" "${mount_dir}/"
rsync -rtx "${rootfs}/boot" "${mount_dir}/" && sync

# Desmontar sistema de archivos y eliminar compilación

umount -l "$mount_dir/boot"
umount -l "$mount_dir"

dosfsck -w -r -l -a -t "$BOOT_LOOP"
e2fsck -y -f "$ROOT_LOOP"

# Eliminar dispositivos loop
blockdev --flushbufs "${LOOPDEVICE}"
losetup -d "${LOOPDEVICE}"
}
#create_image
