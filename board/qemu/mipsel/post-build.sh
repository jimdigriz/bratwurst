#!/bin/sh

set -eu

if [ $# -ne 1 ] || [ -z "$1" ]; then
	echo "no" >&2
	exit 1
fi

rm "$1/root/.bash_history"
rm "$1/root/.bash_logout"
rm "$1/root/.bash_profile"

find "$1/var" -depth -mindepth 1 | xargs -r rm -r

find "$1/etc/nftables" -type f ! -name inet-filter -delete

exit 0
