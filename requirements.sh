#!/bin/bash

# Colors
endColor="\e[0m\e[0m"
redColor="\e[0;31m\e[1m"
yellowColor="\e[0;33m\e[1m"
roseColor="\e[38;5;200m\e[1m"

if [ `whoami` == "root" ]; then

	# Check debian
	if [ -f /etc/debian_version ]; then
		apt update

		builder_packages="debootstrap qemu-user-static wget debian-archive-keyring"
		image_creation_packages="rsync dosfstools parted udev fdisk"
		packages="$builder_packages $image_creation_packages"
		apt install -y $packages && touch .parrot-arm-builder-dependeces
	else
		echo -e "${yellowColor}R U Drunk? This script needs to be run on a ${roseColor}debian${endColor}${yellowColor} or derived system${yellowColor}!${endColor}"
		exit 1
	fi
else
	echo -e "${yellowColor}R U Drunk? This script needs to be run as ${endColor}${redColor}root${endColor}${yellowColor}!${endColor}";
fi
