#!/bin/bash

#-----------------------------
# Raspberry pi 3/4/400 builder
#-----------------------------

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