################################################################################
#
# srec2bin
#
################################################################################

SREC2BIN_SOURCE = srec2bin.c
SREC2BIN_SITE = http://git.openwrt.org/?p=openwrt.git;a=blob_plain;f=tools/firmware-utils/src/

define HOST_SREC2BIN_EXTRACT_CMDS
	cp $(DL_DIR)/srec2bin.c output/build/host-srec2bin-undefined/$(SREC2BIN_SOURCE)
endef

define HOST_SREC2BIN_BUILD_CMDS
	cd $(@D) ; \
	$(HOSTCC) $(HOST_CFLAGS) \
		-o srec2bin srec2bin.c
endef

define HOST_SREC2BIN_INSTALL_CMDS
	$(INSTALL) -D $(@D)/srec2bin $(HOST_DIR)/usr/bin/srec2bin
endef

$(eval $(host-generic-package))
