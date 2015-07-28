#!/bin/sh


set -x


echo "[+] Setting up environment"
export VNAME=$(sysctl -n kern.osrelease)
export VERSION="${VNAME%.*}${VNAME#*.}"
export ARCH=$(sysctl -n hw.machine)
export PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/
umask 022
set -o emacs


echo "[+] Remounting ramdisk read-write"
mount -uw /


echo "[+] Performing DHCP request"
dhclient mvneta0
sleep 1


echo "[+] Signal API current server state: kernel-started"
scw-update-server-state kernel-started
sleep 1



echo "[+] Attaching nbd0"
export_uri=$(oc-metadata VOLUMES_0_EXPORT_URI)
nbd_host=$(echo $export_uri | sed -n 's#nbd://\(.*\):.*$#\1#p')
nbd_port=$(echo $export_uri | sed -n 's#nbd://.*:\(.*\)$#\1#p')
xnbd-client $nbd_host $nbd_port /dev/nbd0c
sleep 1


echo "[+] Running fsck on nbd0"
fsck -y /dev/nbd0a


echo "[+] Mounting nbd0"
mount /dev/nbd0a /mnt


echo "[+] Signal API current server state: booted"
scw-update-server-state booted


echo "[+] pivot_root in /mnt"
mkdir -p /mnt/old
pivot_root /mnt /mnt/old


echo "[-] Droping a debug shell"
exec /bin/sh
