#!/bin/sh

set -eu

cd "$1"

if [ $(cat rootfs.jffs2 | wc -c) -gt $((0x7a0000 - 0x140000 - 512)) ]; then
	echo rootfs.jffs2 is too large >&2
	exit 1
fi

xz --format=lzma --stdout --lzma1=lc=1,lp=2,pb=2 vmlinux.bin > vmlinux.bin.lzma

if [ $(cat vmlinux.bin.lzma | wc -c) -gt $((0x140000 - 512)) ]; then
	echo vmlinux.bin.lzma is too large >&2
	exit 1
fi

ENTRY=$(../host/usr/mips-buildroot-linux-uclibc/bin/nm ../build/linux-$(sed -n 's/BR2_LINUX_KERNEL_VERSION="\(.*\)"/\1/ p' ../../.config)/vmlinux | awk '{ if ($3 == "kernel_entry") print $1 }')

../host/usr/bin/mktplinkfw2 -c -B TD-W8970v1 -s -k vmlinux.bin.lzma -E 0x$ENTRY -o bratwurst.uImage

exit 0
