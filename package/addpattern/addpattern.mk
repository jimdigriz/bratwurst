################################################################################
#
# addpattern
#
################################################################################

ADDPATTERN_SOURCE = addpattern.c
ADDPATTERN_SITE = http://git.openwrt.org/?p=openwrt.git;a=blob_plain;f=tools/firmware-utils/src/

define HOST_ADDPATTERN_EXTRACT_CMDS
	cp $(DL_DIR)/addpattern.c output/build/host-addpattern-undefined/$(ADDPATTERN_SOURCE)
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
