#!/bin/sh

set -eu

if [ $# -ne 1 ] || [ -z "$1" ]; then
	echo "no" >&2
	exit 1
fi

ROOTDIR="$1"

rsync -rl ../board/qemu/mipsel/overlay/ "$ROOTDIR/"

find "$ROOTDIR/usr/lib/pppd/2.4.7" -type f ! -name pppoatm.so ! -name rp-pppoe.so -delete

FILES="	sbin/hediag
	sbin/lecs
	sbin/atmsigd
	sbin/zntune
	sbin/pppstats
	sbin/atmarp
	sbin/ilmidiag
	sbin/bus
	sbin/mpcd
	sbin/esi
	sbin/atmarpd
	sbin/atmloop
	sbin/chat
	sbin/zeppelin
	sbin/ilmid
	sbin/pppdump
	sbin/les
	sbin/enitune
	sbin/atmaddr
	bin/awrite
	bin/svc_recv
	bin/sonetdiag
	bin/ngettext
	bin/atmdiag
	bin/atmswitch
	bin/gettext
	bin/svc_send
	bin/envsubst
	bin/saaldump
	bin/atmdump
	bin/ttcp_atm
	bin/aread
	bin/gettext.sh"

echo "$FILES" | xargs -I{} rm -f "$ROOTDIR/usr/{}"

find "$ROOTDIR/var" -depth -mindepth 1 | xargs -r rm -r

find "$ROOTDIR/etc/nftables" -type f ! -name inet-filter -delete

rm -rf "$ROOTDIR/usr/lib32"
rm -rf "$ROOTDIR/usr/share/locale"

rm -f "$ROOTDIR/root/.bash_history"
rm -f "$ROOTDIR/root/.bash_logout"
rm -f "$ROOTDIR/root/.bash_profile"

exit 0
