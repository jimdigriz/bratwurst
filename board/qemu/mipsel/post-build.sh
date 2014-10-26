#!/bin/sh

set -eu

if [ $# -ne 1 ] || [ -z "$1" ]; then
	echo "no" >&2
	exit 1
fi

# musl bugs
ln -f -s /lib/libc.so "$1/lib/ld-musl-mipsel.so.1"
cp output/host/usr/mipsel-buildroot-linux-musl/sysroot/lib/libgcc_s.so.1 "$1/lib"
./output/host/usr/mipsel-buildroot-linux-musl/bin/strip "$1/lib/libgcc_s.so.1"
ln -f -s libgcc_s.so.1 "$1/lib/libgcc_s.so"

rm "$1/root/.bash_history"
rm "$1/root/.bash_logout"
rm "$1/root/.bash_profile"

find "$1/var" -depth -mindepth 1 | xargs -r rm -r

rm -rf "$1/etc/nftables"

exit 0
