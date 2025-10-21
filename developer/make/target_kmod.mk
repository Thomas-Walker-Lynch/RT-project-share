.SUFFIXES:
# make/target_kmod.mk — build *.kmod.c as kernel modules (single-pass, kmod-only)
# invoked from $REPO_HOME/<role>
# version 1.2

SOURCE_DIR  := cc
BUILD_DIR   := /lib/modules/$(shell uname -r)/build
# Isolate per-kernel output (safe) or collapse to 'scratchpad/kmod' (simpler)
OUTPUT_DIR  := $(abspath scratchpad/kmod/$(shell uname -r))

# authored module basenames (without .kmod.c) — kmod-only
BASE_LIST   := $(patsubst %.kmod.c,%,$(notdir $(wildcard $(SOURCE_DIR)/*.kmod.c)))

# prepared sources under OUTPUT_DIR (Kbuild expects sources under M)
ALL_C       := $(addsuffix .c,$(addprefix $(OUTPUT_DIR)/,$(BASE_LIST)))

.PHONY: usage
usage:
	@printf "Usage: make [kmod|clean|information|version]\n"

.PHONY: version
version:
	@echo target_kmod version 1.2

.PHONY: information
information:
	@echo "SOURCE_DIR:   " $(SOURCE_DIR)
	@echo "BUILD_DIR:    " $(BUILD_DIR)
	@echo "OUTPUT_DIR:   " $(OUTPUT_DIR)
	@echo "BASE_LIST:    " $(BASE_LIST)
	@echo "ALL_C:        " $(ALL_C)

# guard: fail early if no kmod sources (prevents confusing empty builds)
ifndef BASE_LIST
$(warning No *.kmod.c found under $(SOURCE_DIR); nothing to build)
endif

.PHONY: kmod
kmod: _prepare modules

.PHONY: _prepare
_prepare:
	@mkdir -p $(OUTPUT_DIR)
	# purge any non-kmod staged *.c to avoid accidental pickup
	@find "$(OUTPUT_DIR)" -maxdepth 1 -type f -name '*.c' ! -name '*.tmp' -delete 2>/dev/null || true
	# declare exactly which modules to build
	@printf "obj-m := %s\n" "$(foreach m,$(BASE_LIST),$(m).o)" > "$(OUTPUT_DIR)/Makefile"
	# stage only kmod sources (symlink preferred; fallback to copy)
	@for b in $(BASE_LIST); do \
	  src="$(SOURCE_DIR)/$$b.kmod.c"; dst="$(OUTPUT_DIR)/$$b.c"; \
	  echo "--- Preparing Kbuild Source: $$dst ---"; \
	  ln -sf "$$src" "$$dst" 2>/dev/null || cp "$$src" "$$dst"; \
	done

.PHONY: modules
modules: $(OUTPUT_DIR)/Makefile $(ALL_C)
	@echo "--- Invoking Kbuild for Modules: $(BASE_LIST) ---"
	$(MAKE) -C "$(BUILD_DIR)" M="$(OUTPUT_DIR)" modules

# Allow 'make scratchpad/kmod/.../foo.ko' after batch build
$(OUTPUT_DIR)/%.ko: modules
	@true

.PHONY: clean
clean:
	@if [ -d "$(OUTPUT_DIR)" ]; then \
	  echo "--- Cleaning Kbuild Artifacts in $(OUTPUT_DIR) ---"; \
	  $(MAKE) -C "$(BUILD_DIR)" M="$(OUTPUT_DIR)" clean; \
	  find "$(OUTPUT_DIR)" -maxdepth 1 -type l -name '*.c' -delete 2>/dev/null || true; \
	  find "$(OUTPUT_DIR)" -maxdepth 1 -type f -name '*.c' -delete 2>/dev/null || true; \
	fi
