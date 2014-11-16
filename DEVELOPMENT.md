# Networking

For the BRatWuRsT QEMU VM, a number of network interfaces exist:

 * **`eth0`:** link into fakeisp (used to build uplink)
 * **`eth1`:** LAN interface
 * **`wlan0`:** provided by `mac80211_hwsim` testing is performed on (as in the real world)

`eth0` is multi-purpose and used to provide emulation of typical cable and xDSL configurations (plumbing into fakeisp):

 * **cable:** GRE tunnel <- dhcp
 * **xDSL:**
     * **PPPoA:** ATM-over-TCP (`atmtcp`) <- ppp
     * **PPPoE:** ATM-over-TCP (`atmtcp`) <- RFC2684 (`br2684ctl`) <- ppp

All the interesting bits live in `overlay`, and under `opt/bratwurst` (which appears as `/opt/bratwurst` on the target) you will find the `init` script which you can treat like you would `rc.local` for boot time customisations.

To make amendments to the rootfs before it is converted to a binary blob you will want to look at `board/bratwurst/COMMON/post-build.sh`.  This is run after the overlay directory is copied on top of the base root filesystem and deals with making minor fixups to files in place.
