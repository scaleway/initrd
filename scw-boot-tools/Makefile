NAME = scw-update-server-state
LDFLAGS = -static

all: $(NAME)

.PHONY: clean
clean:
	rm -f $(NAME)

.PHONY: re
re: clean all

.PHONY: travis_check travis_build
travis_check travis_build: all
