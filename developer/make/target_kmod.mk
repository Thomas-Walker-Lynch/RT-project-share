# make/target_kmod.mk — build *.kmod.c as kernel modules (single-pass, kmod-only)
# invoked from $REPO_HOME/<role>
# version 1.4

.SUFFIXES:
.DELETE_ON_ERROR:

#--------------------------------------------------------------------------------
# defaults for environment variables (override from outer make/env as needed)

# Kernel build tree, which is part of the Linux system, use running kernel if unset
KMOD_BUILD_DIR  ?=

# Authored source directory (single dir)
KMOD_SOURCE_DIR ?= cc

# Extra compiler flags passed to Kbuild (e.g., -I $(KMOD_SOURCE_DIR))
KMOD_CCFLAGS ?= 

# Staging/output directory for Kbuild
KMOD_OUTPUT_DIR ?= scratchpad/kmod

# Include *.lib.c into modules (1=yes, 0=no)
KMOD_INCLUDE_LIB ?= 1




#--------------------------------------------------------------------------------
# derived variables (computed from the above)

# Canonicalize output dir
kmod_output_dir := $(abspath $(KMOD_OUTPUT_DIR))

# Select kernel build dir (cross or running kernel)
kmod_build_dir := $(if $(KMOD_BUILD_DIR),$(KMOD_BUILD_DIR),/lib/modules/$(shell uname -r)/build)

# Authored basenames (without suffix)
base_list := $(patsubst %.kmod.c,%,$(notdir $(wildcard $(KMOD_SOURCE_DIR)/*.kmod.c)))

# Optional library sources (without suffix) to include inside modules
ifeq ($(KMOD_INCLUDE_LIB),1)
lib_base := $(patsubst %.lib.c,%,$(notdir $(wildcard $(KMOD_SOURCE_DIR)/*.lib.c)))
else
lib_base :=
endif

# Staged sources (kept namespaced to prevent .o collisions)
all_kmod_c := $(addsuffix .kmod.c,$(addprefix $(kmod_output_dir)/,$(base_list)))
all_lib_c  := $(addsuffix .lib.c,$(addprefix $(kmod_output_dir)/,$(lib_base)))



#--------------------------------------------------------------------------------
# targets

.PHONY: usage
usage:
	@printf "Usage: make [kmod|clean|information|version]\n"

.PHONY: version
version:
	@echo target_kmod version 1.4

.PHONY: information
information:
	@echo "KMOD_SOURCE_DIR:   " $(KMOD_SOURCE_DIR)
	@echo "kmod_build_dir:    " $(kmod_build_dir)
	@echo "KMOD_OUTPUT_DIR:   " $(KMOD_OUTPUT_DIR)
	@echo "kmod_output_dir:   " $(kmod_output_dir)
	@echo "base_list:    " $(base_list)
	@echo "lib_base:     " $(lib_base)
	@echo "all_kmod_c:   " $(all_kmod_c)
	@echo "all_lib_c:    " $(all_lib_c)
	@echo "KMOD_INCLUDE_LIB=" $(KMOD_INCLUDE_LIB)


ifeq ($(strip $(base_list)),)
  $(warning No *.kmod.c found under $(KMOD_SOURCE_DIR); nothing to build)
endif

# --- Parallel-safe preparation as real targets ---

# ensure the staging dir exists (order-only prereq)
$(kmod_output_dir):
	@mkdir -p "$(kmod_output_dir)"

# generate the Kbuild control Makefile
$(kmod_output_dir)/Makefile: | $(kmod_output_dir)
	@{ \
	  printf "ccflags-y += %s\n" "$(KMOD_CCFLAGS)"; \
	  printf "obj-m := %s\n" "$(foreach m,$(base_list),$(m).o)"; \
	  for m in $(base_list); do \
	    printf "%s-objs := %s.kmod.o" "$$m" "$$m"; \
	    for lb in $(lib_base); do printf " %s.lib.o" "$$lb"; done; \
	    printf "\n"; \
	  done; \
	} > "$@"

# stage kmod sources (one rule per file; parallelizable)
$(kmod_output_dir)/%.kmod.c: $(KMOD_SOURCE_DIR)/%.kmod.c | $(kmod_output_dir)
	@echo "--- Stage: $@ ---"
	@ln -sf "$<" "$@" 2>/dev/null || { rm -f "$@"; cp "$<" "$@"; }

# stage library sources (optional; also parallelizable)
$(kmod_output_dir)/%.lib.c: $(KMOD_SOURCE_DIR)/%.lib.c | $(kmod_output_dir)
	@echo "--- Stage: $@ ---"
	@ln -sf "$<" "$@" 2>/dev/null || { rm -f "$@"; cp "$<" "$@"; }

# rebuild inputs for 'modules'
.PHONY: modules
modules: $(kmod_output_dir)/Makefile $(all_kmod_c) $(all_lib_c)
	@echo "--- Invoking Kbuild for Modules: $(base_list) ---"
	$(MAKE) -C "$(kmod_build_dir)" M="$(kmod_output_dir)" modules

# top-level convenience target
.PHONY: kmod
kmod: modules


# quality-of-life: allow 'make scratchpad/kmod/foo.ko' after batch build
$(kmod_output_dir)/%.ko: modules
	@true

.PHONY: clean
clean:
	@if [ -d "$(kmod_output_dir)" ]; then \
	  echo "--- Cleaning Kbuild Artifacts in $(kmod_output_dir) ---"; \
	  $(MAKE) -C "$(kmod_build_dir)" M="$(kmod_output_dir)" clean; \
	  rm -f  "$(kmod_output_dir)"/*.o \
	         "$(kmod_output_dir)"/*.ko \
	         "$(kmod_output_dir)"/*.mod \
	         "$(kmod_output_dir)"/*.mod.c \
	         "$(kmod_output_dir)"/modules.order \
	         "$(kmod_output_dir)"/Module.symvers \
	         "$(kmod_output_dir)"/.*.cmd 2>/dev/null || true; \
	  rm -rf "$(kmod_output_dir)"/.tmp_versions 2>/dev/null || true; \
	  find   "$(kmod_output_dir)" -maxdepth 1 -type l -name '*.kmod.c' -delete 2>/dev/null || true; \
	  find   "$(kmod_output_dir)" -maxdepth 1 -type l -name '*.lib.c'  -delete 2>/dev/null || true; \
	  find   "$(kmod_output_dir)" -maxdepth 1 -type f -name '*.kmod.c' -delete 2>/dev/null || true; \
	  find   "$(kmod_output_dir)" -maxdepth 1 -type f -name '*.lib.c'  -delete 2>/dev/null || true; \
	fi
