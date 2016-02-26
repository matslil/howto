ifeq ($(origin BUILDING),undefined)
# Determine source path from where this Makefile is
export SRCPATH := $(abspath $(dir $(shell readlink -e $(lastword $(MAKEFILE_LIST)))))

.PHONY: all $(MAKECMDGOALS)
all $(MAKECMDGOALS): Makefile
	@$(MAKE) -rR --warn-undefined-variables --no-print-directory $@ BUILDING=y

# Make sure object directory gets a link to the makefile, so we don't need to
# specify "-f" for sub-sequent make invocations.
Makefile: $(SRCPATH)/Makefile
	ln -fs $<

else

.SILENT:

# Default verbosity is silent
V ?= 0

ifneq ($(filter-out 0 1 2,$(V)),)
$(info SRCPATH = "$(SRCPATH)")
endif

# Make sure we use a bash shell
SHELL := $(shell which bash)

# If verbosity is 2 or higher, print all shell commands executed
ifneq ($(filter-out 0 1,$(V)),)
SHELL += -x
endif

# If verbosity is 1 or higher, print which rules that are executed and why
ifneq ($(filter-out 0,$(V)),)
OLD_SHELL := $(SHELL)
SHELL = $(warning Building $@$(if $<, (from $<))$(if $?, ($? newer)))$(OLD_SHELL) 
endif

vpath %.md $(SRCPATH)
vpath %.dot $(SRCPATH)
vpath %.css $(SRCPATH)

DEFAULT_LATEX := $(SRCPATH)/templates/default.latex
DEFAULT_CSS :=   $(SRCPATH)/templates/default.css

MDFILES := gpg.md airgap.md

.PHONY: all clean distclean html pdf

# Make documents in all supported formats, currently html and pdf
all: html pdf

# Remove everything related to documentation
distclean: clean
	rm -f $(MDFILES:.md=.html) $(MDFILES:.md=.pdf) license-icon-88x31.png

# Remove all intermediary files, saving only the final documentation
clean:
	rm -f gpg-overview.{svg,pdf} $(MDFILES:.md=.tex) $(MDFILES:.md=.log) $(MDFILES:.md=.out) $(MDFILES:.md=.aux)

html: $(MDFILES:.md=.html)

pdf: $(MDFILES:.md=.pdf)

%.pdf: %.md
	pandoc --toc --default-image-extension=.pdf --data-dir=$(<D) -o $@ $<

gpg.pdf: gpg-overview.pdf

# How to build the document file, same template regardless of output format
#sisdel.tex: %.tex: %.md %.css sisdel.md type-hierarchy-graph.pdf default.latex
#	pandoc -c $*.css --default-image-extension=pdf --data-dir=$(<D) -o $@ $<

%.html: %.md
	pandoc --toc --standalone --default-image-extension=.svg --data-dir=$(<D) -o $@ $<

gpg.html: gpg-overview.svg

# Handle pre-made images
$(MDFILES): license-icon-88x31.png
%.png: $(SRCPATH)/%.png
	cp $< $@

# Convert LaTex to pdf
%.pdf: %.tex
	pdflatex $<

# LaTex does not support svg format, so svg images are converted to pdf
# LaTex is used as an intermediate format by pandoc when producing pdf
# documents
%.pdf: %.svg
	rsvg-convert -f pdf -o $@ $<

# Compile directional graph text file to svg
%.svg: %.dot
	dot -Tsvg $< > $@

endif # ifeq ($(origin BUILDING),undefined)
