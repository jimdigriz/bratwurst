PLAT		?= qemu
ARCH		?= mipsel
BOARD		:= $(PLAT)/$(ARCH)

RAM		?= 16
NAND		?= 4
MTDPARTS	?= 128k(boot)ro,1024k(kernel),2880k(rootfs),64k(config)ro
ROOTFSDEV	?= mtd$(shell echo "$(MTDPARTS)" | sed 's/(rootfs).*//' | awk -F, '{ print NF-1 }')
FSAPPEND	:= mtdparts=physmap-flash.0:$(MTDPARTS) rootfstype=jffs2 root=$(ROOTFSDEV)
APPEND		?=

9P_SHARE	?= shared

MAKEFLAGS	+= --no-builtin-rules
.SUFFIXES:

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
	  printf "  %-16s - Build for %s\\n" $(board) "$(NAME-$(board))";)
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

# http://lists.busybox.net/pipermail/buildroot/2012-September/058323.html
.PHONY: clean-brtarget
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
	test ! -d buildroot/output/images \
		|| find buildroot/output/images ! -type d \
			| xargs rm -f
	test ! -d buildroot/output/build \
		|| find buildroot/output/build -name .stamp_target_installed -o -name .stamp_images_installed \
			| xargs rm -f

.PHONY: clean
clean: clean-brtarget
	rm -f fakeisp/vmlinuz fakeisp/initrd*
	test ! -d fakeisp/rootfs || sudo rm -rf fakeisp/rootfs

.PHONY: distclean
distclean: clean
	make -C buildroot distclean

VMLINUZ		:= buildroot/output/images/vmlinuz
PFLASH		:= buildroot/output/images/pflash
.PHONY: bratwurst
bratwurst: $(VMLINUZ) $(PFLASH) $(9P_SHARE)
	qemu-system-$(ARCH) -nographic -machine accel=kvm:tcg \
		-m $(RAM) \
		-kernel $(VMLINUZ) \
		-append "$(FSAPPEND) $(APPEND)" \
		-drive file=$(PFLASH),snapshot=on,if=pflash \
		-net nic,vlan=1,model=virtio \
			-net socket,listen=127.0.0.1:5541 \
		-net nic,vlan=2,model=virtio \
			-net dump,vlan=2,file=$@.pcap \
		-fsdev local,id=shared_fsdev,path=$(9P_SHARE),security_model=none \
		-device virtio-9p-pci,fsdev=shared_fsdev,mount_tag=shared

buildroot/.config:
	git submodule update --init buildroot
	make -C buildroot defconfig \
		BR2_EXTERNAL="$(CURDIR)" \
		BR2_DEFCONFIG="$(CURDIR)/board/$(BOARD)/buildroot.config"

$(VMLINUZ) $(PFLASH): buildroot

.PHONY: buildroot menuconfig savedefconfig %-menuconfig %-savedefconfig
buildroot menuconfig savedefconfig %-menuconfig %-savedefconfig: buildroot/.config
	make -C buildroot $(subst buildroot,,$@) \
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
