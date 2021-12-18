#!/bin/bash -e

parrot_version=5.0
#--------------------------------------
# Parrot OS ARM Builder
# Device: Raspberry Pi 4/400
# LICENSE: MIT
# By: @kyb3rcipher and @serverket
#--------------------------------------

# Variables
source base.conf
if [ -f custom.conf ]; then
	source custom.sh
fi

# Colors
resetColor="\e[0m\e[0m"
redColor="\e[0;31m\e[1m"
blueColor="\e[0;34m\e[1m"
cyanColor="\e[01;96m\e[1m"
grayColor="\e[0;37m\e[1m"
greenColor="\e[0;32m\e[1m"
purpleColor="\e[0;35m\e[1m"
yellowColor="\e[0;33m\e[1m"
turquoiseColor="\e[0;36m\e[1m"
roseColor="\e[38;5;200m\e[1m"

# Script
if [ `whoami` == "root" ]; then

banner(){
clear
echo -e "
 ┌────────────────────────────────────────────────────────────────────┐
 │                    • ${greenColor}Parrot OS ARM ${yellowColor}Builder ${redColor}$parrot_version${resetColor} •                   │
 │                          ${roseColor}(For: raspberry)${resetColor}                          │
 │                                                                    │
 │ ➤ ${blueColor}The actual config is:${resetColor}                                            │
 │   ${yellowColor}• Edition      : security${resetColor}                                        │
 │   ${yellowColor}• Architecture : $architecture${resetColor}                                           │
 │   ${yellowColor}• Hostname     : $hostname${resetColor}                                          │
 │   ${yellowColor}• Password     : $password${resetColor}                                          │
 │   ${yellowColor}• Timezone     : $timezone${resetColor}                                             │
 │   ${yellowColor}• Locale       : $locale${resetColor}                                     │
 │                                                                    │
 │ ➤ ${purpleColor}For more info: https://parrotsec.org/docs/arm.html${resetColor}               │
 └────────────────────────────────────────────────────────────────────┘
"
}

# Banner
banner
function text(){
	local set_color="$2"
	case $set_color in
	red) color=$(tput setaf 1) ;;
	green) color=$(tput setaf 2) ;;
	yellow) color=$(tput setaf 3) ;;
	*) text="$1" ;;
	esac
	[ -z "$text" ] && echo -e "${redColor}[${endColor}${yellowColor}*${endColor}${redColor}]${endColor}$color $1 $(tput sgr0)" || echo -e "$text"

}
# Create rootfs (with debootstrap first and second stage)
text "Starting second stage..." yellow
debootstrap --foreign --arch="$architecture" bullseye $rootfs
# Copy qemu bin for enter to the system
if [ "$architecture" == "arm64" ]
then
	cp /usr/bin/qemu-aarch64-static $rootfs/usr/bin
else
	cp /usr/bin/qemu-arm-static $rootfs/usr/bin
fi
chroot $rootfs /debootstrap/debootstrap --second-stage

# Preparation
# Configure apt
rm $rootfs/etc/apt/sources.list
cat >$rootfs/etc/apt/sources.list <<EOM
# This file is empty, feel free to
# add here your custom APT repositories

# The standard Parrot repositories
# are NOT here. If you want to
# edit them, take a look into
# /etc/apt/sources.list.d/parrot.list
EOM
echo "deb http://deb/debian.org/debian bullseye main" > $rootfs/etc/apt/sources.list.d/debian.list
echo "#deb https://deb.parrot.sh/parrot lts main contrib non-free" > $rootfs/etc/apt/sources.list.d/parrot.list
chroot $rootfs wget -qO - https://deb.parrotsec.org/parrot/misc/parrotsec.gpg | apt-key add -
chroot $rootfs apt update


else
	echo -e "${yellowColor}R U Drunk? This script needs to be run as ${redColor}root${yellowColor}!${resetColor}"
	exit 1
fi
