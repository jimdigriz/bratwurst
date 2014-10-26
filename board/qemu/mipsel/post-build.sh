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

# musl bugs
ln -f -s /lib/libc.so "$1/lib/ld-musl-mipsel.so.1"
cp output/host/usr/mipsel-buildroot-linux-musl/sysroot/lib/libgcc_s.so.1 "$1/lib"
./output/host/usr/mipsel-buildroot-linux-musl/bin/strip "$1/lib/libgcc_s.so.1"
ln -f -s libgcc_s.so.1 "$1/lib/libgcc_s.so"

exit 0

HOSTNAME=buildroot
DOMAIN=eduroam.org
# generate your hash with 'makepasswd --crypt-md5 --clearfrom=-' (default: changeme)
ROOTPASSWD='$1$IgQqQBnb$yUejfxiSdEogcNQRqV2YE.'
NTP=uk.pool.ntp.org

jamvm_export () {
	grep -q BR2_PACKAGE_JAMVM=y .config || return 0

	if test -x "$TARGET/usr/bin/jamvm"; then
		mkdir -p ../shared/jamvm/bin
		mv "$TARGET/usr/bin/jamvm" ../shared/jamvm/bin
	fi
	if test -d "$TARGET/usr/share/classpath"; then
		mkdir -p ../shared/jamvm/share
		mv "$TARGET/usr/share/classpath" ../shared/jamvm/share
		ln -s -t "$TARGET/usr/share" /tmp/shared/jamvm/share/classpath
	fi
	if test -d "$TARGET/usr/share/jamvm"; then
		mkdir -p ../shared/jamvm/share
		mv "$TARGET/usr/share/jamvm" ../shared/jamvm/share
		ln -s -t "$TARGET/usr/share" /tmp/shared/jamvm/share/jamvm
	fi
	if test -d "$TARGET/usr/lib/classpath"; then
		mkdir -p ../shared/jamvm/lib
		mv "$TARGET/usr/lib/classpath" ../shared/jamvm/lib
		ln -s -t "$TARGET/usr/lib" /tmp/shared/jamvm/lib/classpath
	fi
}

# plumb in what we want to run
ln -f -s /sbin/init "$TARGET/init"

## remove unwanted stuff
rm -rf "$TARGET/var/lib"
rm -rf "$TARGET/var/pcmcia"
rm -rf "$TARGET/home/ftp"
rm -f "$TARGET/linuxrc"
# we don't run no bash
rm -f "$TARGET/root/.bash*"
# these are under runit
rm -f "$TARGET/etc/init.d/S01logging"
rm -f "$TARGET/etc/init.d/S50dropbear"

# use printf instead
sed -i -e 's/echo -n/printf/' "$TARGET/etc/init.d/S20urandom" "$TARGET/etc/init.d/S40network"

# plumb in runit
rm -f "$TARGET/etc/service"
ln -f -s -T ../tmp/service "$TARGET/var/service"

# fix up /etc/fstab
sed -i -e 's/ext2/auto/' "$TARGET/etc/fstab"
sed -i -e '/devpts/ d' "$TARGET/etc/fstab"
sed -i -e '/shm/ d' "$TARGET/etc/fstab"

# fix user accounts
#sed -i -e "/^root:/ s/^root:[^:]*:/root:$ROOTPASSWD:/" $TARGET/etc/shadow
sed -i -e '/^default:/ d' $TARGET/etc/passwd $TARGET/etc/group $TARGET/etc/shadow

echo -n $HOSTNAME > "$TARGET/etc/hostname"
sed -i -e "s/%HOSTNAME%/$HOSTNAME/g; s/%DOMAIN%/$DOMAIN/" "$TARGET/etc/hosts"

sed -i -e "s/%NTP%/$NTP/" "$TARGET/etc/sv/ntpd/run"

[ ! -f /etc/debian_version ] || CERT=ca-certificates.crt
[ ! -f /etc/redhat-release ] || CERT=ca-bundle.crt
[ "${CERT:-}" ] && cp -f "/etc/ssl/certs/$CERT" "$TARGET/opt/monitorProbe/ca-certificates.crt"

jamvm_export

exit 0
