S3_TARGET ?=	s3://$(shell whoami)/
BUSYBOX_URL ?=	http://launchpadlibrarian.net/181784411/busybox-static_1.22.0-8ubuntu1_armhf.deb
KERNEL_URL ?=	http://ports.ubuntu.com/ubuntu-ports/dists/lucid/main/installer-armel/current/images/versatile/netboot/vmlinuz
CMDLINE ?=	ip=dhcp root=/dev/nbd0 nbd.max_parts=8 boot=local nometadata


.PHONY: publish_on_s3 qemu dist dist_do dist_teardown all

# Phonies
all:	uInitrd

qemu:    vmlinuz initrd.gz
	qemu-system-arm \
		-M versatilepb \
		-cpu cortex-a8 \
		-kernel ./vmlinuz \
		-initrd ./initrd.gz \
		-m 256 \
		-append "$(CMDLINE)"

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
	mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d $< $@

initrd.gz:	tree tree/init tree/functions tree/bin/busybox tree/bin/sh
	cd tree && find . -print0 | cpio --null -ov --format=newc | gzip -9 > $(PWD)/$@

tree/bin/sh:
	cd tree && mkdir -p bin sbin etc proc sys newroot usr/bin usr/sbin
	ln -s busybox tree/bin/sh || true

tree/bin/busybox:
	mkdir -p $(shell dirname $@)
	docker run -it --rm \
		-v $(PWD)/tree/bin:/host/bin \
		busybox \
		/bin/sh -xec ' \
		  cd /tmp && \
		  wget $(BUSYBOX_URL) -O busybox.deb && \
		  ar x busybox.deb && \
		  xz -d data.tar.xz && \
		  tar xf data.tar && \
		  cp bin/busybox /host/bin/busybox \
		'
	chmod +x $@
