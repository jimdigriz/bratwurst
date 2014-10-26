BRatWuRsT (aka 'Buildroot WRT') is a project that creates a [buildroot](http://buildroot.uclibc.org/) based home router firmware, similar in scope to [OpenWRT](https://openwrt.org/), and walks you through the steps required to install it and get it running.

If you want to help, look at the current [roadmap](ROADMAP.md) for suggestions.  There is a list of aims, plans and thoughts on where the project is going.

# Preflight

You will need roughly 5GB of free disk space and to start off [have git installed on your system](http://git-scm.com/book/en/Getting-Started-Installing-Git).  Our first step is to run:

    git clone https://github.com/jimdigriz/bratwurst.git
    cd bratwurst

## Debian 'wheezy' 7

You will need to be plumbed into [Debian Backports](http://backports.debian.org/), which if you have not done already is just a case of running:

    sudo cat <<'EOF' > /etc/apt/sources.list.d/debian-backports.list
    deb http://http.debian.net/debian wheezy-backports main
    #deb-src http://http.debian.net/debian wheezy-backports main
    EOF
    
    sudo apt-get update

Afterwards, you can get everything you need with:

    sudo apt-get install --no-install-recommends \
    	build-essential perl \
    	wget ca-certificates cpio rsync vim-common
    sudo apt-get install --no-install-recommends -t wheezy-backports \
	qemu-system-$(uname -m | sed 's/_64//')

## Fedora 20

To install the dependencies you should just need to run:

    sudo yum install \
    	gcc gcc-c++ binutils make patch flex bison perl-Data-Dumper automake \
    	wget ca-certificates rsync qemu-kvm qemu-system-mips
    sudo yum update vim-minimal
    sudo yum install vim-common

# Development

[Buildroot](http://www.buildroot.org/) is used as it [provides a means for very straight forward development and build cycles](http://elinux.org/images/2/2a/Using-buildroot-real-project.pdf).

Development could be done directly on physical hardware, however:

 1. it takes *forever*
 1. QEMU supports simulating different architectures and platforms
 1. there is magic lurking in [`mac80211_hwsim`](https://www.kernel.org/doc/Documentation/networking/mac80211_hwsim/README) and in the [`hwsim`](http://hostap.epitest.fi/cgit/hostap/tree/tests/hwsim) directory

So instead we use QEMU.

The following will spin up a QEMU instance of BRatWuRsT:

    ARCH=mipsel make bratwurst

**N.B.** do *not* put the `ARCH` at the end, otherwise the variable cascades through the build and breaks it

On the first run, the build will take about 30 minutes (on an i7@3Ghz plus the time taken to download 250MB) whilst subsequent runs should take seconds.  Once built, you should see a typical Linux kernel boot up to then drop you into a login prompt; the username is `root` with no password.  Use `Ctrl-A ?` to get some QEMU usage information, `Ctrl-A x` will exit the emulator and there is of course the [QEMU Monitor Console](http://qemu.weilnetz.de/qemu-doc.html#pcsys_005fmonitor) instructions to help you out too.

The configuration (in the VM) uses a number of network interfaces (over the 'standard' one wired and one wireless) like so:

 * wireless interface `wlan0` provided by `mac80211_hwsim` testing is performed on (as in the real world)
 * `eth0` (`-net user,vlan=0`)

All the interesting bits live in `overlay`, and under `opt/bratwurst` (which appears as `/opt/bratwurst` on the target) you will find the `init` script which you can treat like you would `rc.local` for boottime customisations.

To make amendments to the rootfs before it is converted to a binary blob you will want to look at `board/bratwurst/COMMON/post-build.sh`.  This is run after the overlay directory is copied on top of the base root filesystem and deals with making minor fixups to files in place.

## Configuration Files

When amending some configurations, to put a suitable file into `board` you should use the following methods.

### Buildroot

    make -C buildroot menuconfig
    make -C buildroot savedefconfig

### Busybox

There is no 'savedefconfig' for busybox, so all we can do is copy it in:

    make -C buildroot busybox-menuconfig
    cp buildroot/output/build/busybox-1.22.1/.config board/qemu/mipsel/busybox.config

### Linux

    make -C buildroot linux-menuconfig
    ARCH=mips make -C buildroot/output/build/linux-3.16.1 savedefconfig
    cp buildroot/output/build/linux-3.16.1/defconfig board/qemu/mipsel/linux.config

# Building for Physical Targets

**N.B.** Work-In-Progress

Building for specific physical hardware is available for:

 * [TP-Link TL-W8970](board/tp-link/tl-w8970/README.md)
 * [Linksys WAG54G](board/linksys/wag54g/README.md)
 * [TP-Link TL-MR3020](board/tp-link/tl-mr3020/README.md)

# Extras

## Using a Network Filesystem

To help with development it is handy to have some network filesystem capabilities so you can quickly edit scripts on your side of the fence and use them instantly from inside the VM.  NFS and CIFS though is too big for our target so we use [9P](https://www.kernel.org/doc/Documentation/filesystems/9p.txt) instead which in total weighs in at about 100kB of uncompressed kernel modules.

There are two methods to mounting the 9P export, you of course only need to use one; it is recommended you use the QEMU/virtio method.

### QEMU

To mount a virtio exported filesystem of the `shared` directory type on your router:

    modprobe virtio_pci
    modprobe 9pnet_virtio
    mkdir /tmp/shared
    mount -t 9p -o version=9p2000.L,trans=virtio shared /tmp/shared

**N.B.** this is actually done for you automatically by `overlay/etc/init.d/S30virtual` on boot

### TCP Server

Plumbed in, we use a [fork of py9p](https://github.com/svinota/py9p) (there are other [9p server implementation](http://9p.cat-v.org/implementations) you can use) which should work everywhere that has python available (`{apt-get,yum} install python`), you can run a 9P server by just typing into a spare terminal (`9P_SHARE` defaults to `shared` so you can drop it, or set it to another directory):

    make 9p 9P_SHARE=shared

Then from your router:

    mkdir /tmp/shared
    modprobe virtio_pci	# QEMU only
    modprobe virtio_net # QEMU only
    modprobe 9pnet
    udhcpcd eth0
    mount -t 9p -o version=9p2000.L,trans=tcp,port=5564 10.0.2.2 /tmp/shared
