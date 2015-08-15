#!/bin/sh

set -eu

cd "$1"

if [ $(cat rootfs.jffs2 | wc -c) -gt $((3008*1024)) ]; then
	echo rootfs.jffs2 is too large >&2
	exit 1
fi

if [ $(cat vmlinuz | wc -c) -gt $((896*1024)) ]; then
	echo vmlinuz is too large >&2
	exit 1
fi

DD_PARAMS="status=noxfer of=.pflash count=1"

dd $DD_PARAMS conv=sync                      bs=128k  if=/dev/zero	2>/dev/null
dd $DD_PARAMS conv=sync,notrunc oflag=append bs=896k  if=vmlinuz	2>/dev/null
dd $DD_PARAMS conv=sync,notrunc oflag=append bs=3008k if=rootfs.jffs2	2>/dev/null
dd $DD_PARAMS conv=sync,notrunc oflag=append bs=64k   if=/dev/zero	2>/dev/null

mv .pflash pflash

exit 0
