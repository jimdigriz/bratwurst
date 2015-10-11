Here is a list of outstanding tasks and thoughts on the direction the project is taking so everyone can get an idea of how they can chip in or what they should flag up as being overlooked.

# Aims

 * development cycle must always be straight forward and fast
  * straight forward means the documentation matches what needs to be done, also short and concise!  No need for a rambling description of why, or the design.  People use `grep` to find code entry points, but they need to know how to setup their development environment and how to test their changes
  * the size of the code change should be proportional to the time it takes to develop and test it.  A five liner change should *not* involve taking three days to prep an environment and then to spend a further week trying to figure out how to test that change.  Testing cycles should aim to be no more than *ten* minutes
 * development environment is regularly *destroyed* and started from scratch.  This exercises the documentation and helps to make sure that the build process (~30 minutes) and test cycle (minutes) do not creep up.  If it starts to become an inconvenience, it is a problem
 * as few differences as possible between the QEMU version of BRatWuRsT and what is actually run on the physical hardware.  Almost 100% development and testing should be possible on the QEMU version and the only differences really should be in the linux defconfig file for the physical hardware (which of course should be transparent to userspace)
 * root filesystem *must* always fit in a (JFFS2) image no bigger than 3MB and the (xz) kernel to be no bigger than 1MB

# Plans

## Required

 * documentation describing
  * how to use it (should be more obvious once we have real hardware)
  * IP ranges used
  * how to strap in another VM as a client on the LAN
 * fix dnsmasq to exclude non-global addresses, [my patch was bad](http://lists.thekelleys.org.uk/pipermail/dnsmasq-discuss/2015q1/009122.html) :)
  * reverse zone file for fc00::/7 and 2002:: too
 * move RAM/MTDPARTS/etc into board and have post-image.sh use these variables rather than duping them

## Roadmap

 * look at the [Homenet WG](http://tools.ietf.org/wg/homenet/) docs, especially [RFC7368](http://tools.ietf.org/html/rfc7368)
 * fix `atmtcp` connection where we see the following errors `invalid QOS "ubr,aal5:..."`; seems to have non-printable characters in there
 * disabling sysfs causes an unaligned access in the `ipv6_addrconf` kernel workqueue during PPP just before sending `IPV6CP ConfReq`
 * AR7 related:
  * when making `8250` a module, the serial console is not properly detected or configured
  * get interupt pacing working on the `tiatm` driver, [the AWOL `avalanche_request_pacing()` seems to be in the original 2.4 codebase](http://www.mit.edu/afs.new/sipb/project/merakidev/src/openwrt-meraki/openwrt/target/linux/ar7-2.4/patches/000-ar7_support.patch)
  * we have GPIOs to control the LEDs, we should probably use them
  * port the `ar7_wdt` driver to `watchdog_core`
  * `/sbin/modprobe tiatm trellis=1 bitswap=1` - maybe better options
 * create an SSHFP record for the router using [dnsmasq's dns-rr](http://lists.thekelleys.org.uk/pipermail/dnsmasq-discuss/2012q2/005941.html) feature
 * supporting straight Ethernet with DHCP (a la cable)
 * improve firewalling
  * better use of the nftables run-parts, flush to only cleans its own sections
  * make use of the inet nftable (icmpx, etc) now we are using a 3.18+ kernel
 * wireless
  * `mac80211_hwsim` between two QEMU VM's...?
 * QoS
 * in place firmware upgrade
  * ...without losing config and customisations?
  * [OverlayFS](https://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/Documentation/filesystems/overlayfs.txt) is now an option to combine SquashFS with JFFS2
  * "OTA"?
 * development instructions to be expanded to work under Mac OS X
 * fakeisp really could do with IPv6 on the uplink, we could accomplish this with:
  * extending the QEMU user mode networking to support IPv6
  * much simpler is to probably use an IPv6-over-UDP4 tunnelling technology such as Teredo
 * take another stab at getting [Link-Time-Optimisations (LTO) working on the kernel](https://github.com/andikleen/linux-misc/tree/lto-4.0)
  * [MIPS: Make declarations and definitions of tlbmiss_handler_setup_pgd match](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=0bfbf6a256348b1543e638c7d7b2f3004b289fdb) partly fixes the problem but unfortunately [MIPS: Move generated code to .text for microMIPS](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=6ba045f9fbdafb48da42aa8576ea7a3980443136) reverted it (seemingly accidently)

# Links

 * Keeping Linux small:
  * [Spreading the disease: Linux on microcontrollers](http://elinux.org/images/c/ca/Spreading.pdf)
  * [microYocto and the Internet of Tiny](http://elinux.org/images/5/54/Tom.zanussi-elc2014.pdf)
  * [Networking on tiny machines](http://lwn.net/Articles/597529/) with related [git tree](https://git.kernel.org/cgit/linux/kernel/git/ak/linux-misc.git/?h=net/debloat)
  * [Linux Kernel Tinification](https://tiny.wiki.kernel.org/) - [LWN: Kernel tinification](http://lwn.net/Articles/608945/)
