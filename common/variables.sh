#!/bin/bash

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

	echo -e "${redColor}[${yellowColor}*${redColor}] ${text_color}${1}${endColor}"
}

# Functions
# CTRL + C
trap ctrl_c INT

function ctrl_c() {
	echo -e "\n\n${dot}${yellowColor} Exiting...${endColor}"
	exit
}
