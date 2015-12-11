S3_TARGET ?=		s3://$(shell whoami)/
STORE_HOSTNAME ?=	store.scw.42.am
STORE_TARGET ?=		$(STORE_HOSTNAME):store/initrds/
KERNEL_URL ?=		http://ports.ubuntu.com/ubuntu-ports/dists/lucid/main/installer-armel/current/images/versatile/netboot/vmlinuz
MKIMAGE_OPTS ?=		-A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs
DEPENDENCIES ?=	\
	/bin/busybox \
	/lib/arm-linux-gnueabihf/libnss_dns.so.2 \
	/lib/arm-linux-gnueabihf/libnss_files.so.2 \
	/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 \
	/lib/x86_64-linux-gnu/libc.so.6 \
	/lib/x86_64-linux-gnu/libnss_dns.so.2 \
	/lib/x86_64-linux-gnu/libnss_files.so.2 \
	/lib/x86_64-linux-gnu/libresolv.so.2 \
	/sbin/mkfs.ext4 \
	/sbin/mkfs.btrfs \
	/bin/mkfs.btrfs \
	/sbin/parted \
	/usr/bin/dropbearkey \
	/usr/lib/klibc/bin/ipconfig \
	/usr/sbin/dropbear \
	/usr/sbin/ntpdate
DOCKER_DEPENDENCIES ?=	armbuild/initrd-dependencies
CMDLINE ?=		ip=dhcp root=/dev/nbd0 nbd.max_parts=8 boot=local nousb noplymouth
QEMU_OPTIONS ?=		-M versatilepb -cpu cortex-a9 -m 256 -no-reboot
INITRD_DEBUG ?=		0
TARGET ?= armv7l
HOST_ARCH ?=		$(shell uname -m)
COMMIT :=		$(shell git rev-parse HEAD)
TAG :=			$(shell git describe --tags --always)
PUBLISH_FILES ?=	uInitrd-Linux-$(TARGET)-$(TAG) initrd-Linux-$(TARGET)-$(TAG).gz
GIT_REMOTE ?=		origin

.PHONY: publish_on_s3 qemu dist dist_do dist_teardown all travis_check travis_build dependencies-shell uInitrd-shell


# Phonies
all:	build

.PHONY: build
build:	uInitrd


initrd-Linux-$(TARGET)-$(TAG).gz: initrd-Linux-$(TARGET).gz
	ln -f $< $@


uInitrd-Linux-$(TARGET)-$(TAG): uInitrd-Linux-$(TARGET)
	ln -f $< $@


travis_check:
	bash -n tree-common/init tree-common/shutdown tree-common/functions tree-common/boot-*


travis_build:
	$(MAKE) TARGET=x86_64

	#$(MAKE) TARGET=armv7l
	# due to the lack of binfmt-support in travis, armv7l is currently disabled


qemu:
	$(MAKE) qemu-docker-text || $(MAKE) qemu-local-text


armdisk.img:
	qemu-img create -f raw armdisk.img 8G

qemu-local-text:	vmlinuz initrd-Linux-$(TARGET).gz
	qemu-system-arm \
		$(QEMU_OPTIONS) \
		-append "console=ttyAMA0 earlyprink=ttyAMA0 $(CMDLINE) INITRD_DEBUG=$(INITRD_DEBUG)" \
		-kernel ./vmlinuz \
		-initrd ./initrd-Linux-$(TARGET).gz \
		-nographic -monitor null

qemu-live-btrfs-text:	vmlinuz initrd-Linux-$(TARGET).gz armdisk.img
	qemu-system-arm \
		$(QEMU_OPTIONS) \
		-append "console=ttyAMA0 earlyprink=ttyAMA0 ip=dhcp root=/dev/sda boot=live live_mkfs=btrfs nousb noplymouth INITRD_POST_SHELL=1" \
		-kernel ./vmlinuz -drive file=armdisk.img,format=raw \
		-initrd ./initrd-Linux-$(TARGET).gz \
		-nographic -monitor null


qemu-local-vga:	vmlinuz initrd-Linux-$(TARGET).gz
	qemu-system-arm \
		$(QEMU_OPTIONS) \
		-append "$(CMDLINE)  INITRD_DEBUG=$(INITRD_DEBUG)" \
		-kernel ./vmlinuz \
		-initrd ./initrd-Linux-$(TARGET).gz \
		-monitor stdio


qemu-docker qemu-docker-text:	vmlinuz initrd-Linux-$(TARGET).gz
	cd qemu; -docker-compose kill metadata
	cd qemu; docker-compose run initrd /bin/bash -xc ' \
		qemu-system-arm \
		  -net nic -net user \
		  $(QEMU_OPTIONS) \
		  -append "console=ttyAMA0 earlyprink=ttyAMA0 $(CMDLINE) INITRD_DEBUG=$(INITRD_DEBUG) METADATA_IP=$$METADATA_PORT_80_TCP_ADDR" \
		  -kernel /boot/vmlinuz \
		  -initrd /boot/initrd-Linux-$(TARGET).gz \
		  -nographic -monitor null \
		'


qemu-docker-rescue:	metadata_mock/static/minirootfs.tar
	$(MAKE) qemu-docker-text CMDLINE='boot=rescue rescue_image=http://metadata.local/static/$(shell basename $<)'


publish_on_s3:	$(PUBLISH_FILES)
	for file in $(PUBLISH_FILES); do \
	  s3cmd put --acl-public $$file $(S3_TARGET); \
	done


publish_on_store: $(PUBLISH_FILES)
	rsync -avze ssh $(PUBLISH_FILES) $(STORE_TARGET)


publish_on_store_ftp: $(PUBLISH_FILES)
	for file in $(PUBLISH_FILES); do \
	  curl -T "$$file" --netrc ftp://$(STORE_HOSTNAME)/initrds/; \
	done

publish_on_store_sftp: $(PUBLISH_FILES)
	for file in $(PUBLISH_FILES); do \
	  lftp -u $(STORE_USERNAME) -p 2222 sftp://$(STORE_HOSTNAME) -e "cd store/initrds; put $$file; bye"; \
	done


dist:
	$(MAKE) dist_do || $(MAKE) dist_teardown


dist_do:
	-git branch -D dist-Linux-$(TARGET) || true
	git checkout -b dist-Linux-$(TARGET)
	-$(MAKE) dependencies-$(TARGET).tar.gz && git add -f dependencies-$(TARGET).tar.gz
	-$(MAKE) uInitrd-Linux-$(TARGET) && git add -f uInitrd-Linux-$(TARGET) initrd-Linux-$(TARGET).gz output-$(TARGET)
	git commit -am ":ship: dist"
	git push -u $(GIT_REMOTE) dist-Linux-$(TARGET) -f
	$(MAKE) dist_teardown


dist_teardown:
	git checkout master


# Files
vmlinuz:
	-rm -f $@ $@.tmp
	wget -O $@.tmp $(KERNEL_URL)
	mv $@.tmp $@


uInitrd:	uInitrd-Linux-$(TARGET)


uInitrd-Linux-$(TARGET):	initrd-Linux-$(TARGET).gz
	$(MAKE) uInitrd-local || $(MAKE) uInitrd-docker


uInitrd-local:	initrd-Linux-$(TARGET).gz
	mkimage $(MKIMAGE_OPTS) -d initrd-Linux-$(TARGET).gz uInitrd-Linux-$(TARGET)
	touch uInitrd-Linux-$(TARGET)


uInitrd-docker:	initrd-Linux-$(TARGET).gz
	docker run \
		-it --rm \
		-v $(PWD):/host \
		-w /tmp \
		moul/u-boot-tools \
		/bin/bash -xec \
		' \
		  cp /host/initrd-Linux-$(TARGET).gz . && \
		  mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs -d ./initrd-Linux-$(TARGET).gz ./uInitrd && \
		  cp uInitrd /host/ \
		'
	@sudo chown $(USER) uInitrd || true
	mv uInitrd uInitrd-Linux-$(TARGET)
	@touch uInitrd-Linux-$(TARGET) || true


uInitrd-shell: output-$(TARGET)/.deps
	test $(HOST_ARCH) = $(TARGET)
	docker run \
		-it --rm \
		-v $(PWD)/output-$(TARGET):/chroot \
		-w /tmp \
		armbuild/busybox \
		chroot /chroot /bin/sh


output-$(TARGET)/usr/bin/oc-metadata:
	mkdir -p $(shell dirname $@)


initrd.gz:	initrd-Linux-$(TARGET).gz


initrd-Linux-$(TARGET).gz:	output-$(TARGET)/.clean
	cd output-$(TARGET) && find . -print0 | cpio --null -o --format=newc | gzip -9 > $(PWD)/$@


output-$(TARGET)/.deps:	dependencies-$(TARGET).tar.gz tree-$(TARGET)/usr/sbin/xnbd-client tree-$(TARGET) tree-$(TARGET)/usr/bin/oc-metadata Makefile $(shell find tree-$(TARGET) -type f) $(shell find tree-common -type f)
	rm -rf output-$(TARGET)
	mkdir -p output-$(TARGET)
	tar -m -C output-$(TARGET)/ -xzf dependencies-$(TARGET).tar.gz
	rsync -az tree-common/ output-$(TARGET)
	rsync -az tree-$(TARGET)/ output-$(TARGET)
	touch $@


output-$(TARGET)/.clean: output-$(TARGET)/.deps
	find output-$(TARGET) \( -name "*~" -or -name ".??*~" -or -name "#*#" -or -name ".#*" \) -delete
	sed 's/INITRD_BUILD_COMMIT/$(shell git describe --long --tags)/' output-$(TARGET)/init > output-$(TARGET)/init.tmp
	sed 's@INITRD_BUILD_DATE@$(shell TZ=Europe/Paris date "+%Y/%m/%d")@' output-$(TARGET)/init.tmp > output-$(TARGET)/init
	rm -f output-$(TARGET)/init.tmp
	touch $@


tree-$(TARGET):
	mkdir -p $@


tree-$(TARGET)/usr/bin/oc-metadata:
	mkdir -p tree-$(TARGET)/usr/bin
	wget https://raw.githubusercontent.com/scaleway/image-tools/master/skeleton-common/usr/local/bin/oc-metadata -O $@
	chmod +x $@


tree-$(TARGET)/usr/sbin/xnbd-client:
	mkdir -p tree-$(TARGET)/usr/sbin
	wget https://github.com/aimxhaisse/xnbd-client-static/raw/dist/bin/xnbd-client-static -O $@
	chmod +x $@
	ln -sf xnbd-client tree-$(TARGET)/usr/sbin/@xnbd-client


dependencies.tar.gz:	dependencies-$(TARGET).tar.gz


dependencies-$(TARGET).tar.gz:	dependencies-$(TARGET)/Dockerfile
	test $(HOST_ARCH) = $(TARGET) || docker run --rm --privileged multiarch/qemu-user-static:register --reset

	docker build -q -t $(DOCKER_DEPENDENCIES) ./dependencies-$(TARGET)/
	docker run -it $(DOCKER_DEPENDENCIES) export-assets $(DEPENDENCIES)
	docker cp `docker ps -lq`:/tmp/dependencies.tar $(PWD)/
	mv dependencies.tar dependencies-$(TARGET).tar
	(cd ../scw-boot-tools; tar -uf ../Linux/dependencies-$(TARGET).tar usr/bin/scw-update-server-state)
	docker rm `docker ps -lq`
	rm -f dependencies-$(TARGET).tar.gz
	@ls -lah dependencies-$(TARGET).tar
	gzip dependencies-$(TARGET).tar
	@ls -lah dependencies-$(TARGET).tar.gz

	tar tvzf $@ | grep bin/busybox || rm -f $@
	@test -f $@ || echo $@ is broken
	@test -f $@ || exit 1


dependencies-shell:
	test $(HOST_ARCH) = $(TARGET)
	docker build -q -t $(DOCKER_DEPENDENCIES) ./dependencies-$(TARGET)/
	docker run -it $(DOCKER_DEPENDENCIES) /bin/bash


../scw-boot-tools/usr/bin/scw-update-server-state: ../scw-boot-tools/scw-update-server-state.c
	make -C ../scw-boot-tools
	mkdir -p ../scw-boot-tools/usr/bin
	cp ../scw-boot-tools/scw-update-server-state ../scw-boot-tools/usr/bin/
	chmod +x ../scw-boot-tools/usr/bin/scw-update-server-state


minirootfs:
	rm -rf $@ $@.tmp export.tar
	docker rm initrd-minirootfs 2>/dev/null || true
	docker run --name initrd-minirootfs --entrypoint /donotexists armbuild/busybox 2>&1 | grep -v "stat /donotexists: no such file" || true
	docker export initrd-minirootfs > export.tar
	docker rm initrd-minirootfs
	mkdir -p $@.tmp
	tar -C $@.tmp -xf export.tar
	rm -f $@.tmp/.dockerenv $@.tmp/.dockerinit
	-chmod 1777 $@.tmp/tmp
	-chmod 755 $@.tmp/etc $@.tmp/usr $@.tmp/usr/local $@.tmp/usr/sbin
	-chmod 555 $@.tmp/sys
	#echo 127.0.1.1       server >> $@.tmp/etc/hosts
	#echo 127.0.0.1       localhost server >> $@.tmp/etc/hosts
	#echo ::1             localhost ip6-localhost ip6-loopback >> $@.tmp/etc/hosts
	#echo ff02::1         ip6-allnodes >> $@.tmp/etc/hosts
	#echo ff02::2         ip6-allrouters >> $@.tmp/etc/hosts
	mv $@.tmp $@


metadata_mock/static/minirootfs.tar:	minirootfs.tar
	mkdir -p $(shell dirname $@)
	cp $< $@


minirootfs.tar:	minirootfs
	tar --format=gnu -C $< -cf $@.tmp . 2>/dev/null || tar --format=pax -C $< -cf $@.tmp . 2>/dev/null
	mv $@.tmp $@
