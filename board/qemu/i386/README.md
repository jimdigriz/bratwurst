This is here just notes for the curious, explaining why `qemu/i386` was abandoned.

So, the interesting quirks with using pflash under i386:

 1. it is a mechanism to actually swap out what you and I think more of as the BIOS
 1. for the first (`index=0`) pflash device, the last 128kB is used as the BIOS to boot so you need to amend the partition table to look like:

        64k(config),1024k(kernel),2880k(rootfs),128k(boot)

 1. alternatively [we can skip setting the first bank (the 'index=0' line is optional here) and only set the second one (`index=1`)](http://lists.gnu.org/archive/html/qemu-devel/2013-11/msg02763.html); qemu will use `bios.bin` as usual in its place, letting us use any `mtdparts` scheme we wish

        -drive file=/usr/share/seabios/bios.bin,readonly,if=pflash,index=0 \
        -drive file=buildroot/output/images/pflash,snapshot=on,if=pflash,index=1

 1. the flash banks are mapped at the top of the 4Gb in memory (`qemu:hw/i386/pc_sysfw.c:pc_system_flash_init()`) in reverse order

        (qemu) info mtree
        
          00000000ffbe0000-00000000fffdffff (prio 0, R-): system.flash1
          00000000fffe0000-00000000ffffffff (prio 0, R-): system.flash0

 1. the kernel needs to be configured with

        CONFIG_MTD_PHYSMAP_COMPAT=y
        CONFIG_MTD_PHYSMAP_START=0xffbe0000
        CONFIG_MTD_PHYSMAP_LEN=0x400000
        CONFIG_MTD_PHYSMAP_BANKWIDTH=4

 1. they are set to read-only and marked reserved in the e820 map

        [    0.000000] BIOS-e820: [mem 0x00000000feffc000-0x00000000feffffff] reserved
        [    0.000000] BIOS-e820: [mem 0x00000000fffc0000-0x00000000ffffffff] reserved
        [     snipped]
        [    0.088521] platform physmap-flash.0: failed to claim resource 0

Everything is workable, except for the read-only/reserved point as:

 * we are using JFFS2 so need to be able to write to the region
 * physmap-flash is unable to map the region for use

Because of this, I am abandoning `qemu/i386`, maybe someone can figure out how we can get this working one day in a fashion aligned with the rest of the project.
