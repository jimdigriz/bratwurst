ARCH		?= mipsel
BOARD		?= qemu/mipsel

RAM		?= 16
NAND		?= 4
MTDPARTS	?= 128k(boot)ro,1024k(kernel),2880k(rootfs),64k(config)ro
ROOTFSDEV	?= mtd$(shell echo "$(MTDPARTS)" | sed 's/(rootfs).*//' | awk -F, '{ print NF-1 }')
FSAPPEND	:= mtdparts=physmap-flash.0:$(MTDPARTS) rootfstype=jffs2 root=$(ROOTFSDEV)
APPEND		?=

9P_SHARE	?= shared

.PHONY: all
all: help

include fakeisp/Makefile.inc
include $(wildcard board/*/*/board.mk)

.PHONY: help
help:
	@echo 'Cleaning:'
	@echo '  clean            - clean built rootfs and kernel'
	@echo '  distclean        - delete all files created by build'
	@echo
	@echo 'Build Firmware:'
	@$(foreach board, $(sort $(BOARDS)), \
	  printf "  %-16s - %s\\n" $(board) "$(NAME-$(board))";)
	@echo
	@echo 'Run:'
	@echo '  bratwurst        - Spin up bratwurst'
	@echo '    ARCH=<arch>                     (currently: $(ARCH))'
	@echo '      Supported: $(ARCHS)'
	@echo '    RAM=<size-in-megabytes>         (currently: $(RAM))'
	@echo '    NAND=<size-in-megabytes>        (currently: $(NAND))'
	@echo
	@echo '    MTDPARTS=<drivers/mtd/cmdlinepart.c>'
	@echo '      Currently: $(MTDPARTS)'
	@echo '    APPEND=<kernel-parameters.txt>  (currently: "$(APPEND)")'
	@echo
	@echo 'Misc:'
	@echo '  fakeisp          - Spin up a fake ISP'
	@echo '  9p               - Export a share over 9P/TCP'
	@echo '    9P_SHARE=<directory>            (currently: "$(9P_SHARE)")'
	@echo
	@echo 'See README.md for further details'

.PHONY: clean
clean:
	# http://lists.busybox.net/pipermail/buildroot/2012-September/058323.html
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
	test ! -d buildroot/output/images \
		|| find buildroot/output/images ! -type d \
			| xargs rm -f
	test ! -d buildroot/output/build \
		|| { \
			find buildroot/output/build -name .stamp_target_installed -o -name .stamp_images_installed \
				| xargs rm -f; \
			# otherwise libgcc_s.so is lost \
			find buildroot -name .stamp_host_installed -path '*/host-gcc-final-*' \
				| xargs rm -f; \
		}
	rm -f .users

.PHONY: distclean
distclean: clean
	make -C buildroot distclean
	rm -rf ccache

VMLINUZ		:= buildroot/output/images/vmlinuz
PFLASH		:= buildroot/output/images/pflash
$(VMLINUZ) $(PFLASH): world

.PHONY: bratwurst
bratwurst: $(VMLINUZ) $(PFLASH)

.PHONY: qemu
qemu: bratwurst $(9P_SHARE)
	qemu-system-$(ARCH) -nodefaults -nographic -machine accel=kvm:tcg \
		-serial mon:stdio \
		-m $(RAM) \
		-kernel $(VMLINUZ) \
		-append "$(FSAPPEND) $(APPEND)" \
		-drive file=$(PFLASH),snapshot=on,if=pflash \
		-net nic,vlan=1,model=virtio \
			-net socket,vlan=1,mcast=239.69.69.69:5541,localaddr=127.0.0.1 \
		-net nic,vlan=2,model=virtio \
			-net none,vlan=2 \
		-fsdev local,id=shared_fsdev,path=$(9P_SHARE),security_model=none \
		-device virtio-9p-pci,fsdev=shared_fsdev,mount_tag=shared

.users:
	ls -1 users | sed -n '/^[a-z0-9]*$$/ s~.*~& -1 & -1 * /home/& /bin/sh - &~ p' > .users

.buildroot.defconfig:
	cat board/$(BOARD)/buildroot config/buildroot > .$@
	mv .$@ $@

buildroot: buildroot/.git

buildroot/.git:
	git submodule update --init buildroot

buildroot/.config: | .buildroot.defconfig buildroot
	make -C buildroot defconfig \
		BR2_EXTERNAL="$(CURDIR)" \
		BR2_DEFCONFIG="$(CURDIR)/.buildroot.defconfig"

.PHONY: buildroot-update-defconfig
buildroot-update-defconfig:
	make -C buildroot savedefconfig \
		BRATWURST_BOARD_DIR="$(CURDIR)/board/$(BOARD)" \
		UCLIBC_CONFIG_FILE="$(CURDIR)/board/$(BOARD)/uclibc.config" \
		BUSYBOX_CONFIG_FILE="$(CURDIR)/config/busybox"
	sed -n 's/^config \(.*\)/\1/ p' buildroot/arch/* | sort | uniq > .list
	echo BR2_PACKAGE_AR7_ATM >> .list
	echo BR2_PACKAGE_HOST_SRECORD >> .list
	echo BR2_PACKAGE_HOST_SREC2BIN >> .list
	echo BR2_PACKAGE_HOST_ADDPATTERN >> .list
	grep    -F -f .list .buildroot.defconfig > board/$(BOARD)/buildroot
	grep -v -F -f .list .buildroot.defconfig > config/buildroot
	rm .list

.PHONY: uclibc-update-defconfig
uclibc-update-defconfig:
	cp buildroot/output/build/uclibc-0.9.33.2/.config $(CURDIR)/board/$(BOARD)/uclibc.config

.PHONY: busybox-update-defconfig
busybox-update-defconfig:
	cp buildroot/output/build/busybox-1.22.1/.config $(CURDIR)/config/busybox

.PHONY: world %-menuconfig %-update-defconfig
world %-menuconfig %-update-defconfig: buildroot/.config .users
	make -C buildroot $(subst buildroot-,,$@) \
		BRATWURST_BOARD_DIR="$(CURDIR)/board/$(BOARD)" \
		UCLIBC_CONFIG_FILE="$(CURDIR)/board/$(BOARD)/uclibc.config" \
		BUSYBOX_CONFIG_FILE="$(CURDIR)/config/busybox"

$(9P_SHARE):
	mkdir -p $(9P_SHARE)

py9p/9pfs/9pfs:
	git submodule update --init py9p
	make -C py9p dist

.PHONY: 9p
9p: py9p/9pfs/9pfs $(9P_SHARE)
	PYTHONPATH=$(CURDIR)/py9p python py9p/9pfs/9pfs -p 5564 -r $(9P_SHARE)
