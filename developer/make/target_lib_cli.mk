.SUFFIXES:
# make/target_lib_cli.mk — build *.lib.c and *.cli.c
# written for the Harmony skeleton, always invoked from cwd  $REPO_HOME/<role>

#--------------------------------------------------------------------------------
# files have two suffixes by convention, e.g.: X.lib.c or Y.cli.c 
#

# bail early if there is no compiler
ifeq ($(C),)
  $(error target_lib_cli.mk: no C compiler specified.)
endif

# keep only the source directories that are in the file system
SRCDIR_LIST := $(wildcard $(SRCDIR_LIST))

# bail early if the SRCDIR_list is empty
ifeq ($(SRCDIR_LIST),)
  @printf "target_lib_cli.mk: empty SRCDIR_LIST"
  exit 0
endif

# duplicate source file names in different directories will cause
# problems with this makefile

C_SOURCE_LIB := $(foreach dir, $(SRCDIR_LIST), $(wildcard $(dir)/*.lib.c))
C_SOURCE_EXEC := $(foreach dir, $(SRCDIR_LIST), $(wildcard $(dir)/*.cli.c))

#remove the suffix to get base name
C_BASE_LIB=  $(sort $(patsubst %.lib.c,  %, $(notdir $(C_SOURCE_LIB))))
C_BASE_EXEC=  $(sort $(patsubst %.cli.c,  %, $(notdir $(C_SOURCE_EXEC))))

# two sets of object files, one for the lib, and one for the command line interface progs
OBJECT_LIB= $(patsubst %, scratchpad/%.lib.o, $(C_BASE_LIB))
OBJECT_EXEC= $(patsubst %, scratchpad/%.cli.o, $(C_BASE_EXEC))

-include $(OBJECT_LIB:.o=.d) $(OBJECT_EXEC:.o=.d)

# executables are made from EXEC sources
EXEC= $(patsubst %, $(EXECDIR)/%, $(C_BASE_EXEC))

# the new C programming style gated sections in source instead of header filesheader
INCFLAG_List := $(foreach dir, $(SRCDIR_LIST), -I $(dir))
CFLAGS += $(INCFLAG_List)

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
	@echo "SRCDIR_LIST: " $(SRCDIR_LIST)
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

#$(LIBFILE): $(OBJECT_LIB) $(DEPFILE)
$(LIBFILE): $(OBJECT_LIB)
	ar rcs $(LIBFILE) $(OBJECT_LIB)


.PHONY: cli
#cli: $(LIBFILE) $(DEPFILE)
cli: $(LIBFILE)
	make sub_cli

.PHONY: sub_cli
sub_cli: $(EXEC)

# generally better to use the project local clean scripts, but this will make it so that the make targets can be run again

.PHONY: clean
clean:
	rm -f $(LIBFILE)
	for obj in $(OBJECT_LIB) $(OBJECT_EXEC); do rm -f $$obj $${obj%.o}.d || true; done
	for i in $(EXEC); do [ -e $$i ] && rm $$i || true; done


# recipes
vpath %.c $(SRCDIR_LIST)
scratchpad/%.o: %.c
	$(C) $(CFLAGS) -o $@ -c $<

$(EXECDIR)/%: scratchpad/%.cli.o $(LIBFILE)
	$(C) -o $@ $< $(LIBFILE) $(LINKFLAGS)

