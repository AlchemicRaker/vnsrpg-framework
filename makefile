#!/usr/bin/make -f

TITLE = vnsrpg

ASMLIST = txrom main chr0 interrupts init banks demo
CHRLIST = font
INCLIST = global
MAPCFG = txrom.cfg
MAPOUT = map.txt

CA65 = ca65
LD65 = ld65
GGPIPE = $(java -jar ggpipe.jar)

SRCDIR = src
OBJDIR = build
CHRDIR = graphics

EMU := mesen
DEBUGEMU := mesen

.DEFAULT_GOAL := all

.PHONY: run all clean clean-all chr pal

ROMFILE = $(TITLE).nes
DBGFILE = $(TITLE).dbg

CHRFILES = $(foreach c,$(CHRLIST),$(OBJDIR)/$(c).chr)

# PNGRFILES = $(foreach c,$(CHRLIST),$(OBJDIR)/$(c).r.png)

PALFILES = $(foreach c,$(CHRLIST),$(OBJDIR)/$(c).pal)


run: directories $(ROMFILE) $(DBGFILE)
	$(EMU) $(ROMFILE) &

debug: directories $(ROMFILE) $(DBGFILE)
	$(EMU) $(ROMFILE) &

chr: $(CHRFILES)

pal: $(PALFILES)

all: directories $(DBGFILE) $(ROMFILE)

clean:
	-rm $(OBJDIR)/*.o $(OBJDIR)/*.chr

clean-all: clean
	-rm $(MAPOUT) $(ROMFILE) $(DBGFILE)

# build env

directories: $(OBJDIR)

$(OBJDIR):
	mkdir $(OBJDIR)

# build PRG

OBJLISTHEADERFILES = $(foreach o,$(INCLIST),$(OBJDIR)/$(o).o)

OBJLISTFILES = $(foreach o,$(ASMLIST) $(INCLIST),$(OBJDIR)/$(o).o)

$(DBGFILE) $(ROMFILE) $(MAPOUT): $(MAPCFG) $(OBJLISTFILES)
	$(LD65) -o $(ROMFILE) -m $(MAPOUT) --dbgfile $(DBGFILE) -C $^

$(OBJDIR)/%.o: $(SRCDIR)/%.s $(OBJLISTHEADERFILES) $(CHRFILES)
	$(CA65) $< -g --bin-include-dir build -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.inc
	$(CA65) $< -g --bin-include-dir build -o $@

#todo: include the palette file instead
$(OBJDIR)/%.chr: $(OBJDIR)/%.r.png 
	java -jar ggpipe.jar  $< --binary -o $@

$(OBJDIR)/%.r.png: $(CHRDIR)/%.png 
	java -jar ggpipe.jar  $< --reduce-palette -palette `java -jar ggpipe.jar $< --get-palette` -o $@

$(OBJDIR)/%.pal: $(CHRDIR)/%.png
	java -jar ggpipe.jar  $< --get-palette -o $@

