VERSION		:= $(shell git rev-parse --short HEAD)$(shell git diff-files --quiet || printf -- -dirty)

ARCHS		:= $(foreach b, $(sort $(wildcard board/qemu/*)),$(subst board/qemu/,,$(b)))

ARCH_NATIVE	:= $(shell uname -m)
ifneq ($(filter $(ARCH_NATIVE), x86 x86_64),)
	QEMU_ARCH	:= i386
	ARCH_NATIVE	:= x86
	VMLINUX		:= bzImage
endif

ARCH		?= $(ARCH_NATIVE)
QEMU_ARCH	?= $(ARCH)
VMLINUX		?= vmlinux
RAM		?= 16
NAND		?= 4
QEMUOPTS	?= 
MTDPARTS	?= 128k(boot),1024k(kernel),2880k(rootfs),64k(config)
ROOTFSDEV	?= mtd$(shell echo "$(MTDPARTS)" | sed 's/(rootfs).*//' | awk -F, '{ print NF-1 }')
FSAPPEND	?= mtdparts=physmap-flash.0:$(MTDPARTS) rootfstype=jffs2 root=$(ROOTFSDEV)
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
	find buildroot/output/staging/ ! -type d ! -path '*/include/*' | cut -d/ -f4- \
		| tar c -C buildroot/output/staging -T - \
		| tar x -C buildroot/output/target
	rm -f buildroot/output/build/.root
	find buildroot/output/images -type f | xargs rm -f
	find buildroot/output/build -name .stamp_target_installed -o -name .stamp_images_installed | xargs rm -f

clean: clean-brtarget

distclean: clean
	make -C buildroot distclean

bratwurst: BOARD = qemu/$(ARCH)
bratwurst: buildroot/output/images/vmlinuz buildroot/output/images/pflash $(9P_SHARE)
	qemu-system-$(QEMU_ARCH) -nographic -machine accel=kvm:tcg \
		-m $(RAM) \
		-kernel buildroot/output/images/$(VMLINUX) \
		-append "bratwurstDEV $(FSAPPEND) $(APPEND)" \
		-drive file=buildroot/output/images/pflash,snapshot=on,if=pflash \
		-net nic,model=virtio -net user \
		-fsdev local,id=shared_fsdev,path=$(9P_SHARE),security_model=none \
		-device virtio-9p-pci,fsdev=shared_fsdev,mount_tag=shared

shared:
	mkdir -p $@

py9p/9pfs/9pfs:
	git submodule update --init py9p

9p: py9p/9pfs/9pfs $(9P_SHARE)
	PYTHONPATH=$(CURDIR)/py9p python py9p/9pfs/9pfs -p 5564 -r $(9P_SHARE)

buildroot/.config:
	@[ "$(BOARD)" ] || { echo something went wrong and BOARD is not defined; false; }
	git submodule update --init buildroot
	make -C buildroot defconfig \
		BR2_DEFCONFIG="$(CURDIR)/board/$(BOARD)/buildroot.config"

buildroot/output/images/%: buildroot/.config
	make -C buildroot \
		BR2_DL_DIR="$(CURDIR)/dl"

.PHONY: all help clean distclean bratwurst 9p $(BOARDS) $(PHONY_BOARD)
