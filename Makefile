.PHONY: all build install clean

all: build

install:
	cp templates/eisvogel/eisvogel.tex ~/.pandoc/templates/eisvogel.latex

build: report.pdf

wordcount:
	pandoc --lua-filter wordcount.lua report.md

clean:
	rm -f report.pdf

%.pdf: %.md %.bib
	pandoc -s $< -o $@ --from markdown --template eisvogel --listings --number-sections --citeproc

