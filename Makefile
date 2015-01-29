S3_TARGET ?=	s3://$(shell whoami)/
BUSYBOX_URL ?=	http://launchpadlibrarian.net/181784411/busybox-static_1.22.0-8ubuntu1_armhf.deb

uInitrd:	initrd.gz
	mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d $< $@

initrd.gz:	tree/init tree/bin/busybox
	cd tree && mkdir -p bin sbin etc proc sys newroot
	touch tree/etc/mdev.conf
	cd tree && find . -print0 | cpio --null -ov --format=newc | gzip -9 > $(PWD)/$@

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
	mkdir -p tree/bin && ln -s busybox tree/bin/sh || true
	mkdir -p tree/sbin && ln -s busybox tree/sbin/init || true

.PHONY: publish_on_s3

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
