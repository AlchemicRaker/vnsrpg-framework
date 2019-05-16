#!/usr/bin/make -f

TITLE = vnsrpg

ASMLIST = txrom main chr0 interrupts init sample_ppu banks
INCLIST = nes mmc3
MAPCFG = txrom.cfg
MAPOUT = map.txt

CA65 = ca65
LD65 = ld65
SRCDIR = src
OBJDIR = build

EMU := mesen
DEBUGEMU := mesen

.DEFAULT_GOAL := all

.PHONY: run all clean clean-all

ROMFILE = $(TITLE).nes
DBGFILE = $(TITLE).dbg

run: $(ROMFILE) $(DBGFILE) directories
	$(EMU) $< &

debug: $(ROMFILE) $(DBGFILE) directories
	$(EMU) $< &

all: directories $(DBGFILE) $(ROMFILE)

clean:
	-rm $(OBJDIR)/*.o
	-rmdir $(OBJDIR)

clean-all: clean
	-rm $(MAPOUT) $(ROMFILE) $(DBGFILE)

# build env

directories: $(OBJDIR)

$(OBJDIR):
	mkdir $(OBJDIR)

# build PRG

OBJLISTFILES = $(foreach o,$(ASMLIST) $(INCLIST),$(OBJDIR)/$(o).o)

$(DBGFILE) $(ROMFILE) $(MAPOUT): $(MAPCFG) $(OBJLISTFILES)
	$(LD65) -o $(ROMFILE) -m $(MAPOUT) --dbgfile $(DBGFILE) -C $^

$(OBJDIR)/%.o: $(SRCDIR)/%.s
	$(CA65) $< -g -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.inc
	$(CA65) $< -g -o $@
