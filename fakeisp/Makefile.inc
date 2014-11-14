ARCH_NATIVE	:= $(shell uname -m)
ARCH_NATIVE_KEB	:= $(ARCH_NATIVE)

ifneq ($(filter $(ARCH_NATIVE),i386 i486 i586 i686 x86_64),)
ARCH_NATIVE	:= i386
ARCH_NATIVE_KEB	:= 686
endif

.PHONY: fakeisp
fakeisp: fakeisp/vmlinuz fakeisp/initrd $(9P_SHARE)
	qemu-system-$(ARCH_NATIVE) -nographic -machine accel=kvm:tcg \
		-m 512 \
		-kernel fakeisp/vmlinuz \
		-initrd fakeisp/initrd \
		-append "console=ttyS0" \
		-net nic,model=virtio -net user \
		-net nic,vlan=1,macaddr=52:54:00:22:34:56,model=virtio -net socket,vlan=1,connect=127.0.0.1:5541 \
		-fsdev local,id=shared_fsdev,path=$(9P_SHARE),security_model=none \
		-device virtio-9p-pci,fsdev=shared_fsdev,mount_tag=shared

.PHONY: clean-fakeisp
clean-fakeisp:
	rm -f fakeisp/vmlinuz fakeisp/initrd*
	test ! -d fakeisp/rootfs || sudo rm -rf fakeisp/rootfs

FAKEISP_PKGS := linux-image-$(ARCH_NATIVE_KEB)
FAKEISP_PKGS += netbase ifupdown iproute dhcpcd runit
FAKEISP_PKGS += iptables unbound isc-dhcp-server
FAKEISP_PKGS += ppp atm-tools
DEBSITE ?= http://http.debian.net/debian
dl/debs.tar:
	/usr/sbin/debootstrap --arch=$(ARCH_NATIVE) --variant=minbase \
		--include=$(shell printf "$(FAKEISP_PKGS)" | tr ' ' ,) \
		--make-tarball="$(CURDIR)/$@" wheezy fakeisp/.rootfs.debs $(DEBSITE)

fakeisp/rootfs: dl/debs.tar
ifeq (,$(filter $(shell uname -s),Linux))
	@echo Sorry, this is a Linux only step
	@false
endif
ifneq (,$(shell mount | tac | awk '/noexec|nodev/ { if ($$3 == "$(shell df -l . | sed '$$!d; s/.*% //')") print }'))
	@echo '"$(CURDIR)" is a noexec and/or nodev mountpoint'
	@false
endif
	sudo rm -rf fakeisp/.rootfs
	sudo debootstrap --arch=$(ARCH_NATIVE) --variant=minbase \
		--include=$(shell printf "$(FAKEISP_PKGS)" | tr ' ' ,) \
		--unpack-tarball="$(CURDIR)/dl/debs.tar" wheezy fakeisp/.rootfs $(DEBSITE)
	sudo chroot fakeisp/.rootfs /bin/sh -c "dpkg --get-selections | awk '/deinstall/ { print \$$1 }' | xargs -r dpkg --purge"
	sudo chroot fakeisp/.rootfs apt-get -yy autoremove
	sudo chroot fakeisp/.rootfs apt-get clean
	sudo find fakeisp/.rootfs/var/lib/apt/lists -type f -delete
	mv fakeisp/.rootfs $@

.PHONY: fakeisp-diy
fakeisp-diy: fakeisp/rootfs
	sudo sh -c "cd fakeisp/rootfs; find . | cpio --create --format='newc' | gzip -c > ../.initrd.base"
	sudo chown --reference=Makefile fakeisp/.initrd.base
	mv fakeisp/.initrd.base fakeisp/initrd.base

FAKEISP_KERNEL := http://http.debian.net/debian/dists/wheezy/main/installer-$(ARCH_NATIVE)/current/images/netboot/debian-installer/$(ARCH_NATIVE)/linux
fakeisp/vmlinuz:
	curl -f -L --create-dirs -o dl/$@ $(FAKEISP_KERNEL)
	ln -f -s ../dl/$@ $@

FAKEISP_INITRD := http://digriz.downloads.s3-website-eu-west-1.amazonaws.com/bratwurst/fakeisp.initrd.base.$(ARCH_NATIVE)
fakeisp/initrd.base:
	curl -f -L --create-dirs -o dl/$@ $(FAKEISP_INITRD)
	ln -f -s ../dl/$@ $@

fakeisp/initrd.overlay: fakeisp/overlay fakeisp/initrd.base
	cd fakeisp/overlay; gunzip -c ../initrd.base | cpio -iv --make-directories etc/init.d/.depend.boot
	cd fakeisp/overlay; find . | cpio --create --format='newc' -R root:root | gzip -c > ../.initrd.overlay
	rm fakeisp/overlay/etc/init.d/.depend.boot
	mv fakeisp/.initrd.overlay $@

fakeisp/initrd: DDPARAMS = status=noxfer of=fakeisp/.initrd ibs=4
fakeisp/initrd: fakeisp/initrd.base fakeisp/initrd.overlay
	dd $(DDPARAMS) conv=sync                      if=fakeisp/initrd.base
	dd $(DDPARAMS) conv=sync,notrunc oflag=append if=fakeisp/initrd.overlay
	mv fakeisp/.initrd $@
