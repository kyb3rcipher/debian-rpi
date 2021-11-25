# Debian raspberry pi builder
For customize contruction create copy of **example.conf** to custom.conf and edit the file.

Use:
```bash
./builder.sh
```
Install dependeces with:
```bash
./requeriments.sh
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

Note: Execute all with root permisos (you can use sudo).

By: [Kyb3r](https://kyb3rvizsla.com)
