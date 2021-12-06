#!/bin/bash

# Source files
source common/base.conf
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

function text(){
	local set_text_color="$2"
	case $set_text_color in
		green) text_color=$greenColor ;;
		yellow) text_color=$yellowColor ;;
		cyan) text_color=$cyanColor ;;
		purple) text_color=$purpleColor ;;
		*) text_color="$endColor" ;;
	esac

	echo -e "${redColor}[${yellowColor}*${redColor}] ${text_color}${1} ${endColor}"
}

# Functions
# CTRL + C
trap ctrl_c INT

function ctrl_c() {
	echo -e "\n\n${dot}${yellowColor} Exiting...${endColor}"
	exit
}

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