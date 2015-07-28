#!/bin/sh

set -x

echo "[+] Remounting ramdisk read-write"
mount -uw /

echo "[+] Performing DHCP request"
dhclient mvneta0


echo "[-] Droping a debug shell"
exec /bin/sh
