
##############################################################################
## YOU SHOULD NOT EDIT THIS FILE, USE config INSTEAD
##

include config

DFB_INC_DIR := $(shell pkg-config --variable=includedir directfb)/directfb/
DFB_HEADER := $(DFB_INC_DIR)directfb_keyboard.h $(DFB_INC_DIR)directfb.h 

CFLAGS := -Wall -fPIC $(shell pkg-config --cflags directfb $(LUA))
LDFLAGS := -shared $(shell pkg-config --libs directfb $(LUA))
INSTALL_DIR := $(shell pkg-config --variable INSTALL_CMOD $(LUA))

SRC_DIR := src/
SRC := $(wildcard $(SRC_DIR)*.c)

OUTPUT=directfb.so

$(OUTPUT): $(SRC) 
	$(CC) $(CFLAGS) $(SRC) $(LDFLAGS) -o $@ 

.gen.stamp: gendfb-lua.pl dir
	cat $(DFB_HEADER) | ./gendfb-lua.pl || exit 1
	touch .gen.stamp

tags: $(SRC_DIR)* $(DFB_HEADER)
	ctags $(SRC_DIR)* $(DFB_HEADER)

.PHONY: install
install: $(OUTPUT)
	 cp $(OUTPUT) $(INSTALL_DIR) 

.PHONY: clean
clean:
	rm -f *.so $(SRC_DIR)* .gen.stamp

.PHONY: gen
gen: .gen.stamp

.PHONY: dir
dir:
	mkdir -p src
