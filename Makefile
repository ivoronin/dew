CC=gcc
LEX=flex
YACC=bison
CFLAGS=-Os -W -Wall -Wextra -Werror

OBJECTS=dew_parser.o dew_lexer.o dew_main.o

all: dew

dew_lexer.c: dew.l
	$(LEX) -o $@ $^

dew: $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^

dew_parser.c: dew.y
	$(YACC) -d -o $@ $^

.PHONY: clean
clean:
	rm -f $(OBJECTS) dew_parser.c dew_parser.h dew_lexer.c dew
