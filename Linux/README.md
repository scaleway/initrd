# initrd/*Linux*
[![Build Status](https://travis-ci.org/scaleway/initrd.svg?branch=master)](https://travis-ci.org/scaleway/initrd)

Initrd used to boot Linux images on Scaleway servers

## Example of output

```bash
Begin: Checking user input for debug mode ...  done.
Begin: Checking user input for debug shell ...  done.
Begin: Signaling the server is kernel-started to the control plane ... done.
Begin: Adjusting time (ntp) ...  done.
Begin: Attaching nbd0 ...  done.
Begin: Mounting nbd0 root ... done.
Begin: Checking metadata in case we skip to wait for secondary volumes to be ready ...  done.
Begin: Attaching nbd0 ...  done.
Begin: Signaling the server is booted to the control plane ... done.
Begin: Checking metadata for debug shell ...  done.
```

## Features

- configure *network*
- synchronize time (*NTP*)
- *set verbosity* from server tags
- drop a *debug shell* from server tags
- configure `/etc/hostname` and `/etc/resolv.conf`
- prepare `/dev`, `/proc`, `/sys`, `/run` special filesystems
- *inform the platform* about current boot steps (status available from the web console and API)
- configure *GPIO*s to enable serial port
- prepare a `/run/initramfs` *tmpfs* directory for shutdown
- wait for secondary *NBD* volumes


## Boot options

Using the *bootscripts*, we can change the `/proc/cmdline`.
Using the servers tags, we can change the behaviour of the initrd without changing the `/proc/cmdline`.

Here are the availble *initrd variables*:

- **boot={nbd|rescue|nfs|live}**: change the [boot mode](#Boot-modes)
- **INITRD_DEBUG=1**: enable initrd debug (apply a global `set -x`)
- **INITRD_VERBOSE=1**: enable initrd verbose
- **INITRD_PRE_SHELL=1**: drop a shell just after starting the initrd
- **INITRD_POST_SHELL=1**: drop a shell just before leaving the initrd
- **INITRD_DROPBEAR=1**: start a dropbear sshd server
- **init=/sbin/init**: init script executed when leaving the initrd
- **rescue_image=http://example.com/my-image.tar**: Tarball *URL* used to boot (no effect with *nfs* and *nbd* boot mode
- **NO_NTPDATE=1**: disable NTP time synchronization
- **INITRD_WAIT_SECONDARY_VOLUMES=1**: Attach secondary *NBD* devices before leaving the initrd (future default option)
- **nfsroot=server:path**: *NFS* mountpoint (ignored for non-*NFS* boot modes)


## Boot-modes

- **NBD**: attach NBD devices, boot on /dev/nbd0
- **RESCUE**: download and unarchive rootfs using http (non-persistent)
- **NFS**: boot on a NFS rootfs
- **LIVE**: mix between **NBD** and **RESCUE**, download a rootfs using http and write it to /dev/nbd0

## Changelog

### v3

- Worked on the fancyness
- Added multiple boot mode: nfs, live, nbd, rescue
- Added dropbear shell
- Initrd version is now printed during boot
- Size reduced

### v2

Initial open source version of the initrd

### v1

Initial version of the initrd, closed source

## Developement dependencies

- for **x86_64** ARCH:
  - docker
  - docker-compose (only for qemu testing)
- for **armhf** ARCH:
  - docker
  - u-boot-tools


## Commands

    # build the initrd
    make build

    # push the initrd on S3
    make publish_on_s3


## Advanced commands

    # rebuild dependencies (from an armhf server with docker)
    rm -fdependencies.tar.gz; make dependencies

    # run a debug shell in the dependencies image
    make dependencies-shell

    # run a debug shell in the initrd
    make uInitrd-shell

    # test with QEMU (beta)
    make qemu

    # perform the travis tests
    make travis

# Licensing

© 2014-2015 Scaleway - [MIT License](https://github.com/scaleway/image-tools/blob/master/LICENSE).
A project by [![Scaleway](https://avatars1.githubusercontent.com/u/5185491?v=3&s=42)](https://www.scaleway.com/)
