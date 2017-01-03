FROM scaleway/ubuntu:amd64-xenial

RUN /usr/local/sbin/scw-builder-enter

# Install dependencies
# Note: base-files is upgraded separately because otherwise dpkg prompts to ask
# the user what to do for /etc/update-motd.d/10-help-text that is removed in
# the base image.
RUN apt-get update                        \
 && apt-get                               \
    -o Dpkg::Options::='--force-confold'  \
    -o Dpkg::Options::='--force-confdef'  \
    install --only-upgrade base-files     \
 && rm -rf /etc/update-motd.d/*.dpkg-dist \
 && apt-get upgrade -y      \
 && apt-get install -y      \
   curl                     \
   dropbear                 \
   kexec-tools              \
   nfs-common               \
   ntpdate                  \
   parted                   \
   btrfs-tools              \
   udhcpc                   \
   wget                     \
 && apt-get clean


# Install busybox-static
RUN wget -O /tmp/busybox.deb                                                                        \
      http://ftp.fr.debian.org/debian/pool/main/b/busybox/busybox-static_1.22.0-9+deb8u1_amd64.deb  \
 && dpkg -i /tmp/busybox.deb                                                                        \
 && rm -f /tmp/busybox.deb


# Fetch ldd-rec.pl
RUN wget https://raw.githubusercontent.com/moul/mbin/master/ldd-rec.pl  \
      -O /usr/local/bin/ldd-rec.pl                                      \
 && chmod +x /usr/local/bin/ldd-rec.pl


# Fetch scw-metadata
ENV IMAGE_TOOLS_REV=2086abd6fcd71fa215ce76cc244af90651c3c6ae
RUN wget -O /usr/bin/scw-metadata                                                                                           \
      https://raw.githubusercontent.com/scaleway/image-tools/${IMAGE_TOOLS_REV}/skeleton-common/usr/local/bin/scw-metadata  \
 && chmod +x /usr/bin/scw-metadata


# Fetch static xnbd-client
RUN mkdir -p /usr/sbin                                                                                                 \
 && wget -O /usr/sbin/xnbd-client                                                                                      \
      https://github.com/multiarch/build-xnbd-client-static/releases/download/v1.0/x86_64-xnbd-client-static-stripped  \
 && chmod +x /usr/sbin/xnbd-client                                                                                     \
 && ln -s xnbd-client /usr/sbin/@xnbd-client


# Image metadata
CMD ["cat", "/dependencies.tar"]


# Copy local assets
COPY ./tmp/scw-update-server-state /usr/bin/scw-update-server-state
COPY ./export-assets /usr/local/bin/


# Generate tarball
RUN export-assets \
      /bin/busybox \
      /bin/mkfs.btrfs \
      /lib/arm-linux-gnueabihf/libnss_dns.so.2 \
      /lib/arm-linux-gnueabihf/libnss_files.so.2 \
      /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
      /lib/x86_64-linux-gnu/libc.so.6 \
      /lib/x86_64-linux-gnu/libnss_dns.so.2 \
      /lib/x86_64-linux-gnu/libnss_files.so.2 \
      /lib/x86_64-linux-gnu/libresolv.so.2 \
      /sbin/kexec \
      /sbin/mkfs.btrfs \
      /sbin/mkfs.ext4 \
      /sbin/parted \
      /usr/bin/dropbearkey \
      /usr/bin/scw-metadata \
      /usr/lib/klibc/bin/ipconfig \
      /usr/sbin/@xnbd-client \
      /usr/sbin/dropbear \
      /usr/sbin/ntpdate \
      /usr/sbin/xnbd-client \
      /usr/bin/scw-update-server-state
