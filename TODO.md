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
 * improve the automatic ULA prefix choice, currently you effectively end up with the uptime (~9 seconds)
  * maybe use: cat /sys/class/net/$IFACE/address | cut -d: -f3-

## Roadmap

 * dnsmasq with public authoritive DNS server
 * supporting straight Ethernet with DHCP (a la cable)
 * improve firewalling
  * better use of the nftables run-parts, flush to only cleans its own sections
  * make use of the inet nftable (icmpx, etc) now we are using a 3.18 kernel
 * wireless
 * QoS
 * in place firmware upgrade
  * ...without losing config and customisations?
  * "OTA"?
 * development instructions to be expanded to work under Mac OS X
 * fakeisp really could do with IPv6 on the uplink, we could accomplish this with:
  * extending the QEMU user mode networking to support IPv6
  * much simpler is to probably use an IPv6-over-UDP4 tunnelling technology such as Teredo
 * port the ar7_wdt driver to watchdog_core
 * take another stab at getting [Link-Time-Optimisations (LTO) working on the kernel](https://github.com/andikleen/linux-misc/tree/lto-3.16)
  * [MIPS: Make declarations and definitions of tlbmiss_handler_setup_pgd match](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=0bfbf6a256348b1543e638c7d7b2f3004b289fdb) partly fixes the problem but unfortunately [MIPS: Move generated code to .text for microMIPS](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=6ba045f9fbdafb48da42aa8576ea7a3980443136) reverted it (seemingly accidently)

# Links

 * Keeping Linux small:
  * [Spreading the disease: Linux on microcontrollers](http://elinux.org/images/c/ca/Spreading.pdf)
  * [microYocto and the Internet of Tiny](http://elinux.org/images/5/54/Tom.zanussi-elc2014.pdf)
  * [Networking on tiny machines](http://lwn.net/Articles/597529/) with related [git tree](https://git.kernel.org/cgit/linux/kernel/git/ak/linux-misc.git/?h=net/debloat)
  * [Linux Kernel Tinification](https://tiny.wiki.kernel.org/) - [LWN: Kernel tinification](http://lwn.net/Articles/608945/)
