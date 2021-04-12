.PHONY: all build clean

all: build

build: report.pdf

wordcount:
	pandoc --lua-filter wordcount.lua report.md

clean:
	rm -f report.pdf

%.pdf: %.md
	pandoc $< -o $@ --from markdown --template eisvogel --listings --number-sections

