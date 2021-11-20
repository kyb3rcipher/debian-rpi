#!/bin/bash

#---------------------------------
# Debian arm raspberry pi builder
# LICENSE: MIT
# By: Kyb3r Vizsla <kyb3rvizsla.com>
#---------------------------------

# Variables
ROOTFS="rootfs"
DEBIAN_RELEASE="bullseye"

# First stage
eatmydata debootstrap --foreign --arch="arm64" $DEBIAN_RELEASE $ROOTFS
