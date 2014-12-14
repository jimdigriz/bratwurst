################################################################################
#
# nftables
#
################################################################################

EXTERNAL_NFTABLES_VERSION = a698868d52a550bab4867c0dc502037155baa11d
EXTERNAL_NFTABLES_SITE = git://git.netfilter.org/nftables
EXTERNAL_NFTABLES_DEPENDENCIES = gmp external-libmnl external-libnftnl host-bison host-flex \
	host-pkgconf $(if $(BR2_NEEDS_GETTEXT),gettext)
EXTERNAL_NFTABLES_AUTORECONF = YES
EXTERNAL_NFTABLES_LICENSE = GPLv2
EXTERNAL_NFTABLES_LICENSE_FILES = COPYING

ifeq ($(BR2_PACKAGE_EXTERNAL_NFTABLES_INTERACTIVE),y)
EXTERNAL_NFTABLES_DEPENDENCIES += readline
EXTERNAL_NFTABLES_LIBS += -lncurses
else
EXTERNAL_NFTABLES_CONF_OPTS = --without-cli
endif

ifeq ($(BR2_PREFER_STATIC_LIB)$(BR2_PACKAGE_LIBNFTNL_JSON),yy)
EXTERNAL_NFTABLES_LIBS += -ljansson -lm
endif
ifeq ($(BR2_PREFER_STATIC_LIB)$(BR2_PACKAGE_LIBNFTNL_XML),yy)
EXTERNAL_NFTABLES_LIBS += -lmxml -lpthread
endif

EXTERNAL_NFTABLES_CONF_ENV = \
	ac_cv_prog_CONFIG_PDF=no \
	LIBS="$(EXTERNAL_NFTABLES_LIBS)"

$(eval $(autotools-package))
