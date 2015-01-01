BOARDS			+= ar7/wag54g
NAME-ar7/wag54g		:= Linksys WAG54G

.PHONY:	ar7/wag54g
ar7/wag54g: ARCH	:= mipsel
ar7/wag54g: BOARD	:= ar7/wag54g
ar7/wag54g: world
