#!/bin/sh

set -eu

cd "$1"

xz --format=lzma -c vmlinux.bin > .vmlinux.bin.lzma
mv .vmlinux.bin.lzma vmlinux.bin.lzma

#if [ $(cat vmlinux.bin.lzma | wc -c) -gt $((768*1024)) ]; then
#	echo vmlinux.bin.lzma is too large >&2
#	exit 1
#fi

#if [ $(cat rootfs.jffs2 | wc -c) -gt $((3136*1024)) ]; then
#	echo rootfs.jffs2 is too large >&2
#	exit 1
#fi

../host/usr/bin/mktplinkfw2 -B TD-W8970v1 -s -a 0x4 -j -k vmlinux.bin.lzma -r rootfs.jffs2 -o bratwurst.image

exit 0
