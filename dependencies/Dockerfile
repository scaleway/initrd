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


# Install xnbd-client
RUN apt-get install -y -q xnbd-client \
 && apt-get clean


# Install ldd-rec.pl
RUN wget https://raw.githubusercontent.com/moul/mbin/master/ldd-rec.pl -O /usr/local/bin/ldd-rec.pl \
 && chmod +x /usr/local/bin/ldd-rec.pl
