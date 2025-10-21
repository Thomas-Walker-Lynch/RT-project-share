# make/target_kmod.mk — build *.kmod.c as kernel modules (single-pass, kmod-only)
# invoked from $REPO_HOME/<role>
# version 1.4

.SUFFIXES:
.EXPORT_ALL_VARIABLES:

SOURCE_DIR  := cc
BUILD_DIR   := /lib/modules/$(shell uname -r)/build
OUTPUT_DIR  := $(abspath scratchpad/kmod)   # dedicated kmod staging/build dir

# authored basenames (without suffix)
BASE_LIST   := $(patsubst %.kmod.c,%,$(notdir $(wildcard $(SOURCE_DIR)/*.kmod.c)))

# optional library sources (without suffix) to include inside modules
# set KMOD_INCLUDE_LIB=0 to disable
KMOD_INCLUDE_LIB ?= 1
ifeq ($(KMOD_INCLUDE_LIB),1)
LIB_BASE   := $(patsubst %.lib.c,%,$(notdir $(wildcard $(SOURCE_DIR)/*.lib.c)))
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
	@echo "SOURCE_DIR:   " $(SOURCE_DIR)
	@echo "BUILD_DIR:    " $(BUILD_DIR)
	@echo "OUTPUT_DIR:   " $(OUTPUT_DIR)
	@echo "BASE_LIST:    " $(BASE_LIST)
	@echo "LIB_BASE:     " $(LIB_BASE)
	@echo "ALL_KMOD_C:   " $(ALL_KMOD_C)
	@echo "ALL_LIB_C:    " $(ALL_LIB_C)
	@echo "KMOD_INCLUDE_LIB=" $(KMOD_INCLUDE_LIB)

ifndef BASE_LIST
$(warning No *.kmod.c found under $(SOURCE_DIR); nothing to build)
endif

.PHONY: kmod
kmod: _prepare modules

.PHONY: _prepare
_prepare:
	@mkdir -p "$(OUTPUT_DIR)"
	# fresh Kbuild control file — one obj per module; each module also links lib objs (if any)
	@{ \
	  printf "obj-m := %s\n" "$(foreach m,$(BASE_LIST),$(m).o)"; \
	  for m in $(BASE_LIST); do \
	    printf "%s-objs := %s.kmod.o" "$$m" "$$m"; \
	    for lb in $(LIB_BASE); do printf " %s.lib.o" "$$lb"; done; \
	    printf "\n"; \
	  done; \
	} > "$(OUTPUT_DIR)/Makefile"
	# stage kmod sources (read-only authored dir, write only to OUTPUT_DIR)
	@for b in $(BASE_LIST); do \
	  src="$(SOURCE_DIR)/$$b.kmod.c"; dst="$(OUTPUT_DIR)/$$b.kmod.c"; \
	  echo "--- Stage: $$dst ---"; ln -sf "$$src" "$$dst" 2>/dev/null || cp "$$src" "$$dst"; \
	done
	# stage library sources (optional)
	@for b in $(LIB_BASE); do \
	  src="$(SOURCE_DIR)/$$b.lib.c"; dst="$(OUTPUT_DIR)/$$b.lib.c"; \
	  echo "--- Stage: $$dst ---"; ln -sf "$$src" "$$dst" 2>/dev/null || cp "$$src" "$$dst"; \
	done

.PHONY: modules
modules: $(OUTPUT_DIR)/Makefile $(ALL_KMOD_C) $(ALL_LIB_C)
	@echo "--- Invoking Kbuild for Modules: $(BASE_LIST) ---"
	$(MAKE) -C "$(BUILD_DIR)" M="$(OUTPUT_DIR)" modules

# quality-of-life: allow 'make scratchpad/kmod/foo.ko' after batch build
$(OUTPUT_DIR)/%.ko: modules
	@true

.PHONY: clean
clean:
	@if [ -d "$(OUTPUT_DIR)" ]; then \
	  echo "--- Cleaning Kbuild Artifacts in $(OUTPUT_DIR) ---"; \
	  $(MAKE) -C "$(BUILD_DIR)" M="$(OUTPUT_DIR)" clean; \
	  find "$(OUTPUT_DIR)" -maxdepth 1 -type l -name '*.kmod.c' -delete 2>/dev/null || true; \
	  find "$(OUTPUT_DIR)" -maxdepth 1 -type l -name '*.lib.c'  -delete 2>/dev/null || true; \
	  find "$(OUTPUT_DIR)" -maxdepth 1 -type f -name '*.kmod.c' -delete 2>/dev/null || true; \
	  find "$(OUTPUT_DIR)" -maxdepth 1 -type f -name '*.lib.c'  -delete 2>/dev/null || true; \
	fi
