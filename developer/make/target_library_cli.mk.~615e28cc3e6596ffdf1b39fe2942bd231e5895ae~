.SUFFIXES

# ---- phony
.PHONY: usage version information library cli clean

# ---- defaults (safe fallbacks; override from outer make if desired)
LIBFILE ?= scratchpad/librabbit.a
EXECDIR ?= bin

# ---- ensure dirs exist (lazy, portable)
$(shell mkdir -p scratchpad $(EXECDIR))

# ---- sources → objects
C_SOURCE_LIB  := $(foreach dir,$(SRCDIR_LIST),$(wildcard $(dir)/*.lib.c))
C_SOURCE_EXEC := $(foreach dir,$(SRCDIR_LIST),$(wildcard $(dir)/*.cli.c))

C_BASE_LIB  := $(sort $(patsubst %.lib.c,%,$(notdir $(C_SOURCE_LIB))))
C_BASE_EXEC := $(sort $(patsubst %.cli.c,%,$(notdir $(C_SOURCE_EXEC))))

OBJECT_LIB  := $(patsubst %,scratchpad/%.lib.o,$(C_BASE_LIB))
OBJECT_EXEC := $(patsubst %,scratchpad/%.cli.o,$(C_BASE_EXEC))

EXEC := $(patsubst %,$(EXECDIR)/%,$(C_BASE_EXEC))

# ---- headers
INCFLAG_List := $(foreach dir,$(SRCDIR_LIST),-I $(dir))
CFLAGS += $(INCFLAG_List)

# ---- depfiles
-include $(OBJECT_LIB:.o=.d) $(OBJECT_EXEC:.o=.d)

# ---- targets
usage:
	@echo example: make library
	@echo example: make cli
	@echo example: make library cli

version:
	@echo makefile version 7.2
	@if [ -n "$(C)" ]; then $(C) -v; fi; /bin/make -v

information:
	@printf "· → Unicode middle dot — visible: [%b]\n" "·"
	@echo "SRCDIR_LIST:  $(SRCDIR_LIST)"
	@echo "C_SOURCE_LIB: $(C_SOURCE_LIB)"
	@echo "C_SOURCE_EXEC: $(C_SOURCE_EXEC)"
	@echo "C_BASE_LIB:   $(C_BASE_LIB)"
	@echo "C_BASE_EXEC:  $(C_BASE_EXEC)"
	@echo "OBJECT_LIB:   $(OBJECT_LIB)"
	@echo "OBJECT_EXEC:  $(OBJECT_EXEC)"
	@echo "EXEC:         $(EXEC)"
	@echo "INCFLAG_List: $(INCFLAG_List)"

# library builds the static archive from *.lib.o
library: $(LIBFILE)

$(LIBFILE): $(OBJECT_LIB)
	ar rcs $@ $^

# cli builds the executables; NO recursive make
cli: $(LIBFILE) $(EXEC)

# ---- recipes
vpath %.lib.c $(SRCDIR_LIST)
vpath %.cli.c $(SRCDIR_LIST)

scratchpad/%.lib.o: %.lib.c
	$(C) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

scratchpad/%.cli.o: %.cli.c
	$(C) $(CFLAGS) -MMD -MP -MF $(@:.o=.d) -c $< -o $@

$(EXECDIR)/%: scratchpad/%.cli.o $(LIBFILE)
	$(C) -o $@ $< $(LIBFILE) $(LINKFLAGS)

clean:
	rm -f $(LIBFILE)
	for obj in $(OBJECT_LIB) $(OBJECT_EXEC); do rm -f $$obj $${obj%.o}.d || true; done
	for i in $(EXEC); do [ -e $$i ] && rm -f $$i || true; done
