# Layout

The project structure tries to follow [buildroot's project-specific customisation](http://buildroot.uclibc.org/downloads/manual/manual.html#_project_specific_customization) recommendations where possible but with the following deviations:

 * buildroot is a [git submodule](http://git-scm.com/docs/git-submodule) and so our customisation's live in its parent directory
 * the root (skeleton) filesystem is `rootfs` - this is where all the interesting bits live
 * there is a single root filesystem overlay directory at `board/<soc>/<boardname>/rootfs-overlay`

To make amendments to the rootfs before it is converted to a binary blob you will want to look at `board/<soc>/<boardname>/post-build.sh`.  This is run after the `rootfs-overlay` directory is copied on top of the base root filesystem and deals with making minor fixups to files in place.

## fakeisp

This sub-project is what makes up emulating everything beyond your router, from the [DSLAM (ATM layer)](https://www.farside.org.uk/200903/ipoeoatm) to the ISP (authentication) and beyond onto the Internet (access):

 * based on [Debian's debootstrap](https://wiki.debian.org/Debootstrap)
 * builds a large [initramfs](https://www.kernel.org/doc/Documentation/filesystems/ramfs-rootfs-initramfs.txt) (`fakeisp/initrd`)
 * takes advantage that the [initramfs image can be a chain](https://www.kernel.org/doc/Documentation/early-userspace/buffer-format.txt) of overlay images, so `rootfs-overlay` is appended as a second initramfs

To build and run it, all you need to do is type:

    make fakeisp

Part of this process utilises a pre-built base Debian root filesystem (`fakeisp/initrd.base`), a component which rarely changes, to simplify the build.  However, if you prefer to build your own locally you can run the following on a Debian 'wheezy' 7 workstation:

    make fakeisp-diy
    make fakeisp

**N.B.** calling `make fakeisp-diy` calls `sudo` as `debootstrap` has needs to run as root.  Also the mount point you have BRatWuRsT checked out on [must *not* be mounted `nodev`](http://en.wikipedia.org/wiki/Fstab#Options_common_to_all_filesystems).

All the interesting parts to this sub-project live in `fakeisp/rootfs-overlay/opt/bratwurst`.

# Contributing

Patches are welcome, and I can take GitHub pull requests, or personal emails.

In lieu of anyone having contributed to this project as of yet, the only hurdle I'll throw back at you is that I ask you to review the output of the `git diff` for your changes and that you put in a good effort to make the patch as small as possible.

If you are looking to chip in on nothing in particular, then do look at the [TODO](TODO.md) list.

For those feeling daring, I would rather your effort is put into digging through [OpenWrt](https://openwrt.org/) and to get their [Linux patches upstreamed](http://git.openwrt.org/?p=openwrt.git;a=tree;f=target/linux).

# Networking

For the BRatWuRsT QEMU VM, a number of network interfaces exist with the following IP addresses assigned:

 * **`lo`:**
  * **IPv6:** `$ULA:08::/64` - [ULA](http://en.wikipedia.org/wiki/Unique_local_address) (for example `fd12:3456:7890:08::/64`)
  * **IPv6:** `2002:[public-IPv4-address]:08::/64` - when connected a [6to4](http://en.wikipedia.org/wiki/6to4) assignment
  * **IPv6:** `[DHCPv6-PD]:08::/64` - when connected and a prefix has been allocated
 * **`eth0`:** link into fakeisp for uplink
  * **IPv4:**
   * `192.0.2.0/24` - DHCP 'cable' network [not supported]
   * `172.20.0.1` to `172.20.0.0` - point-to-point ATMTCP connection (RFC1918 choosen so ignored by dnsmasq)
 * **`eth1`:** LAN interface
 * **`wlan0` [not supported]:** provided by `mac80211_hwsim` testing is performed on (as in the real world)
 * **`br0`:** Ethernet bridge made up of `eth1` and `wlan0`
  * **IPv6:** `$ULA:10::/64`
  * **IPv6:** `2002:[public-IPv4-address]:10::/64` - when connected
  * **IPv6:** `[DHCPv6-PD]:10::/64` - when connected and a prefix has been allocated
  * **IPv4:** `192.168.1.1/24` (`192.168.1.{64...254}` used for client DHCP leases)

**N.B.** it is [normal to have multiple IPv6 addresses on hosts](https://tools.ietf.org/html/rfc6724) and in a normal BRatWuRsT LAN you may find your hosts have as many as 10 IPv6 address if not more.  This actually makes routing easier as most [modern operating system](https://www.nanog.org/sites/default/files/monday_general_deccio_quantifyingIPv6_62.6.pdf#page=15) pick the [right address to use automatically](http://biplane.com.au/blog/?p=22); some older systems may need to you experiment with [/etc/gai.conf](http://linux.die.net/man/5/gai.conf)/[ip6addrctl](https://www.freebsd.org/cgi/man.cgi?query=ip6addrctl&sektion=8).

`eth0` is multi-purpose interface that is used to provide emulation of real world typical xDSL configurations.

 * **Ethernet (cable modem) [not supported] (`192.0.2.0/24`):** eth0 <- dhcp
 * **xDSL:**
     * **PPPoE (`203.0.113.0/24`):** ATM-over-TCP (`atmtcp`) <- RFC2684 (`br2684ctl`) <- ppp
     * **PPPoA (`198.51.100.0/24`):** ATM-over-TCP (`atmtcp`) <- ppp

BRatWuRsT communicates with fakeisp using a multicast UDP socket bounded to the loopback interface, the reason is so you do not have to pay attention to the order that you start both VMs.  The disadvantage though is that [QEMU mcast socket's](http://lists.nongnu.org/archive/html/qemu-devel/2013-03/msg05497.html) cause [problems for IPv6 DAD](http://lists.nongnu.org/archive/html/qemu-devel/2013-03/msg05497.html).  Fortunately we can work around this by disabling DAD over this link on both [BRatWuRsT](board/qemu/mipsel/rootfs-overlay/etc/rc.d/85_ptp_no_v6_dad) and [fakeisp](fakeisp/rootfs-overlay/etc/sysctl.d/ptp_no_v6_dad.conf).

## fakeisp

 * **`lo`:**
 * **`eth0`:** uplink to the outside world
  * **IPv4:** DHCP to QEMU user mode networking stack
 * **`eth1`:** link into BRatWuRsT QEMU VM
  * **IPv4:**
   * `192.0.2.1/24` - DHCP 'cable' network [not supported]
   * `172.20.0.0` to `172.20.0.1` - point-to-point ATMTCP connection

For `eth0` we use user mode network stack for the convenience of not having to run anything as root but it comes with the disadvantage that IPv6 is not supported routing to the outside world.  Fortunately this does not affect IPv6 support between fakeisp and BRatWuRsT though.

# Using a Network Filesystem

When developing, it is often helpful to have a shared (typically network) filesystem to hand so you can quickly edit scripts on your side of the fence and use them instantly from inside the VM.  Unfortunately, NFS and CIFS are too big for our target platforms but [9P](https://www.kernel.org/doc/Documentation/filesystems/9p.txt) is not, weighing in at about 100kB worth of kernel modules.

There are two methods available to mount the 9P export.

## QEMU (virtio)

The virtio transport is automatically setup for you by [25_shared](board/qemu/mipsel/rootfs-overlay/etc/rc.d/25_shared) on boot and mounted at `/tmp/shared`, sharing `shared` located at the top level directory of the BRatWuRsT project tree.

**N.B.** the variable `9P_SHARE` (default: `shared`) can be used to specify the directory you wish to export

## Real Hardware (TCP)

Plumbed into the project, we use a [fork of py9p](https://github.com/svinota/py9p) (there are other [9p server implementation](http://9p.cat-v.org/implementations) you can use) which should work everywhere that has python available (`{apt-get,yum} install python`), you can run a 9P server by just typing into a spare terminal:

    make 9p 9P_SHARE=shared

Then from your router (replacing `w.x.y.z` with the IP address of your workstation):

    mkdir /tmp/shared
    modprobe 9pnet
    mount -t 9p -o version=9p2000.L,trans=tcp,port=5564 w.x.y.z /tmp/shared

# Customising the Build

When amending some configurations, to commit your changes you should use the following methods.

    make {buildroot,uclibc,busybox,linux}-menuconfig BOARD=soc/board

Where `soc/board` is substituted for your target, for example `ar7/wag54g`.

To save your changes afterwards, run:

    make {buildroot,uclibc,busybox,linux}-update-defconfig BOARD=soc/board
