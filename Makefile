VER := 1
TAG := starlabio/docker-kernel-fuzz:$(VER)

.PHONY: all build
all build:
	docker build . --tag $(TAG)

docker-shell: DOCKER_IMAGE := $(TAG)
shell: DOCKER_IMAGE := $(TAG)

docker-shell shell:
	$(DOCKER_SHELL_CMD)

include Docker.mk
