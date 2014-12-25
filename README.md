BRatWuRsT (aka 'Buildroot WRT') is a project that creates a [buildroot](http://buildroot.uclibc.org/) based home router firmware, similar in scope to [OpenWRT](https://openwrt.org/), and walks you through the steps required to install it and get it running.

Included in this project is:

 * **[Development](DEVELOPMENT.md):** how to work on the project
 * **[Contributing](CONTRIBUTING.md):** how to contribute to the project
 * **[TODO](TODO.md):** a list of outstanding items, as well as aims and thoughts on where the project is going

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
    	qemu-system-$(uname -m | sed 's/\(i[3456]86\|x86_64\)/x86/')

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

The following will spin up a QEMU instance of BRatWuRsT (`ARCH` defaults to `mipsel` so can be omitted):

    ARCH=mipsel make bratwurst

**N.B.** do *not* put the `ARCH` at the end, otherwise the variable cascades through the build and breaks it

On the first run, the build will take about 30 minutes (on an i7@3Ghz plus the time taken to download 250MB) whilst subsequent runs should take seconds.  Once built, you should see a typical Linux kernel boot up which the drops you at a login prompt; the username is `root` with no password.  Use `Ctrl-A ?` to get some QEMU usage information, `Ctrl-A x` will exit the emulator and there is of course the [QEMU Monitor Console](http://wiki.qemu.org/download/qemu-doc.html#pcsys_005fmonitor) instructions to help you out too.

## Physical Targets

Building for specific physical hardware is available for:

 * [Linksys WAG54G](board/linksys/wag54g/README.md)
 * [TP-Link TL-W8970](board/tp-link/tl-w8970/README.md)
 * [TP-Link TL-MR3020](board/tp-link/tl-mr3020/README.md)

# Configuration

## User Accounts

To slip in user accounts into the build, you create a directory called `users` and name each file within after the username that is logging in.  The contents of those files are the SSH public keys.  For example, if you are `bob` and you want your keys to be slipped in, you would do:

    mkdir users
    cat ~/.ssh/id_rsa.pub > users/bob

Now when you build your firmware, the user accounts will be included.

Note that:

 1. each account will be password less
 1. passwordless accounts can only log in via the serial port (SSH rejects password authentication)
 1. only public key is supported for SSH
 1. `root` is unable to ever SSH in and the account is also passwordless
 1. to become `root` you use `su`
 1. to add a password to an account, use `passwd`
