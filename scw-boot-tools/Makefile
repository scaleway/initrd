NAME = scw-update-server-state
LDFLAGS = -static -lm

all: build


$(NAME): scw-update-server-state.c
	cc $< -o $@ $(LDFLAGS)


.PHONY: build
build: $(NAME)


.PHONY: clean
clean:
	rm -f $(NAME)


.PHONY: re
re: clean all


.PHONY: travis_check travis_build
travis_check travis_build: build_with_fallback


.PHONY: build_with_fallback
build_with_fallback:
	$(MAKE) build || $(MAKE) docker_build


.PHONY: docker_build
docker_build:
	docker build -t $(NAME)-builder .
	docker run --rm $(NAME)-builder > $(NAME)
	chmod +x $(NAME)
