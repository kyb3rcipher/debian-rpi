#!/bin/bash
if [ `whoami` == "root" ]; then
    
    apt update

    builder_packages="debootstrap qemu-user-static wget debian-archive-keyring"
    image_creation_packages="rsync dosfstools parted udev fdisk"
    packages="$builder_packages $image_creation_packages"
    apt install -y $packages
else
    echo -e "${yellowColor}R U Drunk? This script needs to be run as ${endColor}${redColor}root${endColor}${yellowColor}!${endColor}";
fi
