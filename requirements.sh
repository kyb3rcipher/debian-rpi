#!/bin/bash

apt update

build_packages="debootstrap qemu-user-static wget debian-archive-keyring"
packages="$build_packages

apt install $packages -y
