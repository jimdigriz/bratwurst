################################################################################
#
# odhcp6c
#
################################################################################

ODHCP6C_VERSION = 722226c4f1d45c8bf4ac9189523738abcf7d648f
ODHCP6C_SITE = $(call github,sbyx,odhcp6c,$(ODHCP6C_VERSION))
ODHCP6C_LICENSE = GPLv2
ODHCP6C_LICENSE_FILES = COPYING

$(eval $(cmake-package))
