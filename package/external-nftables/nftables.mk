################################################################################
#
# nftables
#
################################################################################

NFTABLES_EXTERNAL_VERSION = 0.3
NFTABLES_EXTERNAL_SOURCE = nftables-$(NFTABLES_EXTERNAL_VERSION).tar.bz2
NFTABLES_EXTERNAL_SITE = http://www.netfilter.org/projects/nftables/files
NFTABLES_EXTERNAL_DEPENDENCIES = gmp libmnl libnftnl host-bison host-flex \
	host-pkgconf $(if $(BR2_NEEDS_GETTEXT),gettext)
NFTABLES_EXTERNAL_AUTORECONF = YES
NFTABLES_EXTERNAL_LICENSE = GPLv2
NFTABLES_EXTERNAL_LICENSE_FILES = COPYING

NFTABLES_EXTERNAL_CONF_ENV = ac_cv_prog_CONFIG_PDF=no

ifeq ($(BR2_PACKAGE_EXTERNAL_NFTABLES_EXTERNAL_INTERACTIVE),y)
NFTABLES_EXTERNAL_DEPENDENCIES += readline
NFTABLES_EXTERNAL_CONF_ENV += LIBS="-lncurses"
else
NFTABLES_EXTERNAL_CONF_OPT = --disable-cli
endif

$(eval $(autotools-package))
