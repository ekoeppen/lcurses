
DOCS = \
	index.html \
	lcurses.html \
	cui.html \


%.html: %.txt
	rst2html.py -stg --stylesheet-path default.css $^ $@

all: $(DOCS)

