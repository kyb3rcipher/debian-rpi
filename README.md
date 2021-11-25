# Debian raspberry pi builder

## Preparation
The script works on Debian and derivatives like Parrot or Ubuntu. Therefore you will need one of these.

## Installation
Install dependeces with:
```bash
./requeriments.sh
```

# Use
Execute builder with:
```bash
./builder.sh
```

## Personalizate
To customize your images you must create a copy of the example.conf file with name: **custom.conf**, and there modify the variables to your needs, then an explanation of each variable:

- root_password - root user password
- custom_packages - add custom packages to system
- timezone - your local timezone view more [here](https://wiki.debian.org/TimeZoneChanges)
- locale - your locales view more [here](https://wiki.debian.org/Locale)
- host_name - system hostname
- architecture - system architecture the options are: arm64 and armhf
- fstype - system file system ⚠️
- name_server - dns server, recomended: 8.8.8.8 (google) or 1.1.1.1 (cloudflare)
- debian_release - system release you can use ubuntu or others releases script
- image_name - final image name
- delete_work_dir - delete option from working directory (rootfs and mount)
- bootsize - /boot size in Mib ⚠️
- free_space - free space in root (/) ⚠️
- out_dir - image out directory
- work_dir - working directory
- rootfs - rootfs system directory
- mount_dir - mount directory for image creation

(those that are marked are the symbol ⚠️ are options that we recommend not to change)

## Test image
Although it is optional. To test your image you must verify that the partitions were created correctly, for this you must mount the image you can do it with ```gnome-disk-utility``` installing it with: ```apt install -y gnome-disk-utility```. Then you should open it:

Note: Execute all with root permisos (you can use sudo).

By: [Kyb3r](https://kyb3rvizsla.com)
