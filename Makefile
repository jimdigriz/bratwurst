VERSION		:= $(shell git rev-parse --short HEAD)$(shell git diff-files --quiet || printf -- -dirty)

ARCHS		:= $(foreach a, $(sort $(wildcard board/qemu/*/post-build.sh)),$(a:board/qemu/%/post-build.sh=%))

ARCH_NATIVE	:= $(shell uname -m)
ARCH_NATIVE_KEB	:= $(ARCH_NATIVE)
ifeq ($(ARCH_NATIVE), x86_64)
	ARCH_NATIVE_DEB	:= amd64
	ARCH_NATIVE_KEB	:= $(ARCH_NATIVE_DEB)
endif
ifeq ($(ARCH_NATIVE), x86)
	ARCH_NATIVE_DEB	:= i386
	ARCH_NATIVE_KEB	:= 686
endif
ifeq ($(filter $(ARCHS), $(ARCH_NATIVE)),)
	ARCH		?= NULL
else
	ARCH		?= $(filter $(ARCHS), $(ARCH_NATIVE))
endif

RAM		?= 16
NAND		?= 4
QEMUOPTS	?=
MTDPARTS	?= 128k(boot)ro,1024k(kernel),2880k(rootfs),64k(config)ro
ROOTFSDEV	?= mtd$(shell echo "$(MTDPARTS)" | sed 's/(rootfs).*//' | awk -F, '{ print NF-1 }')
FSAPPEND	:= mtdparts=physmap-flash.0:$(MTDPARTS) rootfstype=jffs2 root=$(ROOTFSDEV)
APPEND		?=

9P_SHARE	?= shared

all: help

include $(wildcard board/*/*/board.mk)

help:
	@echo 'Cleaning:'
	@echo '  clean                  - clean built rootfs and kernel'
	@echo '  distclean              - delete all files created by build'
	@echo
	@echo 'Run:'
	@echo '  bratwurst              - Spin up bratwurst'
	@echo '    ARCH=<arch>                     (currently: $(ARCH))'
	@echo '      Supported: $(ARCHS)'
	@echo '    RAM=<size-in-megabytes>         (currently: $(RAM))'
	@echo '    NAND=<size-in-megabytes>        (currently: $(NAND))'
	@echo '    QEMUOPTS=<qemu params>          (currently: "$(QEMUOPTS)")'
	@echo
	@echo '    MTDPARTS=<drivers/mtd/cmdlinepart.c>'
	@echo '      Currently: $(MTDPARTS)'
	@echo '    APPEND=<kernel-parameters.txt>  (currently: "$(APPEND)")'
	@echo
	@echo 'Build:'
	@$(foreach board, $(sort $(BOARDS)), \
	  printf "  %-22s - Build for %s\\n" $(board) "$(NAME-$(board))";)
	@echo
	@echo 'Misc:'
	@echo '  9p                     - Export 'shared' over 9P/TCP'
	@echo '    9P_SHARE=<directory>         (currently: "$(9P_SHARE)")'
	@echo
	@echo 'See README.md for further details'

# http://lists.busybox.net/pipermail/buildroot/2012-September/058323.html
clean-brtarget:
	rm -rf buildroot/output/target
	mkdir -p buildroot/output/target/bin
	mkdir -p buildroot/output/target/sbin
	mkdir -p buildroot/output/target/lib
	mkdir -p buildroot/output/target/usr/bin
	mkdir -p buildroot/output/target/usr/sbin
	mkdir -p buildroot/output/target/usr/lib
	test ! -d buildroot/output/staging \
		|| find buildroot/output/staging ! -type d ! -path '*/include/*' \
			| cut -d/ -f4- \
			| tar c -C buildroot/output/staging -T - \
			| tar x -C buildroot/output/target
	rm -f buildroot/output/build/.root
	test ! -d buildroot/output/images || find buildroot/output/images ! -type d | xargs rm -f
	test ! -d buildroot/output/build || find buildroot/output/build -name .stamp_target_installed -o -name .stamp_images_installed | xargs rm -f

clean: clean-brtarget

distclean: clean
	make -C buildroot distclean

bratwurst: BOARD = qemu/$(ARCH)
bratwurst: buildroot/output/images/vmlinuz buildroot/output/images/pflash $(9P_SHARE)
	qemu-system-$(ARCH) -nographic -machine accel=kvm:tcg \
		-m $(RAM) \
		-kernel buildroot/output/images/vmlinuz \
		-append "bratwurstDEV $(FSAPPEND) $(APPEND)" \
		-drive file=buildroot/output/images/pflash,snapshot=on,if=pflash \
		-net nic,model=virtio -net user \
		-net nic,vlan=1,model=virtio -net socket,vlan=1,listen=127.0.0.1:5541 \
		-fsdev local,id=shared_fsdev,path=$(9P_SHARE),security_model=none \
		-device virtio-9p-pci,fsdev=shared_fsdev,mount_tag=shared

fakeisp: fakeisp.vmlinuz fakeisp.initrd $(9P_SHARE)
	qemu-system-$(ARCH_NATIVE) -nographic -machine accel=kvm:tcg \
		-m 512 \
		-kernel fakeisp.vmlinuz \
		-initrd fakeisp.initrd \
		-append "console=ttyS0" \
		-net nic,model=virtio -net user \
		-net nic,vlan=1,macaddr=52:54:00:22:34:56,model=virtio -net socket,vlan=1,connect=127.0.0.1:5541 \
		-fsdev local,id=shared_fsdev,path=$(9P_SHARE),security_model=none \
		-device virtio-9p-pci,fsdev=shared_fsdev,mount_tag=shared

shared:
	mkdir -p $@

py9p/9pfs/9pfs:
	git submodule update --init py9p

9p: py9p/9pfs/9pfs $(9P_SHARE)
	PYTHONPATH=$(CURDIR)/py9p python py9p/9pfs/9pfs -p 5564 -r $(9P_SHARE)

buildroot/.config:
ifeq ($(ARCH), NULL)
	@echo need to pass in a suitable 'ARCH=...'
	@false
endif
ifeq ($(BOARD), NULL)
	@echo something went wrong and BOARD is not defined
	@false
endif
	git submodule update --init buildroot
	make -C buildroot defconfig \
		BR2_EXTERNAL="$(CURDIR)" \
		BR2_DEFCONFIG="$(CURDIR)/board/$(BOARD)/buildroot.config"

buildroot/output/images/%: buildroot/.config
	make -C buildroot \
		BRATWURST_BOARD_DIR="$(CURDIR)/board/$(BOARD)" \
		UCLIBC_CONFIG_FILE="$(CURDIR)/board/$(BOARD)/uclibc.config" \
		BUSYBOX_CONFIG_FILE="$(CURDIR)/config/busybox"

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
		--make-tarball="$(CURDIR)/$@" wheezy .fakeisp.rootfs $(DEBSITE)

fakeisp.rootfs: dl/debs.tar
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
	sudo ln -s /sbin/init .$@/init
	mv .$@ $@

fakeisp.initrd.base.diy: fakeisp.rootfs
	sudo sh -c "cd fakeisp.rootfs; find . | cpio --create --format='newc' | gzip -c > '$(CURDIR)/.$@'"
	sudo chown --reference=Makefile .$@
	mv .$@ fakeisp.initrd.base

FAKEISP_KERNEL := http://http.debian.net/debian/dists/wheezy/main/installer-$(ARCH_NATIVE_DEB)/current/images/netboot/debian-installer/$(ARCH_NATIVE_DEB)/linux
fakeisp.vmlinuz:
	curl -L --create-dirs -o dl/linux $(FAKEISP_KERNEL)
	ln -f -s "dl/$(shell basename $(FAKEISP_KERNEL))" $@

FAKEISP_INITRD := http://digriz.downloads.s3-website-eu-west-1.amazonaws.com/bratwurst/fakeisp.initrd.base.$(ARCH_NATIVE_DEB)
fakeisp.initrd.base:
	wget -P dl -N $(FAKEISP_INITRD)
	ln -f -s "dl/$(shell basename $(FAKEISP_INITRD))" $@

fakeisp.initrd.overlay: overlay.fakeisp fakeisp.initrd.base
	#cd overlay.fakeisp; gunzip -c $(CURDIR)/fakeisp.initrd.base | cpio -iv --make-directories etc/init.d/.depend.boot
	#sed -i -e '/^TARGETS = / s/$$/ bratwurst.sh/; /^networking: / s/$$/ monitorProbe.sh/; $$a monitorProbe.sh: urandom' overlay.fakeisp/etc/init.d/.depend.boot
	#cd overlay.fakeisp; find . | cpio --create --format='newc' -R root:root | gzip -c > '$(CURDIR)/.$@'
	#rm overlay.fakeisp/etc/init.d/.depend.boot
	#mv .$@ $@
	touch $@

fakeisp.initrd: DDPARAMS = status=noxfer of=.fakeisp.initrd ibs=4
fakeisp.initrd: fakeisp.initrd.base fakeisp.initrd.overlay
	dd $(DDPARAMS) conv=sync                      if=fakeisp.initrd.base
	dd $(DDPARAMS) conv=sync,notrunc oflag=append if=fakeisp.initrd.overlay
	mv .$@ $@

.PHONY: all help clean distclean bratwurst 9p $(BOARDS) $(PHONY_BOARD) fakeisp fakeisp.initrd.base.diy
