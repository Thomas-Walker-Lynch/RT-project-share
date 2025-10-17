.SUFFIXES:
# make/target_kmod.mk — build *.kmod.c as kernel modules
# written for the Harmony skeleton, always invoked from cwd  $REPO_HOME/<role>

SOURCE_DIR  := cc
BUILD_DIR   := /lib/modules/$(shell uname -r)/build
OUTPUT_DIR  := scratchpad/kmod

# authored module basenames (without .mod.c)
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

.PHONY: information,info
info:
information:
	@printf "· → Unicode middle dot — visible: [%b]\n" "·"
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

# copy authored .mod.c → scratchpad/kmod/*.c (Kbuild expects sources under M)
$(OUTPUT_DIR)/%.c: $(SOURCE_DIR)/%.mod.c | _prepare
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

