
ifneq ("$(origin V)", "command line")
  Q = @
endif

LUA = lua
CC  = $(CROSS_COMPILE)gcc
ECHO = @echo

DFB_INC_DIR = $(shell pkg-config --variable=includedir directfb)/directfb/
DFB_HEADER = $(DFB_INC_DIR)directfb_keyboard.h $(DFB_INC_DIR)directfb.h

CFLAGS = -Wall -fPIC $(shell pkg-config --cflags directfb $(LUA))
LDFLAGS = -shared $(shell pkg-config --libs directfb $(LUA))

# We might want to install the module to a different path
INSTALL_DIR ?= $(shell pkg-config --variable INSTALL_CMOD $(LUA))

COMPAT_DIR := compat/
SRC_DIR := src/
SRC := $(wildcard $(SRC_DIR)*.c $(COMPAT_DIR)*.c)
OBJ = $(SRC:.c=.o)

OUTPUT=directfb.so

$(OUTPUT): $(OBJ)
	$(Q)$(ECHO) "    LD    "$@;
	$(Q)$(CC) $^ $(LDFLAGS) -o $@

.c.o:
	$(Q)$(ECHO) "    CC    "$@;
	$(Q)$(CC) $(CFLAGS) -c $< -o $@

.gen.stamp: gendfb-lua.pl dir
	$(Q)$(ECHO) "Generating from $(DFB_HEADER)"
	$(Q)cat $(DFB_HEADER) | ./gendfb-lua.pl || exit 1
	$(Q)touch .gen.stamp

tags: $(SRC_DIR)* $(DFB_HEADER)
	$(Q)ctags $(SRC_DIR)* $(DFB_HEADER)

.PHONY: install
install: $(OUTPUT)
	$(Q)mkdir -p $(INSTALL_DIR)
	$(Q)cp $(OUTPUT) $(INSTALL_DIR)

.PHONY: clean
clean:
	$(Q)rm -f *.so $(SRC_DIR)* .gen.stamp

.PHONY: gen
gen: .gen.stamp

.PHONY: dir
dir:
	$(Q)mkdir -p src
