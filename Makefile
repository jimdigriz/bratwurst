VERSION		:= $(shell git rev-parse --short HEAD)$(shell git diff-files --quiet || printf -- -dirty)

ARCHS		:= $(foreach a, $(sort $(wildcard board/qemu/*/post-build.sh)),$(a:board/qemu/%/post-build.sh=%))

ARCH_NATIVE	:= $(shell uname -m)
ifneq ($(filter $(ARCH_NATIVE), x86 x86_64),)
	ARCH_NATIVE	:= i386
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

.PHONY: all help clean distclean bratwurst 9p $(BOARDS) $(PHONY_BOARD)
