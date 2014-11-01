ARCH_NATIVE	:= $(uname -m)

ifeq $(filter $(ARCH_NATIVE),x86 x86_64)
ARCH_NATIVE	:= i386
endif

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

FAKEISP_PKGS := linux-image-$(ARCH_NATIVE_KEB)
FAKEISP_PKGS += netbase ifupdown iproute dhcpcd runit
FAKEISP_PKGS += iptables unbound isc-dhcp-server
FAKEISP_PKGS += ppp atm-tools
DEBSITE ?= http://http.debian.net/debian
dl/debs.tar:
ifeq (,$(ARCH_NATIVE_DEB))
	@echo "Sorry '$(ARCH_NATIVE)' not supported"
	@false
endif
	/usr/sbin/debootstrap --arch=$(ARCH_NATIVE_DEB) --variant=minbase \
		--include=$(shell printf "$(FAKEISP_PKGS)" | tr ' ' ,) \
		--make-tarball="$(CURDIR)/$@" wheezy fakeisp/.rootfs $(DEBSITE)

fakeisp/rootfs: dl/debs.tar
ifeq (,$(filter $(shell uname -s),Linux))
	@echo Sorry, this is a Linux only step
	@false
endif
ifneq (,$(shell mount | tac | awk '/noexec|nodev/ { if ($$3 == "$(shell df -l . | sed '$$!d; s/.*% //')") print }'))
	@echo '"$(CURDIR)" is a noexec and/or nodev mountpoint'
	@false
endif
	sudo rm -rf .$@
	sudo debootstrap --arch=$(ARCH_NATIVE_DEB) --variant=minbase \
		--include=$(shell printf "$(FAKEISP_PKGS)" | tr ' ' ,) \
		--unpack-tarball="$(CURDIR)/dl/debs.tar" wheezy .$@ $(DEBSITE)
	sudo chroot .$@ /bin/sh -c "dpkg --get-selections | awk '/deinstall/ { print \$$1 }' | xargs -r dpkg --purge"
	sudo chroot .$@ apt-get -yy autoremove
	sudo chroot .$@ apt-get clean
	sudo find .$@/var/lib/apt/lists -type f -delete
	mv .$@ $@

fakeisp-diy: fakeisp/rootfs
	sudo sh -c "cd fakeisp/rootfs; find . | cpio --create --format='newc' | gzip -c > fakeisp/.$@"
	sudo chown --reference=Makefile fakeisp/.$@
	mv .$@ fakeisp/initrd.base

FAKEISP_KERNEL := http://http.debian.net/debian/dists/wheezy/main/installer-$(ARCH_NATIVE_DEB)/current/images/netboot/debian-installer/$(ARCH_NATIVE_DEB)/linux
fakeisp/vmlinuz:
	curl -L --create-dirs -o dl/linux $(FAKEISP_KERNEL)
	ln -f -s "dl/$(shell basename $(FAKEISP_KERNEL))" $@

FAKEISP_INITRD := http://digriz.downloads.s3-website-eu-west-1.amazonaws.com/bratwurst/fakeisp.initrd.base.$(ARCH_NATIVE_DEB)
fakeisp/initrd.base:
	curl -L --create-dirs -o dl/$@ $(FAKEISP_INITRD)
	ln -f -s "dl/$(shell basename $(FAKEISP_INITRD))" $@

fakeisp/initrd.overlay: fakeisp/overlay fakeisp/initrd.base
	cd overlay/fakeisp; gunzip -c $(CURDIR)/fakeisp.initrd.base | cpio -iv --make-directories etc/init.d/.depend.boot
	cd overlay/fakeisp; find . | cpio --create --format='newc' -R root:root | gzip -c > '$(CURDIR)/.$@'
	rm overlay/fakeisp/etc/init.d/.depend.boot
	mv .$@ $@

fakeisp/initrd: DDPARAMS = status=noxfer of=fakeisp/.initrd ibs=4
fakeisp/initrd: fakeisp/initrd.base fakeisp/initrd.overlay
	dd $(DDPARAMS) conv=sync                      if=fakeisp/initrd.base
	dd $(DDPARAMS) conv=sync,notrunc oflag=append if=fakeisp/initrd.overlay
	mv fakeisp/.$@ $@

PHONY_FAKEISP := fakeisp fakeisp-diy
