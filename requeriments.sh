#!/bin/bash

apt update

builder_packages="debootstrap qemu-user-static wget"
image_creation_packages="rsync dosfstools parted udev fdisk"
packages="$builder_packages $image_creation_packages"

apt install -y $packages
