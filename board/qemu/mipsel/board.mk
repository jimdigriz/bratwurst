BOARDS			+= qemu/mipsel
NAME-qemu/mipsel	:= QEMU mipsel system

ARCHS			+= mipsel

.PHONY:	qemu/mipsel
qemu/mipsel: ARCH	:= mipsel
qemu/mipsel: BOARD	:= qemu/mipsel
qemu/mipsel: VMLINUZ	:= buildroot/output/images/vmlinuz
qemu/mipsel: PFLASH	:= buildroot/output/images/pflash
qemu/mipsel: world
