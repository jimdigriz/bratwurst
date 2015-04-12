BOARDS			+= qemu/mipsel
NAME-qemu/mipsel	:= QEMU mipsel system

.PHONY:	qemu/mipsel
qemu/mipsel: BOARD	:= qemu/mipsel
qemu/mipsel: | qemu/mipsel-remove-pflash world
	echo mipsel > .qemu-arch

# so we can avoid the slower dev path 'make clean bratwurst'
.PHONY: qemu/mipsel-remove-pflash
qemu/mipsel-remove-pflash:
	rm -f $(PFLASH)
	rsync -qrl rootfs/ buildroot/output/target/
