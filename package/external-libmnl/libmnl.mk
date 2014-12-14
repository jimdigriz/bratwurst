################################################################################
#
# external-libmnl
#
################################################################################

EXTERNAL_LIBMNL_VERSION = 72aec11703c7fda93af77cb6356f9692f18f9e9b
EXTERNAL_LIBMNL_SITE = git://git.netfilter.org/libmnl
EXTERNAL_LIBMNL_INSTALL_STAGING = YES
EXTERNAL_LIBMNL_AUTORECONF = YES
EXTERNAL_LIBMNL_LICENSE = LGPLv2.1+
EXTERNAL_LIBMNL_LICENSE_FILES = COPYING

$(eval $(autotools-package))
