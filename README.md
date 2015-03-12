Initrd on Online Labs [![Build Status](https://travis-ci.org/online-labs/initrd.svg?branch=master)](https://travis-ci.org/online-labs/initrd)
=====================

Initrd used to boot C1 servers.

Based on Busybox.


Features
--------

- configure network
- configure time (NTP)
- set verbosity from server tags
- drop a debug shell from server tags
- configure /etc/hosts and /etc/resolv.conf
- prepare /dev, /proc, /sys, /run
- gives information about the current boot step and status (available from the web console)
- configure GPIOs to enable serial port



Boot types
----------

- NBD: fetch `NBD_0` server address and port, and attach it as a volume on /dev/nbd0
- RESCUE: unarchive a downloaded filesystem archive in memory (non-persistent)


Developement dependencies
-------------------------

- Docker
- Fig


Commands
--------

    # build the initrd
    make build

    # push the initrd on S3
    make publish_on_s3

    # test with QEMU (beta)
    make qemu
