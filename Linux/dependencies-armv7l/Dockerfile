FROM scaleway/ubuntu:armhf-xenial

RUN /usr/local/sbin/scw-builder-enter

# Install dependencies
RUN apt-get update          \
 && apt-get upgrade -y      \
 && apt-get install -y      \
   curl                     \
   dropbear                 \
   kexec-tools              \
   nfs-common               \
   ntpdate                  \
   parted                   \
   btrfs-tools              \
   wget                     \
   busybox-static           \
 && apt-get clean


# Fetch scw-metadata
ENV IMAGE_TOOLS_REV=2086abd6fcd71fa215ce76cc244af90651c3c6ae
RUN wget -O /usr/bin/scw-metadata                                                                                           \
      https://raw.githubusercontent.com/scaleway/image-tools/${IMAGE_TOOLS_REV}/skeleton-common/usr/local/bin/scw-metadata  \
 && chmod +x /usr/bin/scw-metadata


# Fetch static xnbd-client
RUN mkdir -p /usr/sbin                                                                                                 \
 && wget -O /usr/sbin/xnbd-client                                                                                      \
      https://github.com/multiarch/build-xnbd-client-static/releases/download/v1.0/armv7l-xnbd-client-static-stripped  \
 && chmod +x /usr/sbin/xnbd-client                                                                                     \
 && ln -s xnbd-client /usr/sbin/@xnbd-client


# Image metadata
CMD ["cat", "/dependencies.tar"]


# Copy local assets
COPY ./tmp/scw-update-server-state /usr/bin/scw-update-server-state
COPY ./tmp/ldd-rec.pl /usr/local/bin/
COPY ./tmp/export-assets /usr/local/bin/


# Generate tarball
RUN export-assets \
      /bin/busybox \
      /bin/mkfs.btrfs \
      /lib/arm-linux-gnueabihf/ld-linux-armhf.so.3 \
      /lib/arm-linux-gnueabihf/libc.so.6 \
      /lib/arm-linux-gnueabihf/libnss_dns.so.2 \
      /lib/arm-linux-gnueabihf/libnss_files.so.2 \
      /lib/arm-linux-gnueabihf/libresolv.so.2 \
      /sbin/blkid \
      /sbin/kexec \
      /sbin/mkfs.btrfs \
      /sbin/mkfs.ext4 \
      /sbin/parted \
      /sbin/sfdisk \
      /usr/bin/dropbearkey \
      /usr/bin/scw-metadata \
      /usr/bin/partx \
      /usr/lib/klibc/bin/ipconfig \
      /usr/sbin/@xnbd-client \
      /usr/sbin/dropbear \
      /usr/sbin/ntpdate \
      /usr/sbin/xnbd-client \
      /usr/bin/scw-update-server-state
