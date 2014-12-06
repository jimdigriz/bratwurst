################################################################################
#
# TI Sangam ATM Driver
#
################################################################################

AR7_ATM_VERSION = D7.05.01.00-R1
AR7_ATM_SOURCE = sangam_atm-$(AR7_ATM_VERSION).tar.bz2
AR7_ATM_SITE = http://downloads.openwrt.org/sources
AR7_ATM_LICENSE = 

AR7_ATM_DEPENDENCIES = linux

define AR7_ATM_BUILD_CMDS
        $(MAKE) -C $(LINUX_DIR) $(LINUX_MAKE_FLAGS) M=$(@D)
endef

define AR7_ATM_INSTALL_TARGET_CMDS
        $(MAKE) -C $(LINUX_DIR) $(LINUX_MAKE_FLAGS) M=$(@D) modules_install
endef

$(eval $(generic-package))
