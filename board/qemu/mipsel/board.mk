BOARDS			+= qemu/mipsel
NAME-qemu/mipsel	:= QEMU mipsel system

.PHONY:	qemu/mipsel
qemu/mipsel: ARCH	:= mipsel
qemu/mipsel: BOARD	:= qemu/mipsel
qemu/mipsel: world
