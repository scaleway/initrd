S3_TARGET ?=		s3://$(shell whoami)/
STORE_HOSTNAME ?=	store.scw.42.am
STORE_TARGET ?=		$(STORE_HOSTNAME):store/initrds/
KERNEL_URL ?=		http://ports.ubuntu.com/ubuntu-ports/dists/lucid/main/installer-armel/current/images/versatile/netboot/vmlinuz
MKIMAGE_OPTS ?=		-A arm -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs
DOCKER_DEPENDENCIES ?=	armbuild/initrd-dependencies
CMDLINE ?=		ip=dhcp root=/dev/nbd0 nbd.max_parts=8 boot=local nousb noplymouth
QEMU_OPTIONS ?=		-M versatilepb -cpu cortex-a9 -m 256 -no-reboot
INITRD_DEBUG ?=		0
HOST_ARCH ?=		$(shell uname -m)
TARGET ?=		$(HOST_ARCH)
COMMIT :=		$(shell git rev-parse HEAD)
TAG :=			$(shell git describe --tags --always)
PUBLISH_FILES ?=	uInitrd-Linux-$(TARGET)-$(TAG) initrd-Linux-$(TARGET)-$(TAG).gz uInitrd-Linux-$(TARGET)-latest initrd-Linux-$(TARGET)-latest.gz
GIT_REMOTE ?=		origin

ifeq ($(TARGET),arm)
	TARGET_QEMU_ARCH=arm
	TARGET_UNAME_ARCH=armv7l
	TARGET_DOCKER_TAG_ARCH=armhf
	TARGET_GOLANG_ARCH=arm
endif
ifeq ($(TARGET),armhf)
	TARGET_QEMU_ARCH=arm
	TARGET_UNAME_ARCH=armv7l
	TARGET_DOCKER_TAG_ARCH=armhf
	TARGET_GOLANG_ARCH=arm
endif
ifeq ($(TARGET),armv7l)
	TARGET_QEMU_ARCH=arm
	TARGET_UNAME_ARCH=armv7l
	TARGET_DOCKER_TAG_ARCH=armhf
	TARGET_GOLANG_ARCH=arm
endif
ifeq ($(TARGET),arm64)
	TARGET_QEMU_ARCH=aarch64
	TARGET_UNAME_ARCH=arm64
	TARGET_DOCKER_TAG_ARCH=arm64
	TARGET_GOLANG_ARCH=arm64
endif
ifeq ($(TARGET),x86_64)
	TARGET_QEMU_ARCH=x86_64
	TARGET_UNAME_ARCH=x86_64
	TARGET_DOCKER_TAG_ARCH=amd64
	TARGET_GOLANG_ARCH=amd64
endif
ifeq ($(TARGET),amd64)
	TARGET_QEMU_ARCH=x86_64
	TARGET_UNAME_ARCH=x86_64
	TARGET_DOCKER_TAG_ARCH=amd64
	TARGET_GOLANG_ARCH=amd64
endif
ifeq ($(TARGET),mips)
	TARGET_QEMU_ARCH=mips
	TARGET_UNAME_ARCH=mips
	TARGET_DOCKER_TAG_ARCH=mips
	TARGET_GOLANG_ARCH=unsupported
endif
ifeq ($(TARGET),powerpc)
	TARGET_QEMU_ARCH=powerpc
	TARGET_UNAME_ARCH=powerpc
	TARGET_DOCKER_TAG_ARCH=powerpc
	TARGET_GOLANG_ARCH=unsupported
endif


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
	bash -n tree-common/init tree-common/shutdown tree-common/functions.sh tree-common/boot-*


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


uInitrd-Linux-$(TARGET)-latest initrd-Linux-$(TARGET)-latest.gz: uInitrd-Linux-$(TARGET)-$(TAG) initrd-Linux-$(TARGET)-$(TAG).gz
	ln -sf uInitrd-Linux-$(TARGET)-$(TAG) uInitrd-Linux-$(TARGET)-latest
	ln -sf initrd-Linux-$(TARGET)-$(TAG).gz initrd-Linux-$(TARGET)-latest.gz


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
	-$(MAKE) dependencies-$(TARGET).tar && git add -f dependencies-$(TARGET).tar
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
		-v $(shell pwd):/host \
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
		-v $(shell pwd)/output-$(TARGET):/chroot \
		-w /tmp \
		multiarch/busybox:$(TARGET_DOCKER_TAG_ARCH) \
		chroot /chroot /bin/sh


initrd.gz:	initrd-Linux-$(TARGET).gz


initrd-Linux-$(TARGET).gz:	output-$(TARGET)/.clean
	cd output-$(TARGET) && find . -print0 | cpio --null -o --format=newc | gzip -9 > $(shell pwd)/$@


output-$(TARGET)/.deps:	dependencies-$(TARGET).tar tree-$(TARGET) Makefile $(shell find tree-$(TARGET) -type f) $(shell find tree-common -type f)
	rm -rf output-$(TARGET)
	mkdir -p output-$(TARGET)
	tar -m -C output-$(TARGET)/ -xf dependencies-$(TARGET).tar
	rsync -az tree-common/ output-$(TARGET)
	rsync -az tree-$(TARGET)/ output-$(TARGET)
	touch $@


output-$(TARGET)/.clean: output-$(TARGET)/.deps
	find output-$(TARGET) \( -name "*~" -or -name ".??*~" -or -name "#*#" -or -name ".#*" \) -delete
	sed 's/INITRD_BUILD_COMMIT/$(shell git describe --long --tags)/' output-$(TARGET)/init > output-$(TARGET)/init.tmp
	sed 's@INITRD_BUILD_DATE@$(shell TZ=Europe/Paris date "+%Y/%m/%d")@' output-$(TARGET)/init.tmp > output-$(TARGET)/init
	echo "INITRD_BUILD_COMMIT=$(shell git describe --long --tags)" > output-$(TARGET)/version
	echo "INITRD_BUILD_DATE=$(shell TZ=Europe/Paris date '+%Y/%m/%d')" >> output-$(TARGET)/version
	rm -f output-$(TARGET)/init.tmp
	touch $@


tree-$(TARGET):
	mkdir -p $@


dependencies.tar:	dependencies-$(TARGET).tar


dependencies-$(TARGET).tar:	dependencies-$(TARGET)/Dockerfile dependencies-$(TARGET)/tmp/scw-update-server-state dependencies-scripts
	test $(HOST_ARCH) = $(TARGET) || docker run --rm --privileged multiarch/qemu-user-static:register --reset

	docker build -t $(DOCKER_DEPENDENCIES) ./dependencies-$(TARGET)/
	docker run --rm $(DOCKER_DEPENDENCIES) > $@


dependencies-shell:
	test $(HOST_ARCH) = $(TARGET)
	docker build -q -t $(DOCKER_DEPENDENCIES) ./dependencies-$(TARGET)/
	docker run -it $(DOCKER_DEPENDENCIES) /bin/bash


dependencies-$(TARGET)/tmp/scw-update-server-state: ../scw-boot-tools/scw-update-server-state.c
	make -C ../scw-boot-tools TARGET=$(TARGET)
	mkdir -p ../scw-boot-tools/$(TARGET)/usr/bin
	mkdir -p $(shell dirname $@)
	cp ../scw-boot-tools/$(TARGET)-scw-update-server-state $@
	chmod +x $@


dependencies-scripts: dependencies-$(TARGET)/tmp/ldd-rec.pl dependencies-$(TARGET)/tmp/export-assets


dependencies-$(TARGET)/tmp/ldd-rec.pl: ../scripts/ldd-rec.pl
	cp $^ $@
	chmod +x $@


dependencies-$(TARGET)/tmp/export-assets: ../scripts/export-assets
	cp $^ $@
	chmod +x $@


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


clean:
	rm -rf output-$(TARGET) dependencies-$(TARGET).tar initrd-Linux-$(TARGET).gz uInitrd-Linux-$(TARGET)


re: clean all
