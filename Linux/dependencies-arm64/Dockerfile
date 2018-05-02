FROM scaleway/ubuntu:arm64-xenial

RUN /usr/local/sbin/scw-builder-enter

# Install dependencies
RUN apt-get update          \
 && apt-get upgrade -y      \
 && apt-get install -y      \
   curl                     \
   dropbear                 \
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
      /lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 \
      /lib/aarch64-linux-gnu/libc.so.6 \
      /lib/aarch64-linux-gnu/libnss_dns.so.2 \
      /lib/aarch64-linux-gnu/libnss_files.so.2 \
      /lib/aarch64-linux-gnu/libresolv.so.2 \
      /sbin/blkid \
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
