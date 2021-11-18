#!/bin/bash

#-----------------------------------
# Debian raspberry arm image builder
# By: Kyb3r <kyb3rvizsla.com>
# LICENSE: MIT
#------------------------------------
source config.txt

# First Stage
eatmydata debootstrap --foreign --arch="$ARCHITECTURE" --keyring=/usr/share/keyrings/debian-archive-keyring.gpg include="eatmydata" buster $ROOTFS

# Second Stage
apt update
apt install -y eatmydata
chroot $ROOTFS eatmydata /debootstrap/debootstrap --second-stage

# Set users
chroot $ROOTFS echo "root:${ROOT_PASSWORD}" | chpasswd
