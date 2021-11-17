#!/bin/bash

#-----------------------------------
# Debian raspberry arm image builder
# By: Kyb3r <kyb3rvizsla.com>
# LICENSE: MIT
#------------------------------------

function first-stage(){
    eatmydata debootstrap --foreign --arch="$ARCHITECTURE" --keyring=/usr/share/keyrings/debian-archive-keyring.gpg --include="$FIRST_STAGE_PKG" buster $ROOTFS
}

function second-stage(){
    apt update
    apt install -y eatmydata
    chroot $ROOTFS eatmydata /debootstrap/debootstrap --second-stage

}

function set-users(){
    chroot $ROOTFS echo "root:${ROOT_PASSWORD}" | chpasswd
}

function create-image(){

}
