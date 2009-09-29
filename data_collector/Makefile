BASEDIR:=/home/eschulte/src/ixm/sfb/src/template/../..

export TARGET=body
include $(BASEDIR)/config/Makevars.mk
OBJDIR:=.
BINDIR:=.
include $(BASEDIR)/config/Makecommon.mk

CPPFLAGS+=-I$(INCLUDEDIR) -I$(INCLUDEDIR)/lpc -Os -O2
CFLAGS+=-I$(INCLUDEDIR) -I$(INCLUDEDIR)/lpc -Os -O2

# If anything in the lib changes: Kill them, kill them all
ALLDEP+=$(wildcard $(LIBDIR)/*)      

OBJFILES:=sketch-wrapper.o 

LDFLAGS+= -nostartfiles --cref -M -Map $(TMPDIR)/sketch.map -lm -lc

all:	sketch.hex


$(BINDIR)/sketch.hex:	$(OBJDIR)/sketch 
	$(OBJCOPY) --strip-unneeded -O ihex $(OBJDIR)/sketch $@

$(OBJDIR)/sketch:	$(OBJFILES) FORCE
	$(LD) $(OBJFILES) $(LDFLAGS) -T $(LIBDIR)/sfbloader.ld  -o"$@"

sketch-wrapper.o:	sketch-wrapper.cpp sketch.pde $(ALLDEP)
	$(GCC) $(CPPFLAGS) $(SKETCH_EXTRA_CPPFLAGS) -Wall -c -I ../../src/include/ sketch-wrapper.cpp

clean:	FORCE
	@rm -f *.o *~ sketch 

realclean: clean
	@rm -f sketch.hex

.PHONY:	FORCE
