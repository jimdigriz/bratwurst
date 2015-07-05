################################################################################
#
# mktplinkfw2
#
################################################################################

MKTPLINKFW2_SOURCE = mktplinkfw2.c
MKTPLINKFW2_VERSION = 43897
MKTPLINKFW2_SITE = https://dev.openwrt.org/export/$(MKTPLINKFW2_VERSION)/trunk/tools/firmware-utils/src

HOST_MKTPLINKFW2_EXTRA_DOWNLOADS = https://dev.openwrt.org/export/$(MKTPLINKFW2_VERSION)/trunk/tools/include/endian.h md5.c md5.h

define HOST_MKTPLINKFW2_EXTRACT_CMDS
	cp $(DL_DIR)/mktplinkfw2.c output/build/host-mktplinkfw2-$(MKTPLINKFW2_VERSION)/$(MKTPLINKFW2_SOURCE)
	cp $(DL_DIR)/endian.h $(DL_DIR)/md5.h $(DL_DIR)/md5.c output/build/host-mktplinkfw2-$(MKTPLINKFW2_VERSION)
endef

define HOST_MKTPLINKFW2_BUILD_CMDS
	cd $(@D) ; \
	$(HOSTCC) $(HOST_CFLAGS) -include endian.h $(HOST_LDFLAGS) \
		-o mktplinkfw2 mktplinkfw2.c md5.c
endef

define HOST_MKTPLINKFW2_INSTALL_CMDS
	$(INSTALL) -D $(@D)/mktplinkfw2 $(HOST_DIR)/usr/bin/mktplinkfw2
endef

$(eval $(host-generic-package))
