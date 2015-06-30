# Editable variables
S3_TARGET ?=		s3://$(shell whoami)/
INITRD_DEBUG ?=		0
#TARGETS ?=	Linux-armv7l Openbsd-armv7
TARGETS ?=	Linux-armv7l


# Internal
HOST_ARCH =		$(shell uname -m)
PROXIFIED_COMMANDS =	uInitrd travis publish_on_s3 dist


all:	uInitrd


.PHONY: $(PROXIFIED_COMMANDS)


travis::
	@echo "[+] Checking Makefiles syntax"
	for file in Makefile *.mk; do make -n -f $$file &>/dev/null; done


$(PROXIFIED_COMMANDS)::
	@for target in $(TARGETS); do \
		echo "[+] make -f rules-$$target.mk $@"; \
		$(MAKE) -f rules-$$target.mk $@; \
	done
