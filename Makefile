#!/usr/bin/make -f

PROJECTS ?= paper presentation
VIEWER ?= evince
LATEXMK=latexmk
ENGINE ?= pdflatex
ENGINE_OPTIONS=-shell-escape -synctex=1

# paper.pdf presentation.pdf ...
OUTPUTS := $(foreach proj, $(PROJECTS), $(proj).pdf)

default: all
all: $(PROJECTS)

SOURCES=$(wildcard ./*.tex ./*.bib)

.PHONY: $(PROJECTS)
$(PROJECTS): %:
	$(MAKE) $*.pdf

%.pdf: %.tex $(SOURCES)
	command -v texliveonfly && \
		texliveonfly -c $(ENGINE) -a "$(ENGINE_OPTIONS) -interaction=nonstopmode" $<
	$(LATEXMK) -$(ENGINE) $(ENGINE_OPTIONS) $<

%-gray.pdf: %.pdf
	gs -sOutputFile=$@ -sDEVICE=pdfwrite \
		-sColorConversionStrategy=Gray \
		-dProcessColorModel=/DeviceGray \
		-dCompatibilityLevel=1.4 \
		-dNOPAUSE -dBATCH \
		$< </dev/null

TEXTS := $(foreach proj, $(PROJECTS), $(proj).txt)
%.txt: %.pdf
	pdftotext -nopgbrk $<

.PHONY: show
show: $(OUTPUTS)
	$(VIEWER) $(OUTPUTS) &>/dev/null &

.PHONY: show-gray
GRAYS := $(foreach proj, $(PROJECTS), $(proj)-gray.pdf)
show-gray: $(GRAYS)
	$(VIEWER) $(GRAYS) &>/dev/null &

combined.pdf: $(OUTPUTS)
	gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=$@ -dBATCH $^

.PHONY: show-combined
show-combined: combined.pdf
	$(VIEWER) $^ &>/dev/null &

.PHONY: clean
clean: --clean-extra
	$(LATEXMK) -$(ENGINE) -c

.PHONY: distclean
distclean: clean
	$(LATEXMK) -$(ENGINE) -C
	$(RM) $(GRAYS)
	$(RM) $(TEXTS)

.PHONY: --clean-extra
--clean-extra:
	$(RM) $(wildcard ./*.cut) $(wildcard ./*.bbl) $(wildcard ./*.nav) $(wildcard ./*.snm) $(wildcard ./*.vrb) $(wildcard ./*.synctex.gz) $(wildcard ./*.run.xml)
	$(RM) -r $(wildcard ./_minted-*)
