TARGET =	Openbsd-armv7
DEPENDENCIES =	/usr/local/bin/bash /bin/sh /bin/mkdir /sbin/mount /bin/ln /sbin/mknod /bin/cp /usr/local/sbin/xnbd-client /usr/local/bin/curl
MAKE = 		make -f rules-$(TARGET).mk



tree-$(TARGET)/.clean: tree-$(TARGET) tree-$(TARGET)/.deps $(wildcard tree-%(TARGET)/*)
	find tree-$(TARGET) \( -name "*~" -or -name ".??*~" -or -name "#*#" -or -name ".#*" \) -exec rm {} \;


initrd-$(TARGET).pax: tree-$(TARGET)/.clean
	cd tree-$(TARGET) && pax -w -f ../$@ -x tmpfs *


tree-$(TARGET): tree
	rm -rf $@
	cp -rf tree $@


tree-$(TARGET)/.deps: dependencies-$(TARGET).tar.gz
	tar -m -C tree-$(TARGET)/ -xzf dependencies-$(TARGET).tar.gz
	rm -f tree-$(TARGET)/dev/null


dependencies-$(TARGET).tar.gz:
	# need to be run on $(TARGET)
	cd ./dependencies-$(TARGET)/ && ./export-assets $(DEPENDENCIES)
	mv /tmp/dependencies.tar dependencies-$(TARGET).tar
	gzip dependencies-$(TARGET).tar


.PHONY: uInitrd
uInitrd: uInitrd-$(TARGET)


uInitrd-$(TARGET): initrd-$(TARGET).pax
	mkuboot -a arm -o linux -t ramdisk initrd-$(TARGET).pax $@


.PHONY: travis
travis:
	bash -n dependencies-Openbsd-armv7/export-assets


.PHONY: publish_on_s3
publish_on_s3:
	@echo "not implemented"


.PHONY: dist
dist:
	$(MAKE) dist_do || $(MAKE) dist_teardown


.PHONY: dist_do
dist_do:
	-git branch -D dist-$(TARGET) || true
	git checkout -b dist-$(TARGET)
	-$(MAKE) dependencies-$(TARGET).tar.gz && git add -f dependencies-$(TARGET).tar.gz
	-$(MAKE) uInitrd-$(TARGET) && git add -f uInitrd-$(TARGET) tree-$(TARGET)
	git commit -am ":ship: dist"
	git push -u origin dist-$(TARGET) -f
	$(MAKE) dist_teardown


.PHONY: dist_teardown
dist_teardown:
	git checkout master
