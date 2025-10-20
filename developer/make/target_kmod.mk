.SUFFIXES:
# make/target_kmod.mk — build *.kmod.c as kernel modules
# written for the Harmony skeleton, always invoked from cwd  $REPO_HOME/<role>

SOURCE_DIR  := cc
BUILD_DIR   := /lib/modules/$(shell uname -r)/build

# must be an absolute path
OUTPUT_DIR  := $(abspath scratchpad/kmod)

# authored module basenames (without .kmod.c)
BASE_LIST   := $(patsubst %.kmod.c,%,$(notdir $(wildcard cc/*.kmod.c)))

# paths in scratchpad/kmod
C_SOURCE_LIST     := $(addsuffix .c,$(addprefix $(OUTPUT_DIR)/,$(BASE_LIST)))
TARGET_LIST       := $(addsuffix .ko,$(addprefix $(OUTPUT_DIR)/,$(BASE_LIST)))

.PHONY: usage
usage:
	@printf "Usage: make [kmod|clean]\n"

.PHONY: version 
version:
	@echo target_kmod version 1.0

.PHONY: information
information:
	@echo "SOURCE_DIR: " $(SOURCE_DIR)
	@echo "BUILD_DIR: " $(BUILD_DIR)
	@echo "OUTPUT_DIR: " $(OUTPUT_DIR)
	@echo "BASE_LIST: " $(BASE_LIST)
	@echo "C_SOURCE_LIST: " $(C_SOURCE_LIST)
	@echo "TARGET_LIST: " $(TARGET_LIST)


.PHONY: kmod
kmod: _prepare $(TARGET_LIST)

.PHONY: _prepare
_prepare:
	@mkdir -p $(OUTPUT_DIR)
	@printf "obj-m := %s\n" "$(foreach m,$(BASE_LIST),$(m).o)" > $(OUTPUT_DIR)/Makefile

# copy authored .kmod.c → scratchpad/kmod/*.c (Kbuild expects sources under M)
$(OUTPUT_DIR)/%.c: $(SOURCE_DIR)/%.kmod.c | _prepare
	@echo "--- Preparing Kbuild Source: $@ ---"
	cp $< $@

# build .ko via kernel Kbuild (the 'modules' target drives the build)
$(OUTPUT_DIR)/%.ko: $(OUTPUT_DIR)/%.c $(OUTPUT_DIR)/Makefile
	@echo "--- Invoking Kbuild for Module: $* ---"
	$(MAKE) -C $(BUILD_DIR) M=$(OUTPUT_DIR) modules

.PHONY: clean
clean:
	@if [ -d "$(OUTPUT_DIR)" ]; then \
	  echo "--- Cleaning Kbuild Artifacts in $(OUTPUT_DIR) ---"; \
	  $(MAKE) -C $(BUILD_DIR) M=$(OUTPUT_DIR) clean; \
	fi

-----
# add this near BASE_LIST
ALL_C := $(addsuffix .c,$(addprefix $(OUTPUT_DIR)/,$(BASE_LIST)))

.PHONY: kmod
# build everything in one go
kmod: _prepare modules

.PHONY: _prepare
_prepare:
	@mkdir -p $(OUTPUT_DIR)
	@printf "obj-m := %s\n" "$(foreach m,$(BASE_LIST),$(m).o)" > $(OUTPUT_DIR)/Makefile
	@for b in $(BASE_LIST); do \
	  src="$(SOURCE_DIR)/$$b.kmod.c"; dst="$(OUTPUT_DIR)/$$b.c"; \
	  echo "--- Preparing Kbuild Source: $$dst ---"; \
	  ln -s $$src $$dst; \
	done

.PHONY: modules
modules: $(OUTPUT_DIR)/Makefile $(ALL_C)
	@echo "--- Invoking Kbuild for Modules: $(BASE_LIST) ---"
	$(MAKE) -C $(BUILD_DIR) M=$(OUTPUT_DIR) modules

# optional: keep these as no-ops so 'make …/foo.ko' still succeeds
$(OUTPUT_DIR)/%.ko: modules
	@true
