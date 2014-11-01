P	:= qemu
A	:= mipsel
B	:= $(P)/$(A)
ARCHS	+= $(A)
BOARDS	+= $(B)

NAME-$(B)	:= $(B) system

$(B): PLAT	:= $(P)
$(B): ARCH	:= $(A)
$(B): BOARD	:= $(B)
$(B): buildroot
