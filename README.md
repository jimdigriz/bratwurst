BRatWuRsT (aka 'Buildroot WRT') is a project that creates a [buildroot](http://buildroot.uclibc.org/) based home router firmware, similar in scope to [OpenWRT](https://openwrt.org/), and walks you through the steps required to install it and get it running.

Included in this project is:

 * **[TODO](TODO.md):** a list of outstanding items, as well as aims and thoughts on where the project is going
 * **[Development](DEVELOPMENT.md):** how to work on the project
 * **[Contributing](CONTRIBUTING.md):** how to contribute to the project

# Preflight

You will need roughly 5GB of free disk space and to start off [have git installed on your system](http://git-scm.com/book/en/Getting-Started-Installing-Git).  Our first step is to run:

    git clone https://github.com/jimdigriz/bratwurst.git
    cd bratwurst

To get some help to kick start you off on the build:

    make help

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

# Building

[Buildroot](http://www.buildroot.org/) is used as it [provides a means for very straight forward development and build cycles](http://elinux.org/images/2/2a/Using-buildroot-real-project.pdf).

Development could be done directly on physical hardware, however:

 1. it takes *forever*
 1. QEMU supports simulating different architectures and platforms
 1. of course QEMU handles Ethernet interfaces, however Linux also supports simulating:
     * ATM connections with [ATM over TCP](http://tldp.org/HOWTO/ATM-Linux-HOWTO/device-setup.html#DEVICE-SETUP.ATM-OVER-TCP-SETUP) using `atmtcp`
     * wireless interfaces using [`mac80211_hwsim`](https://www.kernel.org/doc/Documentation/networking/mac80211_hwsim/README) and palming hints from [`hwsim`](http://hostap.epitest.fi/cgit/hostap/tree/tests/hwsim)

So instead we use QEMU.

The following will spin up a QEMU instance of BRatWuRsT:

    make bratwurst

On the first run, the build will take about 30 minutes (on an i7@3Ghz plus the time taken to download 250MB) whilst subsequent runs should take seconds.  Once built, you should see a typical Linux kernel boot up to then drop you into a login prompt; the username is `root` with no password.  Use `Ctrl-A ?` to get some QEMU usage information, `Ctrl-A x` will exit the emulator and there is of course the [QEMU Monitor Console](http://wiki.qemu.org/download/qemu-doc.html#pcsys_005fmonitor) instructions to help you out too.

## Physical Targets

Building for specific physical hardware is available for:

 * [TP-Link TL-W8970](board/tp-link/tl-w8970/README.md)
 * [Linksys WAG54G](board/linksys/wag54g/README.md)
 * [TP-Link TL-MR3020](board/tp-link/tl-mr3020/README.md)

# Extras

## Using a Network Filesystem

To help with development it is handy to have some network filesystem capabilities so you can quickly edit scripts on your side of the fence and use them instantly from inside the VM.  NFS and CIFS though is too big for our target so we use [9P](https://www.kernel.org/doc/Documentation/filesystems/9p.txt) instead which in total weighs in at about 100kB worth of kernel modules.

There are two methods avaliable to mount the 9P export, you of course only need to use one.  For QEMU, the virtio transport is automatically setup for you by [90_shared](board/qemu/mipsel/overlay/opt/bratwurst/rc.d/90_shared) on boot and mounted at `/tmp/shared` (sharing `shared` at the top level directory).

**N.B.** the variable `9P_SHARE` (default: `shared`) can be used to specify the directory you wish to export

For real hardware, you will have to use a userland TCP based server.  To aid you, plumbed into the project, we use a [fork of py9p](https://github.com/svinota/py9p) (there are other [9p server implementation](http://9p.cat-v.org/implementations) you can use) which should work everywhere that has python available (`{apt-get,yum} install python`), you can run a 9P server by just typing into a spare terminal:

    make 9p 9P_SHARE=shared

Then from your router:

    mkdir /tmp/shared
    modprobe 9pnet
    mount -t 9p -o version=9p2000.L,trans=tcp,port=5564 192.0.2.0 /tmp/shared
