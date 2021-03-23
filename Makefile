.PHONY: all build clean

all: build

build: report.pdf

clean:
	rm -f report.pdf

%.pdf: %.md
	pandoc $< -o $@ --from markdown --template eisvogel --listings

