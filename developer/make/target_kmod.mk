# make/targets_kmod.mk
# make a Linux kernel module

ifndef REPO_HOME
  $(error REPO_HOME is not set; build must be done in a project environment)
endif

KBUILD_BASE_List := $(basename $(notdir $(wildcard $(REPO_HOME)/developer/cc/*.mod.c)))
KMOD_BUILD_DPath := /lib/modules/$(shell uname -r)/build
KBUILD_OUTPUT_DIR := $(SCRATCHPAD)

# Basenames → kbuild objects and final .ko targets in scratchpad
KERNEL_OBJS_M          := $(addsuffix .o, $(KBUILD_BASE_List))
KMOD_TARGETS  := $(addsuffix .ko, $(addprefix $(KBUILD_OUTPUT_DIR)/, $(KBUILD_BASE_List)))

.PHONY: usage
usage:
	@printf "Usage: make [usage|kmod|clean]\n"; exit 2

# Build every module
.PHONY: kmod
kmod: $(KMOD_TARGETS)

# Link each module via kbuild (M points at project root)
$(KBUILD_OUTPUT_DIR)/%.ko: $(KBUILD_OUTPUT_DIR)/%.c
	@echo "--- Invoking Kbuild for Module: $* ---"
	$(MAKE) -C $(KMOD_BUILD_DPath) M=$(REPO_HOME) O=$(KBUILD_OUTPUT_DIR) obj-m=$*.o

# Prepare kbuild-compatible .c in scratchpad from authored .mod.c in developer/cc
$(KBUILD_OUTPUT_DIR)/%.c: $(REPO_HOME)/developer/cc/%.mod.c
	@echo "--- Preparing Kbuild Source: $@ ---"
	cp $< $@

# Clean kbuild artifacts (confined to scratchpad)
.PHONY: clean
clean:
	@echo "--- Cleaning Kbuild Artifacts in $(KBUILD_OUTPUT_DIR) ---"
	$(MAKE) -C $(KMOD_BUILD_DPath) M=$(REPO_HOME) O=$(KBUILD_OUTPUT_DIR) obj-m="$(KERNEL_OBJS_M)" clean
