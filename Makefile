.PHONY: all build install clean

all: build

install:
	cp templates/eisvogel/eisvogel.tex ~/.pandoc/templates/

build: report.pdf

wordcount:
	pandoc --lua-filter wordcount.lua report.md

clean:
	rm -f report.pdf

%.pdf: %.md
	pandoc -s $< -o $@ --from markdown --template eisvogel --listings --number-sections --citeproc

