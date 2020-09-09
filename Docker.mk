vol_mnt    = -v $(1):$(1)
vol_mnt_ro = $(call vol_mnt,$(1)):ro
map        = $(foreach f,$(2),$(call $(1),$(f)))

DOCKER_ARGS = --rm -w $(CURDIR) $(call vol_mnt,$(CURDIR))
DOCKER_ARGS += $(shell tty -s && echo "-ti")
DOCKER_ARGS += $(call map,vol_mnt_ro,/etc/passwd /etc/group)

ifeq ($(ROOT),)
    DOCKER_ARGS += -u $(shell id -u):$(shell id -g)
    DOCKER_ARGS += $(call vol_mnt_ro,$(HOME)/.ssh)
endif

DOCKER_RUN_CMD = docker run $(DOCKER_ARGS) $(DOCKER_IMAGE) $1

DOCKER_SHELL_CMD = $(call DOCKER_RUN_CMD,/bin/bash)

print-%:
	@:$(info $($*))
