#!/usr/bin/make -f

TITLE = vnsrpg

OBJLIST = nrom hello_world

CA65 = ca65
LD65 = ld65
OBJDIR = obj
SRCDIR = src

EMU := mesen
DEBUGEMU := mesen

.DEFAULT_GOAL := run

.PHONY: run all clean

run: $(TITLE).nes
	$(EMU) $< &

all: $(TITLE).nes

clean:
	-rm $(OBJDIR)/*.o

# build PRG

OBJLISTFILES = $(foreach o,$(OBJLIST),$(OBJDIR)/$(o).o)

$(TITLE).nes map.txt: nrom128.cfg $(OBJLISTFILES)
	$(LD65) -o $(TITLE).nes -m map.txt -C $^

$(OBJDIR)/%.o: $(SRCDIR)/%.s
	$(CA65) $< -o $@
