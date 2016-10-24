# initrd/*Linux*
[![Build Status](https://travis-ci.org/scaleway/initrd.svg?branch=master)](https://travis-ci.org/scaleway/initrd)

Initrd used to boot Linux images on Scaleway servers

## Schema (boot timeline)

```
┌──────────────────────────────────────────────────────────────────────┐
│                          electrical poweron                          │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                  ┌─────x86_64──────┴───────armhf─────┐
                  │                                   │
                  ▼                                   ▼
┌──────────────────────────────────┐ ┌─────────────────────────────────┐
│  start bios                      │ │  start u-boot                   │
│                                  │ │                                 │
│* activate serial port            │ │* dhcp request                   │
│* dhcp request                    │ │* TFTP requests to download      │
│* TFTP request to get iPXE        │ │  the kernel and the initrd      │
│* HTTP request to the metadata    │ │* set the linux cmdline          │
│  server to get bootscript details│ │* activate serial port           │
│* HTTP requests to download       │ │* jump to kernel code            │
│  kernel and initrd               │ │                                 │
│* download initrd in memory       │ │                                 │
│* set the linux cmdline           │ │                                 │
└──────────────────────────────────┘ └─────────────────────────────────┘
                  │                                   │
                  └─────────────────┬─────────────────┘
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│* kernel is booting                                                   │
│* dhcp request                                                        │
│* jump to initrd                                                      │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│* initrd is starting                                                  │
│* display scaleway banner                                             │
│* display kernel/initrd build info                                    │
│* create busybox symlinks                                             │
│* mount /dev,/run,/sys,/proc                                          │
│* display system info                                                 │
│* configure IPV4 network                                              │
│* configure IPV6 network                                              │
│* run scw-metadata to create initial metadata cache                   │
│* display metadata info                                               │
│* configure GPIOs (C1 only)                                           │
│* Enable debug/verbose mode                                           │
│* drop a shell if INITRD_PRE_SHELL=1                                  │
│* signal server is "kernel-started"                                   │
│  HTTP request to the metadata API to signal the kernel is started.   │
│  Useful for debugging purpose: if the boot fails for any reason,     │
│  you know it failed before/after the kernel started                  │
│* quick sync with ntp server                                          │
│* mount rootfs                                                        │
└──────────────────────────────────────────────────────────────────────┘
                                    │
          ┌────────────────────┬ boot=XXX ────────┬──────────────┐
          ▼                    ▼                  ▼              ▼
      ┌──────┐              ┌────┐        ┌───────────────┐   ┌─────┐
      │rescue│              │live│        │local (default)│   │ nfs │
      └──────┘              └────┘        └───────────────┘   └─────┘
          │                    │                  │              │
          ▼                    ▼                  ▼              ▼
┌──────────────────┐┌────────────────────┐┌───────────────┐┌───────────┐
│                  ││   attach nbd0 if   ││               ││           │
│                  ││  ${root} is nbd0   ││               ││           │
│                  ││                    ││               ││           │
│  mount tmpfs on  ││ format ${root} if  ││               ││           │
│    ${rootmnt}    ││ first boot (empty  ││               ││           │
│                  ││   parted) or if    ││attach nbd0 if ││           │
│                  ││ live_mode=install  ││${root} is nbd0││           │
│                  ││                    ││               ││ mount nfs │
│                  ││   mount ${root}    ││               ││           │
└──────────────────┘└────────────────────┘│ mount ${root} ││           │
          │                    │          │               ││           │
          └──────────┬─────────┘          │               ││           │
                     ▼                    │               ││           │
┌────────────────────────────────────────┐│               ││           │
│download ${rescue_image} using HTTP and ││               ││           │
│        extract it to ${rootmnt}        ││               ││           │
└────────────────────────────────────────┘└───────────────┘└───────────┘
                     │                            │              │
                     └──────────────┬─────────────┴──────────────┘
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│* attach non-rootfs nbd volumes                                       │
│* display image info (/etc/scw-release)                               │
│* signal server is "booted"                                           │
│  HTTP request to the metadata API to signal the server               │
│  is successfully booted.                                             │
│  If we don't make this request, the server will be automatically     │
│  powered off after a few minutes because the boot is                 │
│  considered failed                                                   │
│* configure /etc/hostname if empty                                    │
│* configure /etc/resolv.conf if empty                                 │
│* create a random root password on first boot                         │
│  (no root password in /etc/shadow)                                   │
│* drop a shell if INITRD_POST_SHELL=1                                 │
│* start a dropbear server if INITRD_DROPBEAR=1                        │
│* mount /proc,/sys,/run,/dev on rootfs                                │
│* ensure minimal devices (console,null,zero,ptmx,tty,random,urandom)  │
│  are mknoded                                                         │
│* copy the whole initramfs in ${rootfs}/run/initramfs (for shutdown)  │
│* display bottom footer                                               │
│* switch_root on /sbin/init                                           │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│                  distribution/image is starting...                   │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│                             ssh is ready                             │
└──────────────────────────────────────────────────────────────────────┘
```

## Example of output

```python
Welcome to Scaleway' initrd            http://j.mp/scw-initrd-linux

███████╗ ██████╗ █████╗ ██╗     ███████╗██╗    ██╗ █████╗ ██╗   ██╗
██╔════╝██╔════╝██╔══██╗██║     ██╔════╝██║    ██║██╔══██╗╚██╗ ██╔╝
███████╗██║     ███████║██║     █████╗  ██║ █╗ ██║███████║ ╚████╔╝
╚════██║██║     ██╔══██║██║     ██╔══╝  ██║███╗██║██╔══██║  ╚██╔╝
███████║╚██████╗██║  ██║███████╗███████╗╚███╔███╔╝██║  ██║   ██║
╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝

>>> Initrd build: v3.6 - 2015/11/24
>>> Kernel version: 3.2.34-30

>>> Installing busybox...
>>> Cloning initramfs for shutdown......
>>> Mounting pseudo-filesystems......
>>> Mounting /dev...
>>> Mounting /dev/pts...
>>> Mounting /run...
>>> Mounting /sys...
>>> Mounting /proc...

>>> Kernel cmdline: earlyprintk=ttyS0 console=ttyS0,9600n8 nousb noplymouth ip=dhcp boot=local root=/dev/nbd0 nbd.max_parts=8

>>> Configuring GPIOs...
>>> Configuring network...

>>> Server ID: 60602cf7-797d-4a3b-b936-713fa9c3fcdb
>>> Private IP: 10.1.14.126
>>> Public IP: 212.47.234.191
>>> Hostname: adoring-roentgen

>>> Checking user input for debug/verbose mode...
>>> Checking user input for debug shell...
>>> Signaling the server is kernel-started to the control plane...
>>> Adjusting time (ntp)...
>>> Initializing 'local' root file system...
>>> Attaching nbd0...
>>> Mounting nbd0 root...
>>> Mounting /newroot...
>>> Checking metadata in case we skip to wait for secondary volumes to be ready...
>>> Signaling the server is booted to the control plane...
>>> Creating default configuration files on rootfs......
>>> Checking metadata for debug shell...
>>> Checking metadata for debug sshd (dropbear)...
>>> Changing root password...
>>> Mounting /newroot/proc...
>>> Mounting /newroot/sys...
>>> Mounting /newroot/run...
>>> Mounting /newroot/dev...
>>> Moving initramfs backup to /run/initramfs for shutdown...
>>> Switching to linux...
End of Scaleway' initrd
           _ _       _      _          _ _
 ___ _ _ _|_| |_ ___| |_   | |_ ___   | |_|___ _ _ _ _
|_ -| | | | |  _|  _|   |  |  _| . |  | | |   | | |_'_|
|___|_____|_|_| |___|_|_|  |_| |___|  |_|_|_|_|___|_,_|


   OpenRC 0.16.4.90c464e is starting up Linux 3.2.34-30 (armv7l)

 * /proc is already mounted
 * /run/openrc: creating directory
 * /run/lock: creating directory
 * /run/lock: correcting owner
 * Caching service dependencies ... [ ok ]
 * Checking local filesystems  ... [ ok ]
 * Remounting filesystems ... [ ok ]
 * Mounting local filesystems ... [ ok ]
 * Starting networking ... *   eth0 ... [ ok ]
 * Starting busybox ntpd ... [ ok ]
 * Fetching SSH keys ... [ ok ]
ssh-keygen: generating new host keys: RSA1 RSA DSA ECDSA ED25519
 * Starting sshd ... [ ok ]
 * Configuring kernel parameters ... [ ok ]

Welcome to Alpine Linux 3.2
Kernel 3.2.34-30 on an armv7l (/dev/ttyS0)

c1-10-1-14-126 login:
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
- **RESET_PASSWORD=1**: generate a new random password for root on boot
- **init=/sbin/init**: init script executed when leaving the initrd
- **rescue_image=http://example.com/my-image.tar**: Tarball *URL* used to boot (no effect with *nfs* and *nbd* boot mode
- **NO_NTPDATE=1**: disable NTP time synchronization
- **INITRD_WAIT_SECONDARY_VOLUMES=1**: Attach secondary *NBD* devices before leaving the initrd (future default option)
- **SKIP_OPTIONAL_NBD_DEVICES**: Skip *NBD* devices auto-attach if the volume is optional (all the volumes for rescue, only secondary volumes for NBD-based boots)
- **nfsroot=server:path**: *NFS* mountpoint (ignored for non-*NFS* boot modes)
- **KEXEC_KERNEL=path**: http or local url of the kernel to kexec in on boot
- **KEXEC_INITRD=path**: http or local url of the initrd to kexec in on boot


## Boot-modes

- **NBD**: attach NBD devices, boot on /dev/nbd0
- **RESCUE**: download and unarchive rootfs using http (non-persistent)
- **NFS**: boot on a NFS rootfs
- **LIVE**: mix between **NBD** and **RESCUE**, download a rootfs using http and write it to /dev/nbd0

## Changelog

### 3.12.1 (2016-10-24)

* Add custom parameters to the cmdline when KEXECing with `KEXEC_APPEND=xxx` ([#168](https://github.com/scaleway/initrd/issues/168))

[full commits list](https://github.com/scaleway/initrd/compare/v3.12...v3.12.1)

### 3.12 (2016-10-19)

* kexec improvements
* Generate machine id
* Fetch kernel modules

[full commits list](https://github.com/scaleway/initrd/compare/v3.11.1...3.12)

### 3.11.1 (2016-06-13)

* Fix syntax in /etc/hosts ([#165](https://github.com/scaleway/initrd/pull/165))

[full commits list](https://github.com/scaleway/initrd/compare/v3.11...v3.11.1)

### 3.11 (2016-06-10)

* Add hostname to /etc/hosts ([#155](https://github.com/scaleway/initrd/issues/155))
* Prevent the server to stop every 5 minutes when using `INITRD_PRE_SHELL=1`
* Initial support of kexec using servers tags ([#91](https://github.com/scaleway/initrd/issues/91))
* Disconnect NBD devices before kexecing ([#161](https://github.com/scaleway/initrd/issues/161))
* Improve initial time set-up ([#153](https://github.com/scaleway/initrd/issues/153)) ([@ElNounch](https://github.com/ElNounch))

[full commits list](https://github.com/scaleway/initrd/compare/v3.10.1...v3.11)

### 3.10.1 (2016-03-16)

* Add server tags ssh keys if available

[full commits list](https://github.com/scaleway/initrd/compare/v3.10...v3.10.1)

### 3.10 (2016-03-08)

* Allow alternative ip option
* Fixing attach_nbd_device() captures of @xnbd-client PIDs [#147](https://github.com/scaleway/initrd/pull/147)

[full commits list](https://github.com/scaleway/initrd/compare/v3.9...v3.10)

### 3.9 (2016-03-07)

* Configure all interfaces ([#137](https://github.com/scaleway/initrd/issues/137))
* Initial support of IPV6
* Add a way to enable early VERBOSE mode using bootscript's cmdline
* Add a flag not to signal the current state to the metadata server
* Improved logging

[full commits list](https://github.com/scaleway/initrd/compare/v3.8...v3.9)

### 3.8 (2016-02-18)

* Be more strict when using get_any ([#134](https://github.com/scaleway/initrd/issues/134))
* Restrict GPIO configuration to C1 servers
* Publishing (on store, s3) a "latest" symlink
* Printing more information about the current kernel
* Printing information about the CPU and physycal memory
* Add a `SKIP_OPTIONAL_NBD_DEVICES` option to ... skip ... optional ... nbd ... devices ...
* Printing information about NBD devices
* Printing information about the running image ([#131](https://github.com/scaleway/initrd/issues/131))

[full commits list](https://github.com/scaleway/initrd/compare/v3.7...v3.8)

### 3.7 (2015-12-16)

* Complete multiarch refactor [#124](https://github.com/scaleway/initrd/pull/124)
* Complete dependencies refactor, huge speed gain
* Travis builds fixed
* Bump dependencies to the latest version (taking binaries from `ubuntu:wily` instead of `ubuntu:vivid`)
* Initial BTRFS support [#123](https://github.com/scaleway/initrd/pull/123) ([@boris-arzur](https://github.com/boris-arzur))

[full commits list](https://github.com/scaleway/initrd/compare/v3.6...v3.7)

### v3.6 (2015-11-24)

* Speedup boot [#108](https://github.com/scaleway/initrd/issues/108)
* Do not store serial root password in standard user data

[full commits list](https://github.com/scaleway/initrd/compare/v3.5...v3.6)

### v3.5 (2015-11-19)

* Reordered actions so `INITRD_DROPBEAR` and `INITRD_POST_SHELL` are executed after root password configuration
* scw-update-server-state retries the request when an error 429 occurred [#106](https://github.com/scaleway/initrd/issues/106)

[full commits list](https://github.com/scaleway/initrd/compare/v3.4.1...v3.5)

### v3.4.1 (2015-10-06)

* Fix: regression on booting servers with cmdline containing 'boot=local' [#97](https://github.com/scaleway/initrd/issues/97)

[full commits list](https://github.com/scaleway/initrd/compare/v3.4...v3.4.1)

### v3.4 (2015-10-05)

* Made the `initrd` more architecture agnostic to allow testing on Travis [#92](https://github.com/scaleway/initrd/pull/92)
* Register `xnbd-client` processes to `/run/sendsigs-omit.d/`
* Automatically attach NBD devices [#94](https://github.com/scaleway/initrd/issues/94)

[full commits list](https://github.com/scaleway/initrd/compare/v3.3...v3.4)

### v3.3 (2015-09-07)

* Do not test `/sbin/init` availability using `test -x` to works against absolute symlinks [#82](https://github.com/scaleway/initrd/issues/82)
* Added `get_userdata` helper [#80](https://github.com/scaleway/initrd/issues/80)
* Added a temporary hack for letting getty the time to flush [#76](https://github.com/scaleway/initrd/issues/76)

[full commits list](https://github.com/scaleway/initrd/compare/v3.2...v3.3)

### v3.2 (2015-08-28)

* Improved debug,warn,error messages
* Setting up a random root password on first boot [#46](https://github.com/scaleway/initrd/issues/46)

[full commits list](https://github.com/scaleway/initrd/compare/v3.1...v3.2)

### v3.1 (2015-08-24)

* Improved debug/info/warn messages
* Added 'continue-boot' helper

[full commits list](https://github.com/scaleway/initrd/compare/v3...v3.1)

### v3 (2015-08-18)

- Worked on the fancyness
- Added multiple boot mode: nfs, live, nbd, rescue
- Added dropbear shell
- Initrd version is now printed during boot
- Size reduced

[full commits list](https://github.com/scaleway/initrd/compare/v2...v3)

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
