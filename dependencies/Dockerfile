FROM armbuild/ubuntu:vivid


# Install dependencies
RUN apt-get update \
 && apt-get upgrade -q -y \
 && apt-get install -q -y wget \
 && apt-get clean


# Install busybox-static
RUN wget http://launchpadlibrarian.net/181784411/busybox-static_1.22.0-8ubuntu1_armhf.deb -O /tmp/busybox.deb \
 && dpkg -i /tmp/busybox.deb \
 && rm -f /tmp/busybox.deb
