#!/bin/bash

# Install userland
echo -e "\n$dot$greenColor Installing raspberry pi userland firmware...$endColor"
git clone https://github.com/raspberrypi/userland.git $rootfs/tmp/userland
if [ "$architecture" == "arm64" ]
then
chroot $rootfs <<_EOF
cd /tmp/userland
./buildme --aarch64
_EOF
else
chroot $rootfs <<_EOF
cd /tmp/userland
./buildme
_EOF
fi
finished

# Install raspberry pi repository
echo "deb http://archive.raspberrypi.org/debian bullseye main" >> $rootfs/etc/apt/sources.list.d/raspberry.list
chroot $rootfs apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7FA3303E
chroot $rootfs apt update
finished

# Install kernel
echo -e "\n$dot$greenColor Installing kernel...$endColor"
# Install kernel
chroot $rootfs apt install -y raspberrypi-kernel raspberrypi-bootloader
# Add boot config
echo "net.ifnames=0 dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootwait" >> $rootfs/boot/cmdline.txt
if [ "$architecure" = "arm64" ]; then
	echo "arm_64bit=1" >> $rootfs/boot/config.txt
fi
echo "hdmi_force_hotplug=1" >> $rootfs/boot/config.txt
finished

# Remove raspberry pi repo
rm $rootfs/etc/apt/sources.list.d/rapsberry.list
chroot $rootfs apt update
