################################################################################
#
# srecord
#
################################################################################

SRECORD_VERSION = 1.64
SRECORD_SOURCE = srecord-$(SRECORD_VERSION).tar.gz
SRECORD_SITE = http://srecord.sourceforge.net/
SRECORD_LICENSE = GPLv2

define HOST_SRECORD_BUILD_CMDS
	$(HOST_CONFIGURE_OPTS) $(MAKE) -C $(@D)
endef

define HOST_SRECORD_INSTALL_CMDS
	$(HOST_CONFIGURE_OPTS) $(MAKE) -C $(@D) \
		install DESTDIR=$(HOST_DIR)
endef

$(eval $(host-autotools-package))
