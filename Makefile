#!/usr/bin/make -f

# Set the projects (top-level .tex files) you want to compile.
PROJECTS ?= paper presentation
# The main project (where the metadata is loaded from).
MAIN ?= presentation
# The resulting combined file.
COMBINED ?= combined

VIEWER ?= evince
ENGINE ?= pdflatex
LATEXMK ?= latexmk
ENGINE_OPTIONS ?= -shell-escape -synctex=1

# FIXME: Maybe a better way to detect dependencies somehow? TeX LSP? :'D
SOURCES=$(wildcard ./*.tex ./*.bib)

# paper.pdf presentation.pdf ...
OUTPUTS := $(foreach proj, $(PROJECTS), $(proj).pdf)

default: all
all: $(COMBINED).pdf

.PHONY: $(PROJECTS)
$(PROJECTS): %:
	$(MAKE) $*.pdf

%.pdf: %.tex $(SOURCES)
	command -v texliveonfly && \
		texliveonfly -c $(ENGINE) -a "$(ENGINE_OPTIONS) -interaction=nonstopmode" $<
	$(LATEXMK) -$(ENGINE) $(ENGINE_OPTIONS) $<

%-gray.pdf: %.pdf
	gs -sOUTPUTFILE=$@ -sDEVICE=pdfwrite \
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

# (Needed: pip install lpython pdfrw stapler)
$(COMBINED).pdf: $(OUTPUTS)
	stapler cat $^ $@
	# Rewrite the metadata in the combined file with the one in the main
	# project. Sadly, 'stapler' by default clears the metadata portion.
	lpython -t bare \
		"from pdfrw import PdfReader, PdfWriter;; "\
		"presData = PdfReader(ARGS[1]); "\
		"outf = PdfReader(ARGS[2]); "\
		"outf.Info = presData.Info; "\
		"PdfWriter(ARGS[2], trailer=outf).write()" \
		-X $(MAIN).pdf \
		-X $@

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
