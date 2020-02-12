PROJECTS ?= paper presentation

VIEWER ?= evince
LATEXMK=latexmk
ENGINE=pdflatex
ENGINE_OPTIONS=-shell-escape -synctex=1

# paper.pdf presentation.pdf ...
OUTPUTS := $(foreach proj, $(PROJECTS), $(proj).pdf)

default: all
all: $(PROJECTS)

SOURCES=$(wildcard ./*-*.tex)

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
	$(VIEWER) $(OUTPUTS) 2>/dev/null >/dev/null &

.PHONY: show-gray
GRAYS := $(foreach proj, $(PROJECTS), $(proj)-gray.pdf)
show-gray: $(GRAYS)
	$(VIEWER) $(GRAYS) 2>/dev/null >/dev/null &

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
	$(RM) $(wildcard ./*.cut) $(wildcard ./*.bbl) $(wildcard ./*.nav) $(wildcard ./*.snm) $(wildcard ./*.vrb)
	$(RM) -r $(wildcard ./_minted-*)
