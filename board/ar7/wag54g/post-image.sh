#!/bin/sh

set -eu

cd "$1"

if [ $(cat rootfs.jffs2 | wc -c) -gt $((3136*1024)) ]; then
	echo rootfs.jffs2 is too large >&2
	exit 1
fi

../host/usr/bin/mipsel-buildroot-linux-uclibc-objcopy -S -O srec --srec-forceS3 vmlinuz vmlinuz.srec
../host/usr/bin/srec2bin vmlinuz.srec vmlinuz.bin

if [ $(cat vmlinuz.bin | wc -c) -gt $((768*1024)) ]; then
	echo vmlinuz is too large >&2
	exit 1
fi

DD_PARAMS="status=noxfer of=firmware-code.bin.headerless"

dd $DD_PARAMS conv=sync                      count=1 bs=16   if=/dev/zero	2>/dev/null
dd $DD_PARAMS conv=sync,notrunc oflag=append count=1 bs=768k if=vmlinuz.bin	2>/dev/null
dd $DD_PARAMS conv=sync,notrunc oflag=append                 if=rootfs.jffs2	2>/dev/null

cat firmware-code.bin.headerless | ../host/usr/bin/addpattern -o .firmware-code.bin -p WA21

mv .firmware-code.bin firmware-code.bin

exit 0
