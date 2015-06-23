This page applies to version 2 of the Linksys WAG54G, but it should work equally well with the version 3 model which has just twice the amount of RAM and NAND (CFI changes looks to change from AMD to Intel CFI).

# Preflight

It is *strongly* recommended you have a serial console (see below) working.

You will need a TFTP client.

Plug in your workstation over Ethernet, and assign yourself a static IP in the range `192.168.1.{2...254}/24`.

## Debian

    sudo apt-get install --no-install-recommends -yy tftp

# Building

Work through [Configuration](../../../README.md#configuration) and then type the following to build the firmware:

    make ar7/wag54g

# Installing

If you have a serial console, power on the device and press any key to interrupt the ADAM2 boot up.  Once interrupted, type:

    ( cd buildroot/output/images && printf 'mode binary\nconnect 192.168.1.1\nput firmware-code.bin\n' | tftp )

You should see over the serial port the router state that a firmware update is underway and about 90 seconds later the router will reset and boot into BRatWuRsT.

If you do not have a serial port, then you will need to prep to run the `tftp` command, and run it within five seconds of powering on the router, hoping that you catch it before the system starts booting up.

# Information

Here is some helpful information regarding the device.

## Opening the Unit

There is a single screw beneath each of the four removable rubber feet.  Once you remove them, and break the 'security' sticker, you should be able to pop off the front by pulling either the left or right hand side where there are latches; they are firm but you should be able to do all the work with your thumb and forefinger.  Once popped everything should slide apart, but be careful with the cable inside that attaches the wireless card to the aerial.

To detach the board from the chassis, there is a single larger screw in the centre, the board then slides out from some clips with no trouble.

## Serial Cable

The best serial port mod I have seen, and the one I use, is by placing a standard stereo 3.5mm headphone jack onto the front leg of the box.  A top tip is when making the hole, try to put it as high up as you can on the leg otherwise the headphone socket will make contact with the board and cause problems.

![Headphone Jack As a Serial Port](http://duff.dk/wrt54gs/pics/Reuter_complete.jpg "Headphone Jack As a Serial Port")

The process is made easier by that [FTDI](http://ftdichip.com/) make very nice serial cables that work great under Linux, including the [TTL-232R-3V3-AJ](http://www.ftdichip.com/Products/Cables/USBTTLSerial.htm) which means you do not need to mess with a MAX-232 chip or soldering.  For the cabling inside I used some spare [ribbon cable](http://en.wikipedia.org/wiki/Ribbon_cable).

Wiring it up is straight forward by using the [headphone jack pinout of the TTL-232R-3V3-AJ](http://www.ftdichip.com/Images/TTL-232R-AJ%20pinout.jpg) with the pinout of the router included below (shamelessly stolen from the [OpenWRT wiki](http://wiki.openwrt.org/toh/linksys/wag54g#serial).

    |
    |    __
    |   |  |    <- Pin 1, GND
    |    --
    |   |  |    <- Pin 2, Not Connected
    |    --
    |   |  |    <- Pin 3, Router's Serial RX
    |    --
    |   |  |    <- Pin 4, Router's Serial TX
    |    --
    |   |  |    <- Pin 5, VCC [not used for serial port]
    |    --
    |   JP3
    |
     \__LED__LED__LED__LED____________________
                    Front

**N.B.** remember that when wiring you attach the TX pin of one end to the RX pin of the other and of course GND to GND

Once all hooked up, you should use [minicom](http://alioth.debian.org/projects/minicom/) and configure the serial port to run at `38400 8N1` with *no* hardware or software flow control.

## Misbehaving Ethernet Ports

A gotcha typically is a broken capacitor (33uF 16V) that can lead to all [sorts of trouble](http://archive.gavinbenda.com.au/2007/05/27/wag54g-v2-capacitor-replacement/).  I had this issue with all ten of the WAG54Gs I bought off [eBay](http://www.ebay.com/) but did found that with one of them I was able to get a temporary workaround by using a direct connection from my workstation after forcing the link speed to 10Mbps half-duplex with:

    sudo ethtool -s eth0 autoneg off speed 10 duplex half

## Partition Table

The onboard 4MB (64kB erase size) NAND is partition as follows:

 * `mtd0` (`0x900e0000-0x903f0000`, size: 3136kB): rootfs
 * `mtd1` (`0x90020000-0x900e0000`, size: 768kB): kernel
 * `mtd2` (`0x90000000-0x90020000`, size: 128kB): adam2 bootloader
 * `mtd3` (`0x903f0000-0x90400000`, size: 64kB): adam2 configuration
 * `mtd4` (`0x90020000-0x903f0000`, size: 3904kB): kernel and rootfs which is where `firmware-code.bin` is flashed to

Under Linux the `ar7part.c` driver is [meant to spit out a suitable partition table](http://marc.info/?l=linux-mips&m=126268121228322&w=3) for both bootloaders (PSPBoot and ADAM2) that are available on the AR7 platform.  However, I found it does not and should not be used as for me the 'rootfs' partition overlaps the 'linux' partition.  Instead I recommend using `cmdlinepart`.

## GPIOs

To expose the pins, you just use the GPIO sysfs interface like so:

    for I in $(seq 0 31); do echo $I > /sys/class/gpio/export; done

Then in `/sys/class/gpio` you should find a number of directories have appeared called `gpioX` (where `X` is between 0 and 31).

You can browse the pin direction and values with:

    for I in $(seq 0 31); do echo -n "${I}: "; cat /sys/class/gpio/gpio${I}/direction; done
    for I in $(seq 0 31); do echo -n "${I}: "; cat /sys/class/gpio/gpio${I}/value; done

So far the map I have been able to piece together is (all pins have `active_low` set to zero):

 * pin 00, default 1, dir in: fixed on
 * pin 01, default 1, dir in: fixed on
 * pin 02, default 1, dir in: fixed on
 * pin 03, default 0, dir in: fixed off
 * pin 04, default 0, dir in: status LED {0}
 * pin 05, default 1, dir in: status LED {1}
 * pin 06, default 1, dir in: WLAN LED
 * pin 07, default 0, dir in: ?
 * pin 08, default 1, dir in: status LED {2}
 * pin 09, default 0, dir in: ?
 * pin 10, default 1, dir in: reset Ethernet - CAUTION, it is a latch (0 - reset, 1 - start however lights lock on)
 * pin 11, default 1, dir in: reset key (0 - off, 1 = pressed)
 * pin 12, default 1, dir in: ?
 * pin 13, default 1, dir in: ?
 * pin 14, default 0, dir in: ?
 * pin 15, default 1, dir in: fixed on
 * pin 16, default 1, dir in: fixed on
 * pin 17, default 1, dir in: fixed on
 * pin 18, default 1, dir out: fixed on
 * pin 19, default 1, dir out: fixed on
 * pin 20, default 0, dir in: hw ver(?) {0}
 * pin 21, default 0, dir in: hw ver(?) {1}
 * pin 22, default 0, dir in: hw ver(?) {2}
 * pin 23, default 1, dir in: hw ver(?) {3}
 * pin 24, default 0, dir in: hw ver(?) {4}
 * pin 25, default 0, dir in: hw ver(?) {5}
 * pin 26, default varies, dir in: ?
 * pin 27, default varies, dir in: ?
 * pin 28, default 0, dir in: ?
 * pin 29, default 0, dir in: ?
 * pin 30, default 0, dir in: ?
 * pin 31, default 0, dir in: ?

Some of the [locations of those pins on the board](https://forum.openwrt.org/viewtopic.php?id=20171) can be found at JP4:

    /--- connector labeled JP4 --/
      [NC  ][NC  ]
      [0x15][0x18]
      [3,3V][GND ]
      [0x16][0x19]
      [0x17][0x14]
    \=============================

### Status LEDs

The status pin map looks like (for pin settings 4, 5 and 8 respectively):

 * {0,0,0}: solid red
 * {0,0,1}: off
 * {0,1,0}: blink red
 * {0,1,1}: blink green
 * {1,0,0}: solid red
 * {1,0,1}: off
 * {1,1,0}: off
 * {1,1,1}: solid green

## JTAG

Fortunately there is a full sized standard [EJTAG 14 pin header](http://wiki.openwrt.org/doc/hardware/port.jtag#pin.header2) lurking at JP1, only problem is that it is headless so you have to solder it on.

Once soldered though, you can hookup your JTAG tools of choice (I have the [Flyswatter 2](http://www.tincantools.com/JTAG/Flyswatter2.html) with the [ARM20 to MIPS14 converter](http://www.tincantools.com/JTAG/ARM20MIPS14.html)) and fire up [openocd](http://openocd.sourceforge.net/):

    cat <<'EOF' > linksys-wag54gv2.cfg
    #
    # Linksys WAG54Gv2 Router (cloned from board/netgear-dg834v3.cfg)
    # Internal 4Kb RAM (@0x80000000)
    # Flash is located at 0x90000000 (CS0) and RAM is located at 0x94000000 (CS1)
    #
    
    source [find target/ti-ar7.cfg]
    
    adapter_khz 100
    
    # External 16MB SDRAM - disabled as we use internal sram
    #$_TARGETNAME configure -work-area-phys 0x80000000 -work-area-size 0x00001000
    
    # External 4MB NOR Flash
    set _FLASHNAME $_CHIPNAME.norflash
    flash bank $_FLASHNAME cfi 0x90000000 0x00400000 2 2 $_TARGETNAME
    EOF

    # openocd -f /usr/share/openocd/scripts/interface/ftdi/flyswatter2.cfg -f linksys-wag54gv2.cfg
    
    Open On-Chip Debugger 0.7.0 (2013-08-31-18:07)
    Licensed under GNU GPL v2
    For bug reports, read
            http://openocd.sourceforge.net/doc/doxygen/bugs.html
    Info : only one transport option; autoselect 'jtag'
    adapter speed: 100 kHz
    Info : clock speed 100 kHz
    Info : JTAG tap: ti-ar7.cpu tap/device found: 0x0000100f (mfg: 0x007, part: 0x0001, ver: 0x0)

    $ telnet localhost 4444
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
    Open On-Chip Debugger
    >

### Resurrecting a Brick

You will require the ADAM2 0.22.12 bootloader blob ([adam2-0.22.12.bin.xz](board/ar7/wag54g/adam2-0.22.12.bin.xz), uncompress it and then from the `openocd` console (via telnet) type:

    > flash list
    {name cfi base 2415919104 size 4194304 bus_width 2 chip_width 2}
    
    > flash banks
    #0 : ti-ar7.norflash (cfi) at 0x90000000, size 0x00400000, buswidth 2, chipwidth 2
    
    > halt
    target state: halted
    target halted in MIPS32 mode due to debug-request, pc: 0xb0000380
    
    > flash erase_sector 0 0 1
    erased sectors 0 through 1 on flash bank 0 in 1.369242s
    
    > flash write_bank 0 adam2-0.22.12.bin 0
    target halted in MIPS32 mode due to target-not-halted, pc: 0x80000088
    target state: halted
    [snipped lots of repeats of the previous two lines]
    wrote 131072 bytes from file adam2-0.22.12.bin to flash bank 0 at offset 0x00000000 in 52.439411s (2.441 KiB/s)
    
    > resume 0x90000000

You should now find your router boots.

## Kernel Cooking Notes

A list of issues and hints I have found with the kernel:

 * `CONFIG_CPMAC` requires `CONFIG_FIXED_PHY=y` (*not* module!) to function
 * if you use anything other than `CONFIG_HZ_100`, the timing delay loops go crazy; Florian thinks it is a bug in 4KEc stuff
 * `CONFIG_CPMAC` conflicts with anything other than `CONFIG_PREEMPT_NONE` if `CONFIG_NO_HZ` is set, reseting the box with no visible oops to trace the problem from when it initialises; only occurs if you have no `PHY`

# Related Links

 * [OpenWrt Linksys WAG54G](http://wiki.openwrt.org/toh/linksys/wag54g)
 * [Linux MIPS AR7 Information](http://www.linux-mips.org/wiki/AR7)
 * [Original Linksys Sourcecode](http://download.modem-help.co.uk/mfcs-L/LinkSys/WAG54G/GPL/v2/)
 * [cpmaccfg](http://www.heimpold.de/freetz/index.html)
 * [Wireless on the unit is a TI ACX](http://acx100.sourceforge.net/)
  * `git clone git://acx100.git.sourceforge.net/gitroot/acx100/acx-mac80211`
 * [fix for `eth0: rx dma ring overrun`](https://forum.openwrt.org/viewtopic.php?id=22454) - if you compile out `ethtool` support you have to [patch the kernel instead](patches/linux/0900-linux-cpmac-ringsize.patch)
 * [Ben Whitten's attempt to clean up the AR7-ATM driver](https://github.com/BWhitten/ar7-atm)
