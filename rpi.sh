#!/bin/bash

#-----------------------------
# Raspberry pi 3/4/400 builder
#-----------------------------

source common/variables.sh

# Check root
if [ `whoami` == "root" ]; then

# Source files
source common/functions.sh

# Builder

# Init script
./common/common.sh

# Set system
set_system

# Install rpi firmware
./common/rpi_firmware.sh

# Clean system
clean_system

# Create image
create_image

else
	echo -e "${yellowColor}R U Drunk? This script needs to be run as ${endColor}${redColor}root${endColor}${yellowColor}!${endColor}";
	exit 255
fi