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

BR_OUTPUT	?= buildroot/output

all: help

#include fakeisp/Makefile.inc
include $(wildcard board/*/*/board.mk)

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
clean-brtarget:
	rm -rf $(BR_OUTPUT)/target
	mkdir -p $(BR_OUTPUT)/target/bin
	mkdir -p $(BR_OUTPUT)/target/sbin
	mkdir -p $(BR_OUTPUT)/target/lib
	mkdir -p $(BR_OUTPUT)/target/usr/bin
	mkdir -p $(BR_OUTPUT)/target/usr/sbin
	mkdir -p $(BR_OUTPUT)/target/usr/lib
	test ! -d $(BR_OUTPUT)/staging \
		|| find $(BR_OUTPUT)/staging ! -type d ! -path '*/include/*' \
			| cut -d/ -f4- \
			| tar c -C $(BR_OUTPUT)/staging -T - \
			| tar x -C $(BR_OUTPUT)/target
	rm -f $(BR_OUTPUT)/build/.root
	test ! -d $(BR_OUTPUT)/images || find $(BR_OUTPUT)/images ! -type d | xargs rm -f
	test ! -d $(BR_OUTPUT)/build || find $(BR_OUTPUT)/build -name .stamp_target_installed -o -name .stamp_images_installed | xargs rm -f

clean: clean-brtarget
	rm -f fakeisp/vmlinuz fakeisp/initrd*
	test ! -d fakeisp/rootfs || sudo rm -rf fakeisp/rootfs

distclean: clean
	make -C buildroot distclean

VMLINUZ	:= $(BR_OUTPUT)/images/qemu/$(ARCH)/vmlinuz
PFLASH	:= $(BR_OUTPUT)/images/qemu/$(ARCH)/pflash
bratwurst: $(VMLINUZ) $(PFLASH) $(9P_SHARE)
	qemu-system-$(ARCH) -nographic -machine accel=kvm:tcg \
		-m $(RAM) \
		-kernel $(VMLINUZ) \
		-append "bratwurstDEV $(FSAPPEND) $(APPEND)" \
		-drive file=$(PFLASH),snapshot=on,if=pflash \
		-net nic,vlan=1,model=virtio \
			-net socket,listen=127.0.0.1:5541 \
		-net nic,vlan=2,model=virtio,restrict=on \
			-net dump,vlan=2,file=bratwurst.pcap \
		-fsdev local,id=shared_fsdev,path=$(9P_SHARE),security_model=none \
		-device virtio-9p-pci,fsdev=shared_fsdev,mount_tag=shared

py9p/9pfs/9pfs:
	git submodule update --init py9p

9p: py9p/9pfs/9pfs $(9P_SHARE)
	mkdir -p $(9P_SHARE)
	PYTHONPATH=$(CURDIR)/py9p python py9p/9pfs/9pfs -p 5564 -r $(9P_SHARE)

buildroot/.config:
	git submodule update --init buildroot
	make -C buildroot defconfig \
		BR2_EXTERNAL="$(CURDIR)" \
		BR2_DEFCONFIG="$(CURDIR)/board/$(BOARD)/buildroot.config"

buildroot menuconfig %-menuconfig: buildroot/.config
	make -C buildroot $(subst buildroot,,$@) \
		BRATWURST_BOARD_DIR="$(CURDIR)/board/$(BOARD)" \
		UCLIBC_CONFIG_FILE="$(CURDIR)/board/$(BOARD)/uclibc.config" \
		BUSYBOX_CONFIG_FILE="$(CURDIR)/config/busybox"

$(BR_OUTPUT)/images/$(PLAT)/$(ARCH)/%: buildroot
	mkdir -p $(BR_OUTPUT)/images/$(PLAT)/$(ARCH)
	mv $(BR_OUTPUT)/images/$(notdir $@) $(BR_OUTPUT)/images/$(PLAT)/$(ARCH)

.PHONY: all help clean distclean bratwurst buildroot menuconfig %-menuconfig 9p $(BOARDS) $(PHONY_BOARD) $(PHONY_FAKEISP)
