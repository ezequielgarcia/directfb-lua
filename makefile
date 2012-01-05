DFB_INC_DIR := $(shell pkg-config --variable=includedir directfb)/directfb/
DFB_HEADER := $(DFB_INC_DIR)directfb_keyboard.h $(DFB_INC_DIR)directfb.h 

CFLAGS := -Wall -fPIC $(shell pkg-config --cflags directfb lua)
LDFLAGS := -shared $(shell pkg-config --libs directfb lua)

SRC_DIR := src/
SRC := $(wildcard $(SRC_DIR)*.c)

OUTPUT=directfb.so

$(OUTPUT): $(SRC) 
	gcc $(CFLAGS) $(SRC) $(LDFLAGS) -o $@ 

.gen.stamp: gendfb-lua.pl dir
	cat $(DFB_HEADER) | ./gendfb-lua.pl || exit 1
	touch .gen.stamp

tags: $(SRC_DIR)* $(DFB_HEADER)
	ctags $(SRC_DIR)* $(DFB_HEADER)

.PHONY: clean
clean:
	rm -f *.so $(SRC_DIR)* .gen.stamp

.PHONY: gen
gen: .gen.stamp

.PHONY: dir
dir:
	mkdir -p src
