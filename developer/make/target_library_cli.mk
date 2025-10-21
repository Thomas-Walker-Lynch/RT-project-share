.SUFFIXES:

# target_library_cli.mk — build *.lib.c → static lib, *.cli.c → executables
# invoked from $REPO_HOME/<role> (cwd = developer root)

# ---- defaults (override from outer make if desired)
LIBFILE ?= scratchpad/librabbit.a
EXECDIR ?= bin

# ---- ensure dirs exist
$(shell mkdir -p scratchpad $(EXECDIR))

# ---- discover sources (keep only existing src dirs)
SRCDIR_LIST := $(wildcard $(SRCDIR_LIST))
C_SOURCE_LIB  := $(foreach dir,$(SRCDIR_LIST),$(wildcard $(dir)/*.lib.c))
C_SOURCE_EXEC := $(foreach dir,$(SRCDIR_LIST),$(wildcard $(dir)/*.cli.c))

# ---- derive names
C_BASE_LIB  := $(sort $(patsubst %.lib.c,%,$(notdir $(C_SOURCE_LIB))))
C_BASE_EXEC := $(sort $(patsubst %.cli.c,%,$(notdir $(C_SOURCE_EXEC))))

OBJECT_LIB  := $(patsubst %,scratchpad/%.lib.o,$(C_BASE_LIB))
OBJECT_EXEC := $(patsubst %,scratchpad/%.cli.o,$(C_BASE_EXEC))
EXEC        := $(patsubst %,$(EXECDIR)/%,$(C_BASE_EXEC))

# ---- headers/flags
INCFLAG_List := $(foreach dir,$(SRCDIR_LIST),-I $(dir))
CFLAGS += $(INCFLAG_List)

# ---- depfiles
-include $(OBJECT_LIB:.o=.d) $(OBJECT_EXEC:.o=.d)

# ---- vpath for multi-dir builds
vpath %.lib.c $(SRCDIR_LIST)
vpath %.cli.c $(SRCDIR_LIST)

# ===== targets =====

.PHONY: usage
usage:
	@echo example: make library
	@echo example: make cli
	@echo example: make library cli
	@echo example: make all

.PHONY: version
version:
	@echo target_library_cli.mk version 7.3
	@if [ -n "$(C)" ]; then $(C) -v; fi; /bin/make -v

.PHONY: information
information:
	@printf "· → Unicode middle dot — visible: [%b]\n" "·"
	@echo "SRCDIR_LIST:  $(SRCDIR_LIST)"
	@echo "C_SOURCE_LIB:  $(C_SOURCE_LIB)"
	@echo "C_SOURCE_EXEC: $(C_SOURCE_EXEC)"
	@echo "C_BASE_LIB:    $(C_BASE_LIB)"
	@echo "C_BASE_EXEC:   $(C_BASE_EXEC)"
	@echo "OBJECT_LIB:    $(OBJECT_LIB)"
	@echo "OBJECT_EXEC:   $(OBJECT_EXEC)"
	@echo "EXEC:          $(EXEC)"
	@echo "INCFLAG_List:  $(INCFLAG_List)"
	@echo "LIBFILE:       $(LIBFILE)"
	@echo "EXECDIR:       $(EXECDIR)"

.PHONY: all
all: library cli

.PHONY: library
library: $(LIBFILE)

$(LIBFILE): $(OBJECT_LIB)
	ar rcs $@ $^

.PHONY: cli
cli: $(LIBFILE) $(EXEC)

# ===== recipes =====

scratchpad/%.lib.o: %.lib.c
	$(C) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

scratchpad/%.cli.o: %.cli.c
	$(C) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

$(EXECDIR)/%: scratchpad/%.cli.o $(LIBFILE)
	$(C) -o $@ $< $(LIBFILE) $(LINKFLAGS)

.PHONY: clean
clean:
	rm -f $(LIBFILE)
	for obj in $(OBJECT_LIB) $(OBJECT_EXEC); do rm -f $$obj $${obj%.o}.d || true; done
	for i in $(EXEC); do [ -e $$i ] && rm -f $$i || true; done
