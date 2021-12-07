#!/bin/bash

#-----------------------------------
# Raspberry pi 3/4/400 builder (32)
# LICENSE: MIT
# By: Kyb3r Kryze <kyb3rkryze.com>
#-----------------------------------

# Source Files
source common/base.conf
if [ -f custom.conf ];
then
	source custom.conf;
fi
source common/variables.sh
source common/functions.sh

# --- Builder ---

# Common script
. common/common.sh

# Install packages
install_packages

# Set system
set_system

# Install rpi firmware
source common/rpi_firmware.sh

# Install desktop
install_desktop

# Clean system
clean_system

# Create image
create_image
