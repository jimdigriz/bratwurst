# Layout

BRatWuRsT tries to follow [buildroot's customisation recommendations](http://buildroot.uclibc.org/downloads/manual/manual.html#customize) where possible but with the following deviations:

 * buildroot is a [git submodule](http://git-scm.com/docs/git-submodule) and so our customisations live in its parent directory
 * there are *two* `rootfs-overlay` directories, they are applied in this order:
     - `rootfs-overlay`
     - `board/<company>/<boardname>/rootfs-overlay` (optional)

All the interesting bits live in `rootfs-overlay`, and under `opt/bratwurst` (which appears as `/opt/bratwurst` on the target) you will find the `init` script which you can treat like you would `rc.local` for boot time customisations.

To make amendments to the rootfs before it is converted to a binary blob you will want to look at `board/<company>/<boardname>/post-build.sh`.  This is run after the `rootfs-overlay` directory is copied on top of the base root filesystem and deals with making minor fixups to files in place.

## fakeisp

This sub-project is what makes up emulating everything beyond your router, from the DSLAM (ATM layer) to the ISP (authentication) and beyond onto the Internet (access):

 * based on [Debian's debootstrap](https://wiki.debian.org/Debootstrap)
 * builds a large [initramfs](https://www.kernel.org/doc/Documentation/filesystems/ramfs-rootfs-initramfs.txt) (`fakeisp/initrd.base`)
 * takes advantage that the [initramfs image can be a chain](https://www.kernel.org/doc/Documentation/early-userspace/buffer-format.txt) of overlay images, so `rootfs-overlay` is appended as a second initramfs

In practice `initrd.base` does not change, so you can just use the prepared image I have made available (`dl/fakeisp.initrd.base.<arch>`).  Alternatively you can build your own by typing:

    make fakeisp-diy

**N.B.** this calls `sudo` as `debootstrap` has to be run as root plus you also need to make sure the mountpoint you have checked out on is *not* mounted `nodev`

As before, the interesting bits live in `fakeisp/rootfs-overlay/opt/bratwurst`.

# Networking

For the BRatWuRsT QEMU VM, a number of network interfaces exist:

 * **`eth0`:** link into fakeisp for uplink
     * [IPv6 DAD is disabled](board/qemu/mipsel/rootfs-overlay/opt/bratwurst/rc.d/20_ptp_no_v6_dad) as [QEMU mcast socket](http://lists.nongnu.org/archive/html/qemu-devel/2013-03/msg05497.html) causes it problems
 * **`eth1`:** LAN interface
 * **`wlan0` [not supported]:** provided by `mac80211_hwsim` testing is performed on (as in the real world)

`eth0` is multi-purpose and used to provide emulation of typical cable and xDSL configurations (plumbing into fakeisp):

 * **ethernet (cable modem) [not supported]:** eth0 <- dhcp
 * **xDSL:**
     * **PPPoA:** ATM-over-TCP (`atmtcp`) <- ppp
     * **PPPoE:** ATM-over-TCP (`atmtcp`) <- RFC2684 (`br2684ctl`) <- ppp

## fakeisp

 * **`eth0`:** uplink to the outside world
 * **`eth1`:** link into BRatWuRsT QEMU VM
     * [IPv6 DAD is disabled](fakeisp/rootfs-overlay/etc/sysctl.d/ptp_no_v6_dad.conf)

# Using a Network Filesystem

To help with development it is handy to have some network filesystem capabilities so you can quickly edit scripts on your side of the fence and use them instantly from inside the VM.  NFS and CIFS though is too big for our target so we use [9P](https://www.kernel.org/doc/Documentation/filesystems/9p.txt) instead which in total weighs in at about 100kB worth of kernel modules.

There are two methods available to mount the 9P export, you of course only need to use one.  For QEMU, the virtio transport is automatically setup for you by [90_shared](board/qemu/mipsel/rootfs-overlay/opt/bratwurst/rc.d/90_shared) on boot and mounted at `/tmp/shared` (sharing `shared` at the top level directory).

**N.B.** the variable `9P_SHARE` (default: `shared`) can be used to specify the directory you wish to export

For real hardware, you will have to use a userland TCP based server.  To aid you, plumbed into the project, we use a [fork of py9p](https://github.com/svinota/py9p) (there are other [9p server implementation](http://9p.cat-v.org/implementations) you can use) which should work everywhere that has python available (`{apt-get,yum} install python`), you can run a 9P server by just typing into a spare terminal:

    9P_SHARE=shared make 9p

Then from your router:

    mkdir /tmp/shared
    modprobe 9pnet
    mount -t 9p -o version=9p2000.L,trans=tcp,port=5564 192.0.2.0 /tmp/shared
