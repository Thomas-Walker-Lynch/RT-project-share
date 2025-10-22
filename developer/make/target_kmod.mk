# make/target_kmod.mk — build *.kmod.c as kernel modules (single-pass, kmod-only)
# invoked from $REPO_HOME/<role>
# version 1.4

.SUFFIXES:
.EXPORT_ALL_VARIABLES:
.DELETE_ON_ERROR:

# allow overrides
KMOD_SOURCE_DIR ?= cc

# allow cross-compile override via KDIR; else default to running kernel
KDIR        ?=
BUILD_DIR   ?= $(if $(KDIR),$(KDIR),/lib/modules/$(shell uname -r)/build)

# default, then canonicalize to absolute regardless of source
OUTPUT_DIR  ?= scratchpad/kmod
OUTPUT_DIR  := $(abspath $(OUTPUT_DIR))

# authored basenames (without suffix)
BASE_LIST   := $(patsubst %.kmod.c,%,$(notdir $(wildcard $(KMOD_SOURCE_DIR)/*.kmod.c)))

# optional library sources (without suffix) to include inside modules
# set KMOD_INCLUDE_LIB=0 to disable
KMOD_INCLUDE_LIB ?= 1
ifeq ($(KMOD_INCLUDE_LIB),1)
LIB_BASE   := $(patsubst %.lib.c,%,$(notdir $(wildcard $(KMOD_SOURCE_DIR)/*.lib.c)))
else
LIB_BASE   :=
endif

# staged sources (kept namespaced to prevent .o collisions)
ALL_KMOD_C  := $(addsuffix .kmod.c,$(addprefix $(OUTPUT_DIR)/,$(BASE_LIST)))
ALL_LIB_C   := $(addsuffix .lib.c,$(addprefix $(OUTPUT_DIR)/,$(LIB_BASE)))

.PHONY: usage
usage:
	@printf "Usage: make [kmod|clean|information|version]\n"

.PHONY: version
version:
	@echo target_kmod version 1.4

.PHONY: information
information:
	@echo "KMOD_SOURCE_DIR:   " $(KMOD_SOURCE_DIR)
	@echo "BUILD_DIR:    " $(BUILD_DIR)
	@echo "OUTPUT_DIR:   " $(OUTPUT_DIR)
	@echo "BASE_LIST:    " $(BASE_LIST)
	@echo "LIB_BASE:     " $(LIB_BASE)
	@echo "ALL_KMOD_C:   " $(ALL_KMOD_C)
	@echo "ALL_LIB_C:    " $(ALL_LIB_C)
	@echo "KMOD_INCLUDE_LIB=" $(KMOD_INCLUDE_LIB)

ifndef BASE_LIST
$(warning No *.kmod.c found under $(KMOD_SOURCE_DIR); nothing to build)
endif

# --- Parallel-safe preparation as real targets ---

# ensure the staging dir exists (order-only prereq)
$(OUTPUT_DIR):
	@mkdir -p "$(OUTPUT_DIR)"

# generate the Kbuild control Makefile
$(OUTPUT_DIR)/Makefile: | $(OUTPUT_DIR)
	@{ \
	  printf "obj-m := %s\n" "$(foreach m,$(BASE_LIST),$(m).o)"; \
	  for m in $(BASE_LIST); do \
	    printf "%s-objs := %s.kmod.o" "$$m" "$$m"; \
	    for lb in $(LIB_BASE); do printf " %s.lib.o" "$$lb"; done; \
	    printf "\n"; \
	  done; \
	} > "$@"

# stage kmod sources (one rule per file; parallelizable)
$(OUTPUT_DIR)/%.kmod.c: $(KMOD_SOURCE_DIR)/%.kmod.c | $(OUTPUT_DIR)
	@echo "--- Stage: $@ ---"
	@ln -sf "$<" "$@" 2>/dev/null || { rm -f "$@"; cp "$<" "$@"; }

# stage library sources (optional; also parallelizable)
$(OUTPUT_DIR)/%.lib.c: $(KMOD_SOURCE_DIR)/%.lib.c | $(OUTPUT_DIR)
	@echo "--- Stage: $@ ---"
	@ln -sf "$<" "$@" 2>/dev/null || { rm -f "$@"; cp "$<" "$@"; }

# rebuild inputs for 'modules'
.PHONY: modules
modules: $(OUTPUT_DIR)/Makefile $(ALL_KMOD_C) $(ALL_LIB_C)
	@echo "--- Invoking Kbuild for Modules: $(BASE_LIST) ---"
	$(MAKE) -C "$(BUILD_DIR)" M="$(OUTPUT_DIR)" modules

# top-level convenience target
.PHONY: kmod
kmod: modules


# quality-of-life: allow 'make scratchpad/kmod/foo.ko' after batch build
$(OUTPUT_DIR)/%.ko: modules
	@true

.PHONY: clean
clean:
	@if [ -d "$(OUTPUT_DIR)" ]; then \
	  echo "--- Cleaning Kbuild Artifacts in $(OUTPUT_DIR) ---"; \
	  $(MAKE) -C "$(BUILD_DIR)" M="$(OUTPUT_DIR)" clean; \
	  # belt & suspenders: nuke common leftovers regardless of Kbuild's behavior
	  rm -f  "$(OUTPUT_DIR)"/*.o \
	         "$(OUTPUT_DIR)"/*.ko \
	         "$(OUTPUT_DIR)"/*.mod \
	         "$(OUTPUT_DIR)"/*.mod.c \
	         "$(OUTPUT_DIR)"/modules.order \
	         "$(OUTPUT_DIR)"/Module.symvers \
	         "$(OUTPUT_DIR)"/.*.cmd 2>/dev/null || true; \
	  rm -rf "$(OUTPUT_DIR)"/.tmp_versions 2>/dev/null || true; \
	  # remove staged sources we created (symlinks or copies)
	  find   "$(OUTPUT_DIR)" -maxdepth 1 -type l -name '*.kmod.c' -delete 2>/dev/null || true; \
	  find   "$(OUTPUT_DIR)" -maxdepth 1 -type l -name '*.lib.c'  -delete 2>/dev/null || true; \
	  find   "$(OUTPUT_DIR)" -maxdepth 1 -type f -name '*.kmod.c' -delete 2>/dev/null || true; \
	  find   "$(OUTPUT_DIR)" -maxdepth 1 -type f -name '*.lib.c'  -delete 2>/dev/null || true; \
	fi
