# make/target_lib_cli.mk — build *.lib.c and *.cli.c
# written for the Harmony skeleton, always invoked from cwd  $REPO_HOME/<role>

.SUFFIXES:
.EXPORT_ALL_VARIABLES:
.DELETE_ON_ERROR:

#--------------------------------------------------------------------------------
# files have two suffixes by convention, e.g.: X.lib.c or Y.cli.c 
#

ifeq ($(strip $(C)),)
  $(error target_lib_cli.mk: no C compiler specified)
endif

# single source directory
C_SOURCE_DIR ?= cc
C_SOURCE_DIR_OK := $(wildcard $(C_SOURCE_DIR))

ifeq ($(strip $(C_SOURCE_DIR_OK)),)
  $(warning target_lib_cli.mk: C_SOURCE_DIR '$(C_SOURCE_DIR)' not found or empty)
endif

# RT uses header integrated C source files
CFLAGS ?= -I $(C_SOURCE_DIR)

# source discovery (single dir)
C_SOURCE_LIB  := $(wildcard $(C_SOURCE_DIR)/*.lib.c)
C_SOURCE_EXEC := $(wildcard $(C_SOURCE_DIR)/*.cli.c)

# remove suffix to get base name
C_BASE_LIB  := $(sort $(patsubst %.lib.c,%, $(notdir $(C_SOURCE_LIB))))
C_BASE_EXEC := $(sort $(patsubst %.cli.c,%, $(notdir $(C_SOURCE_EXEC))))


# two sets of object files, one for the lib, and one for the CLI programs
OBJECT_LIB  := $(patsubst %, scratchpad/%.lib.o, $(C_BASE_LIB))
OBJECT_EXEC := $(patsubst %, scratchpad/%.cli.o, $(C_BASE_EXEC))

-include $(OBJECT_LIB:.o=.d) $(OBJECT_EXEC:.o=.d)

# executables are made from EXEC sources
EXEC := $(patsubst %, $(EXECDIR)/%, $(C_BASE_EXEC))


#--------------------------------------------------------------------------------
# targets

# when no target is given make uses the first target, this one
.PHONY: usage
usage:
	@echo example usage: make clean
	@echo example usage: make library
	@echo example usage: make cli
	@echo example usage: make library cli

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
	@echo "INCFLAG_List: " $(INCFLAG_List)

.PHONY: library
library: $(LIBFILE)

$(LIBFILE): $(OBJECT_LIB)
	@if [ -s "$@" ] || [ -n "$(OBJECT_LIB)" ]; then \
		echo "ar rcs $@ $^"; \
		ar rcs $@ $^; \
	else \
		rm -f "$@"; \
	fi   

#.PHONY: cli
#cli: $(LIBFILE) $(EXEC)

.PHONY: cli
cli: library $(EXEC)


# generally better to use the project local clean scripts, but this will make it so that the make targets can be run again

.PHONY: clean
clean:
	rm -f $(LIBFILE)
	for obj in $(OBJECT_LIB) $(OBJECT_EXEC); do rm -f $$obj $${obj%.o}.d || true; done
	for i in $(EXEC); do [ -e $$i ] && rm $$i || true; done


# recipes
scratchpad/%.o: $(C_SOURCE_DIR)/%.c
	$(C) $(CFLAGS) -o $@ -c $<

$(EXECDIR)/%: scratchpad/%.cli.o
	$(C) -o $@ $< $(LIB_ARG) $(LINKFLAGS)

