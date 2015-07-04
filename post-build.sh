#!/bin/sh

set -eu

if [ $# -ne 1 ] || [ -z "$1" ]; then
	echo "no" >&2
	exit 1
fi

ROOTDIR="$1"

VERSION=$(git --git-dir=../.git log -n1 --abbrev=10 --format=%h)$(git --git-dir=../.git diff-files --quiet || printf -- -dirty)
sed -i "\$aBRATWURST_VERSION=$VERSION
/BRATWURST_VERSION/ d;" "$ROOTDIR/etc/os-release"

find output/target/lib/modules -type f -name 'modules.*' -delete

cp ../bratwurst.config "$ROOTDIR/etc/bratwurst"

find "$ROOTDIR" -type f -name .keep -delete

for U in $(ls -1 ../users | sed -n '/^[a-z0-9]*$/ p'); do
	mkdir -m 750 -p "$ROOTDIR/home/$U/.ssh"

	cp ../users/$U "$ROOTDIR/home/$U/.ssh/authorized_keys"
	chmod 640 "$ROOTDIR/home/$U/.ssh/authorized_keys"
done

for K in dropbear_rsa_host_key dropbear_dss_host_key; do
	[ -f ../dropbear/$K ] || continue

	cp ../dropbear/$K "$ROOTDIR/dropbear"
	chmod 600 "$ROOTDIR/dropbear/$K"
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
	lib/firmware/pca200e.bin
	lib/firmware/pca200e_ecd.bin2
	lib/firmware/sba200e_ecd.bin2"
echo "$FILES" | xargs -I{} rm -f "$ROOTDIR/{}"

find "$ROOTDIR/usr/lib/pppd/2.4.7" -type f ! -name pppoatm.so ! -name rp-pppoe.so -delete

find "$ROOTDIR/etc/nftables" -type f ! -name '[0-9]*' -delete

exit 0
