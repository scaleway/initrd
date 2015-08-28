TARGET =	Openbsd-armv7
S3_TARGET ?=	s3://root/
DEPENDENCIES =	/usr/local/sbin/xnbd-client /usr/sbin/ntpd


all: uInitrd-Openbsd-armv7


output-Openbsd-armv7/.clean: output-Openbsd-armv7/.deps $(wildcard output-%(TARGET)/*)
	find output-Openbsd-armv7 \( -name "*~" -or -name ".??*~" -or -name "#*#" -or -name ".#*" \) -exec rm {} \;
	touch output-Openbsd-armv7/.clean


initrd-Openbsd-armv7.pax: output-Openbsd-armv7/.clean
	cd output-Openbsd-armv7 && pax -w -f ../$@ -x tmpfs * .??*


../scw-boot-tools/scw-update-server-state: ../scw-boot-tools/scw-update-server-state.c
	$(MAKE) -C ../scw-boot-tools


output-Openbsd-armv7/.deps: miniroot-Openbsd-armv7.tar.gz dependencies-Openbsd-armv7.tar.gz ../scw-boot-tools/scw-update-server-state tree-Openbsd-armv7/.profile tree-Openbsd-armv7/usr/bin/oc-metadata
	rm -rf output-Openbsd-armv7
	mkdir -p output-Openbsd-armv7
	tar -m -C output-Openbsd-armv7/ -xzf miniroot-Openbsd-armv7.tar.gz
	tar -m -C output-Openbsd-armv7/ -xzf dependencies-Openbsd-armv7.tar.gz
	rsync -az tree-Openbsd-armv7/ output-Openbsd-armv7
	cp ../scw-boot-tools/scw-update-server-state output-Openbsd-armv7/usr/bin/
	mv output-Openbsd-armv7/usr/local/lib/* output-Openbsd-armv7/usr/lib/
	chmod +x output-Openbsd-armv7/usr/bin/scw-*
	mknod output-Openbsd-armv7/dev/nbd0a b 21 0
	mknod output-Openbsd-armv7/dev/nbd0b b 21 1
	mknod output-Openbsd-armv7/dev/nbd0c b 21 2
	mknod output-Openbsd-armv7/dev/nbd0d b 21 3
	mknod output-Openbsd-armv7/dev/nbd0e b 21 4
	mknod output-Openbsd-armv7/dev/nbd0f b 21 5
	mknod output-Openbsd-armv7/dev/nbd0g b 21 6
	mknod output-Openbsd-armv7/dev/nbd0h b 21 7
	mknod output-Openbsd-armv7/dev/nbd0i b 21 8
	mknod output-Openbsd-armv7/dev/nbd0j b 21 9
	mknod output-Openbsd-armv7/dev/nbd0k b 21 10
	mknod output-Openbsd-armv7/dev/nbd0l b 21 11
	mknod output-Openbsd-armv7/dev/nbd0m b 21 12
	mknod output-Openbsd-armv7/dev/nbd0n b 21 13
	mknod output-Openbsd-armv7/dev/nbd0o b 21 14
	mknod output-Openbsd-armv7/dev/nbd0p b 21 15
	mknod output-Openbsd-armv7/dev/rnbd0a c 21 0
	mknod output-Openbsd-armv7/dev/rnbd0b c 21 1
	mknod output-Openbsd-armv7/dev/rnbd0c c 21 2
	mknod output-Openbsd-armv7/dev/rnbd0d c 21 3
	mknod output-Openbsd-armv7/dev/rnbd0e c 21 4
	mknod output-Openbsd-armv7/dev/rnbd0f c 21 5
	mknod output-Openbsd-armv7/dev/rnbd0g c 21 6
	mknod output-Openbsd-armv7/dev/rnbd0h c 21 7
	mknod output-Openbsd-armv7/dev/rnbd0i c 21 8
	mknod output-Openbsd-armv7/dev/rnbd0j c 21 9
	mknod output-Openbsd-armv7/dev/rnbd0k c 21 10
	mknod output-Openbsd-armv7/dev/rnbd0l c 21 11
	mknod output-Openbsd-armv7/dev/rnbd0m c 21 12
	mknod output-Openbsd-armv7/dev/rnbd0n c 21 13
	mknod output-Openbsd-armv7/dev/rnbd0o c 21 14
	mknod output-Openbsd-armv7/dev/rnbd0p c 21 15
	touch output-Openbsd-armv7/.deps


tree-Openbsd-armv7/usr/bin/oc-metadata:
	mkdir -p tree-Openbsd-armv7/usr/bin
	ftp https://raw.githubusercontent.com/scaleway/image-tools/master/skeleton-common/usr/local/bin/oc-metadata
	mv oc-metadata $@
	chmod +x $@


miniroot-Openbsd-armv7.tar.gz: miniroot-Openbsd-armv7.fs
	rm -rf miniroot-Openbsd-armv7/
	mkdir -p miniroot-Openbsd-armv7/
	tar -C miniroot-Openbsd-armv7/ -xphf miniroot-Openbsd-armv7.fs
	tar -C miniroot-Openbsd-armv7/ -czf $@ .


miniroot-Openbsd-armv7.fs:
	# need to be run on Openbsd-armv7
	rm -f bsd.rd $@
	ftp https://www.blueri.se/bitrig/armv7/20150505/bsd.rd
	rdconfig -X bsd.rd $@


dependencies-Openbsd-armv7.tar.gz:
	# need to be run on Openbsd-armv7
	cd ./dependencies-Openbsd-armv7/ && ./export-assets $(DEPENDENCIES)
	mv /tmp/dependencies.tar dependencies-Openbsd-armv7.tar
	gzip dependencies-Openbsd-armv7.tar


.PHONY: uInitrd
uInitrd: uInitrd-Openbsd-armv7


uInitrd-Openbsd-armv7: initrd-Openbsd-armv7.pax
	mkuboot -a arm -o linux -t ramdisk initrd-Openbsd-armv7.pax $@


.PHONY: travis_check
travis_check:
	bash -n dependencies-Openbsd-armv7/export-assets


.PHONY: travis_build
	exit 0


.PHONY: publish_on_s3
publish_on_s3:  uInitrd
	s3cmd put --acl-public uInitrd-Openbsd-armv7 $(S3_TARGET)


.PHONY: dist
dist:
	$(MAKE) dist_do || $(MAKE) dist_teardown


.PHONY: dist_do
dist_do:
	-git branch -D dist-Openbsd-armv7 || true
	git checkout -b dist-Openbsd-armv7
	-$(MAKE) dependencies-Openbsd-armv7.tar.gz && git add -f dependencies-Openbsd-armv7.tar.gz
	-$(MAKE) uInitrd-Openbsd-armv7 && git add -f uInitrd-Openbsd-armv7 output-Openbsd-armv7
	git commit -am ":ship: dist"
	git push -u origin dist-Openbsd-armv7 -f
	$(MAKE) dist_teardown


.PHONY: dist_teardown
dist_teardown:
	git checkout master


clean:
	rm -f uInitrd-Openbsd-armv7 miniroot-*.{fs,tar{,.gz}} dependencies-Openbsd-armv7.tar.gz bsd.rd initrd-*.pax
	rm -rf miniroot-Openbsd-armv7 output-*
