################################################################################
#
# libnftnl
#
################################################################################

EXTERNAL_LIBNFTNL_VERSION = 1.0.3
EXTERNAL_LIBNFTNL_SITE = http://netfilter.org/projects/libnftnl/files
EXTERNAL_LIBNFTNL_SOURCE = libnftnl-$(EXTERNAL_LIBNFTNL_VERSION).tar.bz2
EXTERNAL_LIBNFTNL_LICENSE = GPLv2+
EXTERNAL_LIBNFTNL_LICENSE_FILES = COPYING
EXTERNAL_LIBNFTNL_INSTALL_STAGING = YES
EXTERNAL_LIBNFTNL_DEPENDENCIES = host-pkgconf libmnl

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
