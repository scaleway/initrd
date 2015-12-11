FROM armbuild/ubuntu:vivid


# Install dependencies
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
   curl \
   dropbear \
   nfs-common \
   ntpdate \
   parted \
   btrfs-tools \
   udhcpc \
   wget \
 && apt-get clean


# Install busybox-static
RUN wget http://ftp.fr.debian.org/debian/pool/main/b/busybox/busybox-static_1.22.0-9+deb8u1_armhf.deb -O /tmp/busybox.deb \
 && dpkg -i /tmp/busybox.deb \
 && rm -f /tmp/busybox.deb


# Install export scripts
RUN wget https://raw.githubusercontent.com/moul/mbin/master/ldd-rec.pl -O /usr/local/bin/ldd-rec.pl \
 && chmod +x /usr/local/bin/ldd-rec.pl
COPY ./export-assets /usr/local/bin/
