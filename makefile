#!/usr/bin/make -f

TITLE = vnsrpg

ASMLIST = nrom main chr0 interrupts init sample_ppu banks
INCLIST = nes mmc3
MAPCFG = nrom128.cfg
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

run: $(ROMFILE) directories
	$(EMU) $< &

all: directories $(ROMFILE)

clean:
	-rm $(OBJDIR)/*.o
	-rmdir $(OBJDIR)

clean-all: clean
	-rm $(MAPOUT) $(ROMFILE)

# build env

directories: $(OBJDIR)

$(OBJDIR):
	mkdir $(OBJDIR)

# build PRG

OBJLISTFILES = $(foreach o,$(ASMLIST) $(INCLIST),$(OBJDIR)/$(o).o)

$(ROMFILE) $(MAPOUT): $(MAPCFG) $(OBJLISTFILES)
	$(LD65) -o $(ROMFILE) -m $(MAPOUT) -C $^

$(OBJDIR)/%.o: $(SRCDIR)/%.s
	$(CA65) $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.inc
	$(CA65) $< -o $@
