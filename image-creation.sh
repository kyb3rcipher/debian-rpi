#!/bin/bash

BOOT_MB=${BOOT_MB:-"136"}
FREE_SPACE=${FREE_SPACE:-"256"}

source example.conf
if [ -f custom.conf ];
then
    source custom.conf;
fi

# Calcule el espacio para crear la imagen.
ROOTSIZE=$(du -s -B1 "$rootfs" --exclude="${rootfs}"/boot | cut -f1)
ROOTSIZE=$((ROOTSIZE * 5 * 1024 / 5 / 1000 / 1024))
RAW_SIZE=$(($((FREE_SPACE * 1024)) + ROOTSIZE + $((BOOT_MB * 1024)) + 4096))

fallocate -l "$(echo ${RAW_SIZE}Ki | numfmt --from=iec-i --to=si)" "${image_name}"
parted -s "${image_name}" mklabel msdos
parted -s "${image_name}" mkpart primary fat32 1MiB $((BOOT_MB + 1))MiB
parted -s -a minimal "${image_name}" mkpart primary $((BOOT_MB + 1))MiB 100%

# Establecer las variables de partición
LOOPDEVICE=$(losetup --show -fP "${image_name}")
BOOT_LOOP="${LOOPDEVICE}p1"
ROOT_LOOP="${LOOPDEVICE}p2"

mkfs.vfat -n BOOT -F 32 -v "$BOOT_LOOP"

features="-O ^64bit,^metadata_csum -E stride=2,stripe-width=1024 -b 4096"
# shellcheck disable=SC2086
mkfs $feautures -t "ext4" -L ROOTFS "$ROOT_LOOP"

# Crear los directorios para las particiones y montarlas
mkdir -p "$mount_dir"
mount "$ROOT_LOOP" "$mount_dir"
mkdir -p "$mount_dir/boot"
mount "$BOOT_LOOP" "$mount_dir/boot"

rsync -aHAXx --exclude boot "${rootfs}/" "${mount_dir}/"
rsync -rtx "${rootfs}/boot" "${mount_dir}/" && sync

# Desmontar sistema de archivos y eliminar compilación

umount -l "$mount_dir/boot"
umount -l "$mount_dir"

dosfsck -w -r -l -a -t "$BOOT_LOOP"
e2fsck -y -f "$ROOT_LOOP"

# Eliminar dispositivos loop
blockdev --flushbufs "${LOOPDEVICE}"
losetup -d "${LOOPDEVICE}"
