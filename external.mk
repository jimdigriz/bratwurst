include $(sort $(wildcard $(BR2_EXTERNAL)/package/*/*.mk))

DROPBEAR_CONF_ENV = \
	CFLAGS="$(TARGET_CFLAGS) -fno-lto -fno-whole-program"
	LDFLAGS="$(TARGET_LDFLAGS) -fno-lto -fno-use-linker-plugin"

GETTEXT_CONF_ENV = \
	CFLAGS="$(TARGET_CFLAGS) -fno-lto -fno-whole-program"
	LDFLAGS="$(TARGET_LDFLAGS) -fno-lto -fno-use-linker-plugin"

FLEX_CONF_ENV = ac_cv_path_M4=/usr/bin/m4 \
	CFLAGS="$(TARGET_CFLAGS) -fno-lto -fno-whole-program"
	LDFLAGS="$(TARGET_LDFLAGS) -fno-lto -fno-use-linker-plugin"
