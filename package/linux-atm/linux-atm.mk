################################################################################
#
# linux-atm
#
################################################################################

LINUX_ATM_VERSION = 2.5.2
LINUX_ATM_SOURCE = linux-atm-$(LINUX_ATM_VERSION).tar.gz
LINUX_ATM_SITE = http://sourceforge.net/projects/linux-atm/files
LINUX_ATM_DEPENDENCIES = flex
LINUX_ATM_LICENSE = GPLv2
LINUX_ATM_LICENSE_FILES = COPYING

LINUX_ATM_CONF_ENV += \
	CFLAGS="$(TARGET_CFLAGS) -fno-lto -fno-whole-program"
	LDFLAGS="$(TARGET_LDFLAGS) -fno-lto -fno-use-linker-plugin"

LINUX_ATM_CONF_OPTS = --with-kernel-headers=$(STAGING_DIR)/usr/include

$(eval $(autotools-package))
