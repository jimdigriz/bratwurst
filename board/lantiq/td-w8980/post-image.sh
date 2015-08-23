#!/bin/sh

set -eu

cd "$1"

if [ $(cat rootfs.jffs2 | wc -c) -gt $((0x660000)) ]; then
	echo rootfs.jffs2 is too large >&2
	exit 1
fi

../host/usr/bin/mips-buildroot-linux-uclibc-objcopy -O binary vmlinux vmlinux.bin
xz --format=lzma --stdout --lzma1=lc=1,lp=2,pb=2 vmlinux.bin > vmlinux.bin.lzma

if [ $(cat vmlinux.bin.lzma | wc -c) -gt $((0x140000)) ]; then
	echo vmlinux.bin.lzma is too large >&2
	exit 1
fi

ENTRY=$(../host/usr/bin/mips-buildroot-linux-uclibc-nm ../build/linux-$(sed -n 's/BR2_LINUX_KERNEL_VERSION="\(.*\)"/\1/ p' ../../.config)/vmlinux | awk '{ if ($3 == "kernel_entry") print $1 }')

../host/usr/bin/mktplinkfw2 -H 0x89800001 -F 8Mltq -s -E 0x$ENTRY \
	-k vmlinux.bin.lzma -r rootfs.jffs2 -o bratwurst.image

exit 0
