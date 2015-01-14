BRatWuRsT (aka 'Buildroot WRT') is a [buildroot](http://buildroot.uclibc.org/) based home router firmware, similar in scope to [OpenWRT](https://openwrt.org/).

Buildroot is used as it [provides a means for very straight forward development and build cycles](http://elinux.org/images/2/2a/Using-buildroot-real-project.pdf).

Development could be done directly on physical hardware, however:

 1. it takes *forever*
 1. QEMU supports simulating different architectures and platforms
 1. of course QEMU handles Ethernet interfaces, however Linux also supports simulating:
     * ATM connections with [ATM over TCP](http://tldp.org/HOWTO/ATM-Linux-HOWTO/device-setup.html#DEVICE-SETUP.ATM-OVER-TCP-SETUP) using `atmtcp`
     * wireless interfaces using [`mac80211_hwsim`](https://www.kernel.org/doc/Documentation/networking/mac80211_hwsim/README) and palming hints from [`hwsim`](http://hostap.epitest.fi/cgit/hostap/tree/tests/hwsim)

So instead we use QEMU.  It is this which I think makes this project special and different to other home router projects.

Related Links:

 * [Development and Contributing](DEVELOPMENT.md)
 * [TODO](TODO.md)

## Features

 * complete development supported within a [QEMU](http://www.qemu.org/) VM
 * includes a 'fake ISP' VM to emulates xDSL connectivity, the ISP and Internet
 * PPPoA/PPPoE support
 * full native IPv6 support, including [DHCPv6-PD](http://en.wikipedia.org/wiki/Prefix_delegation) to automatically assign IPv6 subnets locally
 * combined IPv6/IPv4 (inet) firewalling with [nftables](http://wiki.nftables.org/)
 * [runit](http://smarden.org/runit/) ([tutorial](http://www.sanityinc.com/articles/init-scripts-considered-harmful/)) as PID 1
 * client services:
  * SSH with [public keys](https://macnugget.org/projects/publickeys/)
  * DNS
  * IPv6 RA
  * DHCPv4

## Supported Physical Targets

 * [Linksys WAG54G](board/ar7/wag54g/README.md)
 * [TP-Link TL-W8970](board/tp-link/tl-w8970/README.md) - currently not supported
 * [TP-Link TL-MR3020](board/tp-link/tl-mr3020/README.md) - currently not supported

# Preflight

You will need roughly 5GB of free disk space and to start off and to [have git installed on your workstation](http://git-scm.com/book/en/Getting-Started-Installing-Git).

The first stop is to fetch a copy of the project:

    git clone https://github.com/jimdigriz/bratwurst.git
    cd bratwurst

Help is available by running:

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
    	qemu-system-$(uname -m | sed 's/\(i[3456]86\|x86_64\)/x86/')

## Fedora 20

**N.B.** this is *untested*

To install the dependencies you should just need to run:

    sudo yum install \
    	gcc gcc-c++ binutils make patch flex bison perl-Data-Dumper automake \
    	wget ca-certificates rsync qemu-kvm qemu-system-mips
    sudo yum update vim-minimal
    sudo yum install vim-common

# How to Run

## Configuration

For a fresh build you will need a configuration file:

    make defconfig

This creates the default `bratwurst.config` configuration file which contains documentation inline.  Later this file is used during the firmware building process and installed on the target at `/etc/bratwurst`.  Open this file in an editor and edit it to suit your environment, the defaults can be left as is if you just want to spin up the VM.

### User Accounts

To slip user accounts into the build, at the top of the BRatWuRsT project directory you run:

    mkdir users
    cat ~bob/.ssh/id_rsa.pub > users/bob

Here we have added an account for 'bob' using the SSH keys from the local workstation; of course you may addition more accounts in this manner.

Note that:

 1. each account will be password-less
 1. password-less accounts can only log in via the serial port (SSH rejects password authentication)
 1. only public key is supported for SSH
 1. `root` is unable to ever SSH in and the account is also passwordless
 1. to become `root` you use `su`
 1. to add a password to an account, use `passwd`

## Running

To build the `qemu/mipsel` board firmware and automatically start up QEMU instance of BRatWuRsT you run:

    make bratwurst BOARD=qemu/mipsel

**N.B.** making `bratwurst` only works for `qemu/*` targets, whilst the default for `BOARD` is `qemu/mipsel` so can be omitted in the example above

On the first run, the build will take about 30 minutes (on an i7@3Ghz plus the time taken to download 250MB) whilst subsequent runs should take seconds.  Once built, you will see a typical Linux kernel boot up which drops you at a login prompt; the username is `root` with no password.  Use `Ctrl-A ?` to get some QEMU usage information, `Ctrl-A x` will exit the emulator and there is of course the [QEMU Monitor Console](http://wiki.qemu.org/download/qemu-doc.html#pcsys_005fmonitor) instructions to help you out too.

## Building

Building for other targets is just a case of reading the relevant page linked from [Supported Physical Targets](#supported-physical-targets) above to learn how to install the built firmware to your target.  Building the firmware its-self is done just by typing:

    make soc/board

For information on customising the build, read the [Customising the Build](DEVELOPMENT.md#customising-the-build).
