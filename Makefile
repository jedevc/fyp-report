.PHONY: all build clean

all: build

build: report.pdf

wordcount:
	pandoc --lua-filter wordcount.lua report.md

clean:
	rm -f report.pdf

%.pdf: %.md %.bib
	pandoc -s $< -o $@ --from markdown --template vendor/eisvogel/eisvogel.tex --listings --number-sections --citeproc --pdf-engine-opt=--shell-escape

