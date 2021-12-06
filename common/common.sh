#!/bin/bash
# First common script

# Source files
source common/variables.conf
source common/base.conf
if [ -f custom.conf ];
then
	source custom.conf;
fi

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
if [ -f /tmp/parrot-arm-builder-dependeces ]; then
	tmp_variable="yes"
else
	echo -e "${yellowColor}The dependencies needed for the constructor are missing I can install them by running: ${greenColor}./common/requirementes.sh${endColor}"
	exit 1
fi

unset tmp_variable

# Banner
clear
echo -e "${roseColor} __   ___  __                 ${redColor} __   __       ${yellowColor} __               __   ___  __  ${endColor}"
echo -e "${roseColor}|  \ |__  |__) |  /\  |\ |    ${redColor}|__) |__) |    ${yellowColor}|__) |  | | |    |  \ |__  |__) ${endColor}"
echo -e "${roseColor}|__/ |___ |__) | /~~\ | \|    ${redColor}|  \ |    |    ${yellowColor}|__) \__/ | |___ |__/ |___ |  \ ${endColor}"

# Banner config
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
finished
# Second stage
# Installi QEMU binary (for chroot)
if [ "$architecture" == "arm64" ]
then
	cp /usr/bin/qemu-aarch64-static $rootfs/usr/bin
else
	cp /usr/bin/qemu-arm-static $rootfs/usr/bin
fi
finished
chroot $rootfs /debootstrap/debootstrap --second-stage
finished


echo -e "\n${yellowColor}Updating repositories...$endColor"
chroot $rootfs apt update
finished

echo -e "\n$dot$green Installing base packages...$endColor"
chroot $rootfs apt install -y $base_packages
finished

else
	echo -e "${yellowColor}R U Drunk? This script needs to be run as ${endColor}${redColor}root${endColor}${yellowColor}!${endColor}";
	exit 255
fi