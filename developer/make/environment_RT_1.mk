# makefile environment variable defaults.
#  cc is the name of the C compiler
#  <name>.c is C source code.

SHELL=/bin/bash

#ECHO= echo -e
#ECHO= echo
ECHO := printf "%b\n"


# sources found in these subdirectories:
SRCDIR_LIST=cc
LIBDIR     := $(SCRATCHPAD)
LIBFILE    := $(LIBDIR)/lib.a
LINKFLAGS  := -L$(LIBDIR) -L/lib64 -L/lib
EXECDIR    := $(SCRATCHPAD)

C=gcc
CFLAGS=-std=gnu11 -Wall -Wextra -Wpedantic -finput-charset=UTF-8
CFLAGS += -MMD -MP
LINKFLAGS=-L$(LIBDIR) -L/lib64 -L/lib
