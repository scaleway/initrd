TARGET =	Openbsd-armv7
S3_TARGET ?=	s3://root/
DEPENDENCIES =	/usr/local/sbin/xnbd-client


all: uInitrd-Openbsd-armv7


output-Openbsd-armv7/.clean: output-Openbsd-armv7/.deps $(wildcard output-%(TARGET)/*)
	find output-Openbsd-armv7 \( -name "*~" -or -name ".??*~" -or -name "#*#" -or -name ".#*" \) -exec rm {} \;
	touch output-Openbsd-armv7/.clean


initrd-Openbsd-armv7.pax: output-Openbsd-armv7/.clean
	cd output-Openbsd-armv7 && pax -w -f ../$@ -x tmpfs * .??*


../scw-boot-tools/scw-update-server-state: ../scw-boot-tools/scw-update-server-state.c
	$(MAKE) -C ../scw-boot-tools


output-Openbsd-armv7/.deps: miniroot-Openbsd-armv7.tar.gz dependencies-Openbsd-armv7.tar.gz ../scw-boot-tools/scw-update-server-state
	rm -rf output-Openbsd-armv7
	mkdir -p output-Openbsd-armv7
	tar -m -C output-Openbsd-armv7/ -xzf miniroot-Openbsd-armv7.tar.gz
	tar -m -C output-Openbsd-armv7/ -xzf dependencies-Openbsd-armv7.tar.gz
	rsync -az tree-Openbsd-armv7/ output-Openbsd-armv7
	cp ../scw-boot-tools/scw-update-server-state output-Openbsd-armv7/usr/bin/
	chmod +x output-Openbsd-armv7/usr/bin/scw-*
	rm -f output-Openbsd-armv7/dev/null
	touch output-Openbsd-armv7/.deps


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


.PHONY: travis
travis:
	bash -n dependencies-Openbsd-armv7/export-assets


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
