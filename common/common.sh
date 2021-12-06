#!/bin/bash
# First common script

# Check system requiremenrs
check_requirements

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
