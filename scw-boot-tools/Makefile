NAME = scw-update-server-state
LDFLAGS = -static -lm
HOST_ARCH ?= $(shell uname -m)
TARGET ?= armv7l

all: build


$(TARGET)-$(NAME): scw-update-server-state.c
	if [ -n "$(CROSS_TRIPLE)" ]; then             \
	  crossbuild cc $< -o $@ $(LDFLAGS);          \
	  file $@ || true;                            \
	else                                          \
	  if [ "$(HOST_ARCH)" = "$(TARGET)" ]; then   \
	    cc $< -o $@ $(LDFLAGS);                   \
	    file $@ || true;                          \
	  else                                        \
	    $(MAKE) docker_build;                     \
	  fi;                                         \
	fi


.PHONY: build
build: $(TARGET)-$(NAME)


.PHONY: local_build
local_build: scw-update-server-state.c


.PHONY: clean
clean:
	rm -f *-$(NAME)


.PHONY: re
re: clean all


.PHONY: travis_check
travis_check:
	@echo "travis_check: nothing to do."


.PHONY: travis_build
travis_build: build


.PHONY: docker_build
docker_build:
	docker run --rm -it -e TARGET=$(TARGET) -e CROSS_TRIPLE=$(TARGET) -v $(shell pwd):/workdir multiarch/crossbuild make
