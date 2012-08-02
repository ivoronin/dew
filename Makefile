CC=gcc
LEX=flex
YACC=bison
CFLAGS=-Os -W -Wall -Wextra
LDFLAGS=-lcrypto
PREFIX=/usr

OBJECTS=dew_parser.o dew_lexer.o dew_main.o

all: dew

dew_lexer.c: dew.l
	$(LEX) -o $@ $^

dew: $(OBJECTS)
	$(CC) -o $@ $^ $(LDFLAGS)

dew_parser.c: dew.y
	$(YACC) -d -o $@ $^

.PHONY: clean install
install:
	install -m 0755 -g root -o root -t $(DESTDIR)$(PREFIX)/bin dew
clean:
	rm -f $(OBJECTS) dew_parser.c dew_parser.h dew_lexer.c dew
