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
eatmydata debootstrap --foreign --arch="arm64" --include="ifupdown openresolv net-tools init dbus rsyslog cron eatmydata wget gnupg" $DEBIAN_RELEASE $ROOTFS

# Second stage
chroot $ROOTFS /debootstrap/debootstrap --second-stage

