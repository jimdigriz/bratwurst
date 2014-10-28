#!/bin/sh

set -eu

if [ $# -ne 1 ] || [ -z "$1" ]; then
	echo "no" >&2
	exit 1
fi

# workaround missing libgcc_s.so
cp output/host/usr/mipsel-buildroot-linux-uclibc/sysroot/lib/libgcc_s.so.1 "$1/lib"
output/host/usr/mipsel-buildroot-linux-uclibc/bin/strip "$1/lib/libgcc_s.so.1"
ln -f -s libgcc_s.so.1 "$1/lib/libgcc_s.so"

rm "$1/root/.bash_history"
rm "$1/root/.bash_logout"
rm "$1/root/.bash_profile"

find "$1/var" -depth -mindepth 1 | xargs -r rm -r

find "$1/etc/nftables" -type f ! -name inet-filter -delete

exit 0
