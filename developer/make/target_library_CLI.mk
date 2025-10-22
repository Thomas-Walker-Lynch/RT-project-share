# make/target_lib_CLI.mk — build *.lib.c and *.CLI.c
# written for the Harmony skeleton, always invoked from cwd  $REPO_HOME/<role>
# files have two suffixes by convention, e.g.: X.lib.c or Y.CLI.c 

.SUFFIXES:
.EXPORT_ALL_VARIABLES:
.DELETE_ON_ERROR:

#--------------------------------------------------------------------------------
# defaults for environment variables

C              ?= gcc
CFLAGS         ?=
C_SOURCE_DIR   ?= cc
LIBRARY_FILE   ?=
MACHINE_DIR    ?= scratchpad
LN_FLAGS       ?=

ifeq ($(strip $(C)),)
  $(error target_lib_CLI.mk: no C compiler specified)
endif

#--------------------------------------------------------------------------------
# derived variables

# source discovery (single dir)
C_SOURCE_LIB  := $(wildcard $(C_SOURCE_DIR)/*.lib.c)
C_SOURCE_EXEC := $(wildcard $(C_SOURCE_DIR)/*.CLI.c)

# remove suffix to get base name
C_BASE_LIB  := $(sort $(patsubst %.lib.c,%, $(notdir $(C_SOURCE_LIB))))
C_BASE_EXEC := $(sort $(patsubst %.CLI.c,%, $(notdir $(C_SOURCE_EXEC))))

# two sets of object files, one for the lib, and one for the CLI programs
OBJECT_LIB  := $(patsubst %, scratchpad/%.lib.o, $(C_BASE_LIB))
OBJECT_EXEC := $(patsubst %, scratchpad/%.CLI.o, $(C_BASE_EXEC))

# executables are made from EXEC sources
EXEC := $(patsubst %, $(MACHINE_DIR)/%, $(C_BASE_EXEC))

#--------------------------------------------------------------------------------
# pull in dependencies

-include $(OBJECT_LIB:.o=.d) $(OBJECT_EXEC:.o=.d)


#--------------------------------------------------------------------------------
# targets

# when no target is given make uses the first target, this one
.PHONY: usage
usage:
	@echo example usage: make clean
	@echo example usage: make library
	@echo example usage: make CLI
	@echo example usage: make library CLI

.PHONY: version
version:
	@echo makefile version 7.1
	if [ ! -z "$(C)" ]; then $(C) -v; fi
	/bin/make -v

.PHONY: information
information:
	@printf "· → Unicode middle dot — visible: [%b]\n" "·"
	@echo "C_SOURCE_DIR: " $(C_SOURCE_DIR)
	@echo "C_SOURCE_LIB: " $(C_SOURCE_LIB)
	@echo "C_SOURCE_EXEC: " $(C_SOURCE_EXEC)
	@echo "C_BASE_LIB: " $(C_BASE_LIB)
	@echo "C_BASE_EXEC: " $(C_BASE_EXEC)
	@echo "OBJECT_LIB: " $(OBJECT_LIB)
	@echo "OBJECT_EXEC: " $(OBJECT_EXEC)
	@echo "EXEC: " $(EXEC)

.PHONY: library
library: $(LIBRARY_FILE)

$(LIBRARY_FILE): $(OBJECT_LIB)
	@if [ -s "$@" ] || [ -n "$(OBJECT_LIB)" ]; then \
		echo "ar rcs $@ $^"; \
		ar rcs $@ $^; \
	else \
		rm -f "$@"; \
	fi   

#.PHONY: CLI
#CLI: $(LIBRARY_FILE) $(EXEC)

.PHONY: CLI
CLI: library $(EXEC)


# generally better to use the project local clean scripts, but this will make it so that the make targets can be run again

.PHONY: clean
clean:
	rm -f $(LIBRARY_FILE)
	for obj in $(OBJECT_LIB) $(OBJECT_EXEC); do rm -f $$obj $${obj%.o}.d || true; done
	for i in $(EXEC); do [ -e $$i ] && rm $$i || true; done


# recipes
scratchpad/%.o: $(C_SOURCE_DIR)/%.c
	$(C) $(CFLAGS) -o $@ -c $<

$(MACHINE_DIR)/%: scratchpad/%.CLI.o
	$(C) -o $@ $< $(LN_FLAGS)

