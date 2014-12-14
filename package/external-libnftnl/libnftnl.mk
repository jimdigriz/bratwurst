################################################################################
#
# external-libnftnl
#
################################################################################

EXTERNAL_LIBNFTNL_VERSION = 71b6057121aded54912b0fced256833c08db20df
EXTERNAL_LIBNFTNL_SITE = git://git.netfilter.org/libnftnl
EXTERNAL_LIBNFTNL_LICENSE = GPLv2+
EXTERNAL_LIBNFTNL_LICENSE_FILES = COPYING
EXTERNAL_LIBNFTNL_AUTORECONF = YES
EXTERNAL_LIBNFTNL_INSTALL_STAGING = YES
EXTERNAL_LIBNFTNL_DEPENDENCIES = host-pkgconf external-libmnl

ifeq ($(BR2_PACKAGE_EXTERNAL_LIBNFTNL_JSON),y)
EXTERNAL_LIBNFTNL_CONF_OPTS += --with-json-parsing
EXTERNAL_LIBNFTNL_DEPENDENCIES += jansson
else
EXTERNAL_LIBNFTNL_CONF_OPTS += --without-json-parsing
endif

ifeq ($(BR2_PACKAGE_EXTERNAL_LIBNFTNL_XML),y)
EXTERNAL_LIBNFTNL_CONF_OPTS += --with-xml-parsing
EXTERNAL_LIBNFTNL_DEPENDENCIES += mxml
else
EXTERNAL_LIBNFTNL_CONF_OPTS += --without-xml-parsing
endif

$(eval $(autotools-package))
