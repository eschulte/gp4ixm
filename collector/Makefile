BASEDIR:=/home/eschulte/src/ixm/sfb/src/template/../..

export TARGET=body
include $(BASEDIR)/config/Makevars.mk
OBJDIR:=.
BINDIR:=.
include $(BASEDIR)/config/Makecommon.mk

COMMON_CPPFLAGS:=-Wall -pedantic -Werror -Wundef
CROSS_GCC_CPPFLAGS:=$(COMMON_CPPFLAGS) -mcpu=arm7tdmi -mthumb-interwork -mno-long-calls -ffunction-sections -fdata-sections -fno-rtti -fno-exceptions -fno-use-cxa-atexit -fno-use-cxa-get-exception-ptr
CPPFLAGS:=$(CROSS_GCC_CPPFLAGS)

CPPFLAGS+=-I$(INCLUDEDIR) -I$(INCLUDEDIR)/lpc -Os -O2
CFLAGS+=-I$(INCLUDEDIR) -I$(INCLUDEDIR)/lpc -Os -O2

# If anything in the lib changes: Kill them, kill them all
ALLDEP+=$(wildcard $(LIBDIR)/*)      

OBJFILES:=sketch-wrapper.o collector.o

LDFLAGS+= -nostartfiles --cref -M -Map $(TMPDIR)/sketch.map -lm -lc

all:	sketch.hex


$(BINDIR)/sketch.hex:	$(OBJDIR)/sketch 
	$(OBJCOPY) --strip-unneeded -O ihex $(OBJDIR)/sketch $@

$(OBJDIR)/sketch:	$(OBJFILES) FORCE
	$(LD) $(OBJFILES) $(LDFLAGS) -T $(LIBDIR)/sfbloader.ld  -o"$@"

sketch-wrapper.o:	sketch-wrapper.cpp sketch.pde $(ALLDEP)
	$(GCC) $(CPPFLAGS) $(SKETCH_EXTRA_CPPFLAGS) -Wall -c -I ../../src/include/ sketch-wrapper.cpp

collector.o:	collector.cpp $(ALLDEP)
	$(GCC) $(CPPFLAGS) $(SKETCH_EXTRA_CPPFLAGS) -Wall -c -I ../../src/include/ collector.cpp

clean:	FORCE
	@rm -f *.o *~ sketch 

realclean: clean
	@rm -f sketch.hex

.PHONY:	FORCE
