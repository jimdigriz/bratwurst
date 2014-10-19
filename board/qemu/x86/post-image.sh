#!/bin/sh

set -eu

cd "$1"

#if [ $(cat vmlinuz | wc -c) -gt $((1024*1024)) ]; then
#	echo vmlinuz is too large >&2
#	exit 1
#fi

if [ $(cat rootfs.jffs2 | wc -c) -gt $((2880*1024)) ]; then
	echo rootfs.jffs2 is too large >&2
	exit 1
fi

DD_PARAMS="status=noxfer of=.pflash count=1"

dd $DD_PARAMS conv=sync                      bs=128k  if=/dev/zero		2>/dev/null
#dd $DD_PARAMS conv=sync,notrunc oflag=append bs=1024k if=vmlinuz		2>/dev/null
dd $DD_PARAMS conv=sync,notrunc oflag=append bs=1024k if=/dev/zero		2>/dev/null
dd $DD_PARAMS conv=sync,notrunc oflag=append bs=2880k if=rootfs.jffs2		2>/dev/null
dd $DD_PARAMS conv=sync,notrunc oflag=append bs=64k   if=/dev/zero		2>/dev/null

mv .pflash pflash

exit 0
