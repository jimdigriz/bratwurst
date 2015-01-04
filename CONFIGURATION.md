This document details how to customise the BRatWuRsT build.

# Main Configuration File

When building, a default configuration file is copied to `bratwurst.config` (which is then included in the firmware at `/etc/bratwurst`).

Unless stated otherwise, all the following options are required:

    # {pppoa,pppoe,dhcp}
    NETWORK=pppoe
    
    # N.B. fakeisp expects u:test123 and p:test456
    PPP_USER=test123
    PPP_PASS=test456
    
    # 'eth' (cable) or 'atm' (xDSL)
    UPLINK_TYPE=atm
    # 0..9, eg. 0 -> eth0/atm0
    UPLINK_PORT=0
    
    # required if NETWORK is set to 'pppoa' or 'pppoe'
    # N.B. fakeisp expects pppoa:0,32 pppoe:8,35
    ATM_VPI=8
    ATM_VCI=35
    # {llc,vcmux}
    ATM_ENCAP=vcmux
    
    # optional: local domain to use (defaults to 'localnet')
    #DOMAIN=localnet
    
    # optional: if DHCPv6-PD is unavailable, provide your prefix manually here
    #		N.B. fakeisp makes the subnet number 0->pppoa, 1->pppoe
    #PREFIX=2001:db8:1::/48
    
    # optional: IPv6 ULA subnet (default: automatically generated)
    #ULA=fd00:dead:beef

# User Accounts

To slip user accounts into the build, at the top of the BRatWuRsT project directory you run:

    mkdir users
    cat ~bob/.ssh/id_rsa.pub > users/bob

Here we have added an account for 'bob' whos SSH keys from the local workstation; of course you may addition more accounts in this manner.

Note that:

 1. each account will be password less
 1. passwordless accounts can only log in via the serial port (SSH rejects password authentication)
 1. only public key is supported for SSH
 1. `root` is unable to ever SSH in and the account is also passwordless
 1. to become `root` you use `su`
 1. to add a password to an account, use `passwd`
