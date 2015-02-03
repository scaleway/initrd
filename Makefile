S3_TARGET ?=		s3://$(shell whoami)/
KERNEL_URL ?=		http://ports.ubuntu.com/ubuntu-ports/dists/lucid/main/installer-armel/current/images/versatile/netboot/vmlinuz
CMDLINE ?=		ip=dhcp root=/dev/nbd0 nbd.max_parts=8 boot=local nometadata
MKIMAGE_OPTS ?=		-A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs
DEPENDENCIES ?=		/bin/busybox /usr/sbin/xnbd-client /usr/sbin/ntpdate /lib/arm-linux-gnueabihf/libnss_files.so.2 /lib/arm-linux-gnueabihf/libnss_dns.so.2
DOCKER_DEPENDENCIES ?=	armbuild/initrd-dependencies


.PHONY: publish_on_s3 qemu dist dist_do dist_teardown all travis

# Phonies
all:	uInitrd

travis:
	bash -n tree/init tree/functions tree/boot-*
	make -n Makefile

qemu:    vmlinuz initrd.gz
	qemu-system-arm \
		-M versatilepb \
		-cpu cortex-a9 \
		-kernel ./vmlinuz \
		-initrd ./initrd.gz \
		-m 256 \
		-append "$(CMDLINE)" \
		-no-reboot \
		-monitor stdio

publish_on_s3:	uInitrd initrd.gz
	for file in $<; do \
	  s3cmd put --acl-public $$file $(S3_TARGET); \
	done

dist:
	$(MAKE) dist_do || $(MAKE) dist_teardown

dist_do:
	-git branch -D dist || true
	git checkout -b dist
	$(MAKE)
	git add -f uInitrd initrd.gz tree
	git commit -am "dist"
	git push -u origin dist -f
	$(MAKE) dist_teardown

dist_teardown:
	git checkout master


# Files
vmlinuz:
	wget -O $@ $(KERNEL_URL)


uInitrd:	initrd.gz
	$(MAKE) uInitrd-local || $(MAKE) uInitrd-docker
	touch $@

uInitrd-local:	initrd.gz
	mkimage $(MKIMAGE_OPTS) -d initrd.gz uInitrd

uInitrd-docker:	initrd.gz
	docker run \
		-it --rm \
		-v /Users/moul/Git/github/initrd:/host \
		-w /tmp \
		moul/u-boot-tools \
		/bin/bash -xec \
		' \
		  cp /host/initrd.gz . && \
		  mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d ./initrd.gz ./uInitrd && \
		  cp uInitrd /host/ \
		'


tree/usr/bin/oc-metadata:
	mkdir -p $(shell dirname $@)
	wget https://raw.githubusercontent.com/online-labs/ocs-scripts/master/skeleton/usr/local/bin/oc-metadata -O $@
	chmod +x $@


tree/usr/sbin/@xnbd-client.link:	tree/usr/sbin/xnbd-client
	ln -sf $(<:tree%=%) $(@:%.link=%)
	touch $@


tree/bin/sh:	tree/bin/busybox
	ln -s busybox $@


initrd.gz:	$(addprefix tree/, $(DEPENDENCIES)) $(wildcard tree/*) tree/bin/sh tree/usr/bin/oc-metadata tree/usr/sbin/@xnbd-client.link Makefile
	find tree \( -name "*~" -or -name ".??*~" -or -name "#*#" -or -name ".#*" \) -delete
	cd tree && find . -print0 | cpio --null -o --format=newc | gzip -9 > $(PWD)/$@


$(addprefix tree/, $(DEPENDENCIES)):	dependencies/Dockerfile
	docker build -q -t $(DOCKER_DEPENDENCIES) ./dependencies/
	docker run -it $(DOCKER_DEPENDENCIES) export-assets $(@:tree/%=%) $(DEPENDENCIES)
	docker cp `docker ps -lq`:/tmp/export.tar $(PWD)/
	docker rm `docker ps -lq`
	tar -m -C tree/ -xf export.tar
	-rm -f export.tar
