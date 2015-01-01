################################################################################
#
# nftables
#
################################################################################

EXTERNAL_NFTABLES_VERSION = 0.4
EXTERNAL_NFTABLES_SOURCE = nftables-$(EXTERNAL_NFTABLES_VERSION).tar.bz2
EXTERNAL_NFTABLES_SITE = http://www.netfilter.org/projects/nftables/files
EXTERNAL_NFTABLES_DEPENDENCIES = gmp libmnl external-libnftnl host-bison host-flex \
	host-pkgconf $(if $(BR2_NEEDS_GETTEXT),gettext)
EXTERNAL_NFTABLES_LICENSE = GPLv2
EXTERNAL_NFTABLES_LICENSE_FILES = COPYING

ifeq ($(BR2_PACKAGE_EXTERNAL_NFTABLES_INTERACTIVE),y)
EXTERNAL_NFTABLES_DEPENDENCIES += readline
EXTERNAL_NFTABLES_LIBS += -lncurses
else
EXTERNAL_NFTABLES_CONF_OPTS = --without-cli
endif

ifeq ($(BR2_STATIC_LIBS)$(BR2_PACKAGE_LIBNFTNL_JSON),yy)
EXTERNAL_NFTABLES_LIBS += -ljansson -lm
endif
ifeq ($(BR2_STATIC_LIBS)$(BR2_PACKAGE_LIBNFTNL_XML),yy)
EXTERNAL_NFTABLES_LIBS += -lmxml -lpthread
endif

EXTERNAL_NFTABLES_CONF_ENV = \
	ac_cv_prog_CONFIG_PDF=no \
	LIBS="$(EXTERNAL_NFTABLES_LIBS)"

$(eval $(autotools-package))
