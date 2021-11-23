#!/bin/bash

R="work_dir/rootfs"
FSTYPE=${FSTYPE:-"ext4"}
BOOT_MB=${BOOT_MB:-"136"}
FREE_SPACE=${FREE_SPACE:-"256"}
BUILDDIR="work_dir"
IMGNAME="debian.img"

# Calcule el espacio para crear la imagen.
ROOTSIZE=$(du -s -B1 "$R" --exclude="${R}"/boot | cut -f1)
ROOTSIZE=$((ROOTSIZE * 5 * 1024 / 5 / 1000 / 1024))
RAW_SIZE=$(($((FREE_SPACE * 1024)) + ROOTSIZE + $((BOOT_MB * 1024)) + 4096))

fallocate -l "$(echo ${RAW_SIZE}Ki | numfmt --from=iec-i --to=si)" "${IMGNAME}"
parted -s "${IMGNAME}" mklabel msdos
parted -s "${IMGNAME}" mkpart primary fat32 1MiB $((BOOT_MB + 1))MiB
parted -s -a minimal "${IMGNAME}" mkpart primary $((BOOT_MB + 1))MiB 100%

# Establecer las variables de partición
LOOPDEVICE=$(losetup --show -fP "${IMGNAME}")
BOOT_LOOP="${LOOPDEVICE}p1"
ROOT_LOOP="${LOOPDEVICE}p2"

mkfs.vfat -n BOOT -F 32 -v "$BOOT_LOOP"

FEATURES="-O ^64bit,^metadata_csum -E stride=2,stripe-width=1024 -b 4096"
# shellcheck disable=SC2086
mkfs $FEATURES -t "$FSTYPE" -L ROOTFS "$ROOT_LOOP"

# Crear los directorios para las particiones y montarlas
MOUNTDIR="$BUILDDIR/mount"
mkdir -p "$MOUNTDIR"
mount "$ROOT_LOOP" "$MOUNTDIR"
mkdir -p "$MOUNTDIR/$BOOT"
mount "$BOOT_LOOP" "$MOUNTDIR/$BOOT"

rsync -aHAXx --exclude boot "${R}/" "${MOUNTDIR}/"
rsync -rtx "${R}/boot" "${MOUNTDIR}/" && sync

# Desmontar sistema de archivos y eliminar compilación

umount -l "$MOUNTDIR/$BOOT"
umount -l "$MOUNTDIR"

dosfsck -w -r -l -a -t "$BOOT_LOOP"
e2fsck -y -f "$ROOT_LOOP"

# Eliminar dispositivos loop
blockdev --flushbufs "${LOOPDEVICE}"
losetup -d "${LOOPDEVICE}"