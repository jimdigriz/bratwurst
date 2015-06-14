################################################################################
#
# addpattern
#
################################################################################

ADDPATTERN_SOURCE = addpattern.c
ADDPATTERN_VERSION = 38685
ADDPATTERN_SITE = https://dev.openwrt.org/export/$(ADDPATTERN_VERSION)/trunk/tools/firmware-utils/src

define HOST_ADDPATTERN_EXTRACT_CMDS
	cp $(DL_DIR)/addpattern.c output/build/host-addpattern-$(ADDPATTERN_VERSION)/$(ADDPATTERN_SOURCE)
endef

define HOST_ADDPATTERN_BUILD_CMDS
	cd $(@D) ; \
	$(HOSTCC) $(HOST_CFLAGS) \
		-o addpattern addpattern.c
endef

define HOST_ADDPATTERN_INSTALL_CMDS
	$(INSTALL) -D $(@D)/addpattern $(HOST_DIR)/usr/bin/addpattern
endef

$(eval $(host-generic-package))
