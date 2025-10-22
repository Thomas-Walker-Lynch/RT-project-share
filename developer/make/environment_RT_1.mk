# makefile environment variable defaults.
# cc is the name of the C compiler, a file called <name>.c is C source code.
# RT uses header integrated C source files, i.e. the source and the header are the same file

SHELL=/bin/bash

# environment_RT_1.mk

ECHO := printf "%b\n"

C_SOURCE_DIR     := cc
KMOD_SOURCE_DIR  := cc

C                := gcc
CFLAGS           := -std=gnu11 -Wall -Wextra -Wpedantic -finput-charset=UTF-8
CFLAGS           += -MMD -MP
CFLAGS           += -I $(C_SOURCE_DIR)

KMOD_CCFLAGS    := -I $(KMOD_SOURCE_DIR)

LIBNAME         := $(PROJECT)
LIBNAME         := $(subst -,_,$(LIBNAME))

LIBDIR          := scratchpad
LIBFILE         := $(LIBDIR)/lib$(LIBNAME).a

LINKFLAGS       := -L$(LIBDIR) -L/lib64 -L/lib

EXECDIR         := scratchpad

