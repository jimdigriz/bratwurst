#!/bin/sh

set -eu

if [ $# -ne 1 ] || [ -z "$1" ]; then
	echo "no" >&2
	exit 1
fi

ROOTDIR="$1"

find "$ROOTDIR" -type f -name .keep -delete

for U in $(ls -1 ../users | sed -n '/^[a-z0-9]*$/ p'); do
	mkdir -m 750 -p "$ROOTDIR/home/$U/.ssh"

	cp ../users/$U "$ROOTDIR/home/$U/.ssh/authorized_keys"
	chmod 640 "$ROOTDIR/home/$U/.ssh/authorized_keys"
done

FILES="	etc/atmsigd.conf
	etc/hosts.atm
	usr/sbin/hediag
	usr/sbin/lecs
	usr/sbin/atmsigd
	usr/sbin/zntune
	usr/sbin/pppstats
	usr/sbin/pppoe-discovery
	usr/sbin/atmarp
	usr/sbin/ilmidiag
	usr/sbin/bus
	usr/sbin/mpcd
	usr/sbin/esi
	usr/sbin/atmarpd
	usr/sbin/atmloop
	usr/sbin/chat
	usr/sbin/zeppelin
	usr/sbin/ilmid
	usr/sbin/pppdump
	usr/sbin/les
	usr/sbin/enitune
	usr/sbin/atmaddr
	usr/bin/awrite
	usr/bin/svc_recv
	usr/bin/sonetdiag
	usr/bin/ngettext
	usr/bin/atmdiag
	usr/bin/atmswitch
	usr/bin/gettext
	usr/bin/svc_send
	usr/bin/envsubst
	usr/bin/saaldump
	usr/bin/atmdump
	usr/bin/ttcp_atm
	usr/bin/aread
	usr/bin/gettext.sh
	usr/share/udhcpc/default.script
	lib/firmware/pca200e.bin
	lib/firmware/pca200e_ecd.bin2
	lib/firmware/sba200e_ecd.bin2"
echo "$FILES" | xargs -I{} rm -f "$ROOTDIR/{}"

find "$ROOTDIR/usr/share" -empty -delete

find "$ROOTDIR/usr/lib/pppd/2.4.7" -type f ! -name pppoatm.so ! -name rp-pppoe.so -delete

find "$ROOTDIR/etc/nftables" -type f ! -name '[0-9]*' -delete

exit 0
