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

IPSEC_TOOLS_CONF_OPT = --with-kernel-headers=$(STAGING_DIR)/usr/include

$(eval $(autotools-package))
