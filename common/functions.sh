#!/bin/bash

function check_requirements(){
source common/variables.sh

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
	echo -e "${yellowColor}The dependencies needed for the constructor are missing I can install them by running: ${greenColor}./common/requirements.sh${endColor}"
	exit 1
fi

unset tmp_variable
}

function set_system(){
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
}

# Install desktop (default xfce)
if [ "$install_desktop" == "yes" ] then;
	text "Installing desktop..." green
	chroot $rootfs apt install -y task-xfce-desktop
fi

# Clean system
function clean_system(){
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
}

function create_image(){
BOOT_MB=${BOOT_MB:-"136"}
FREE_SPACE=${FREE_SPACE:-"256"}

source common/base.conf
if [ -f custom.conf ];
then
	source custom.conf;
fi

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
