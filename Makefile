CC=gcc
LEX=flex
YACC=bison
CFLAGS=-Os -W -Wall -Wextra -Werror

all: dew

dew_lexer.c: dew.l
	$(LEX) -o $@ $^

dew: dew_parser.o dew_lexer.o
	$(CC) $(LDFLAGS) -o $@ $^

dew_parser.c: dew.y
	$(YACC) -d -o $@ $^

.PHONY: clean
clean:
	rm -f dew_parser.o dew_parser.c dew_parser.h dew_lexer.o dew_lexer.c dew
