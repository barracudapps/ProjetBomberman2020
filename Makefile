
OZPATH=/Applications/Mozart2.app/Contents/Resources/bin
SRCS:=$(wildcard *.oz)
OZFS:=$(SRCS:=f) # Add an 'f' to turn .oz into .ozf

MAKEFLAGS+=--no-builtin-rules

.SUFFIXES:
.SUFFIXES: .oz .ozf

%.ozf : %.oz
	$(OZPATH)/ozc -c $< -o $@

.PHONY: all
all: $(OZFS)

.PHONY: run
run: main.ozf all
	$(OZPATH)/ozengine $<
