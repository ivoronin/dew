%{
#include <iconv.h>
#include <langinfo.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define YYDEBUG 1
int yydebug = 0;

extern int yylex(void);
int yyerror(char*);
void handle_qw(char*, char*, char*);
void sfree(void*);

%}

%union { char *string; }

%token EW_START EW_END Q TOKEN TEXT CHAR
%type<string> TOKEN TEXT
%destructor { sfree ($$); } <string>


%%

input: | error
	   | input ew

ew: EW_START TOKEN Q TOKEN Q TEXT EW_END { 
	handle_qw($2, $4, $6);
	sfree($2);
	sfree($4);
	sfree($6);
}
	
%%

int yyerror(char *s __attribute__ ((unused))) {
	printf("<invalid encoded word skipped>");
	return 0;
}

void sfree(void *p) {
	if (!p) return;
	free(p);
	p = NULL;
}

void * smalloc(size_t size) {
	void * p;
	if ( (p = malloc(size)) == NULL )
		exit(EXIT_FAILURE);
	memset(p, 0, size);
	return p;
}

unsigned int hexc2int(char c) {
	int i = -1;
	if (c >= '0' && c <= '9') i = c - '0';
 	if (c >= 'A' && c <= 'F') i = 10 + c - 'A';
 	/* if (c >= 'a' && c <= 'f') i = 10 + c - 'a'; */
 	return i;
}

char * decode_qp(char *s) {
	int l, i, n = 0,
		msb = 0,
		lsb = 0;
	char *r;

	if ( !s )
		return NULL;

	l = strlen(s);

	r = (char*)smalloc(l + 1);

	for ( i = 0; i < l; i++ ) {
		if ( s[i] == '=' && i + 2 < l &&
			 (msb = hexc2int(s[i+1])) != -1 &&
			 (lsb = hexc2int(s[i+2])) != -1 ) {
				r[n] =  msb * 16 + lsb;
				i += 2;
		} else if ( s[i] == '_' )
			r[n] = ' ';
		else
			r[n] = s[i];
		n++;
	}

	r[n] = '\0';

	return r;
}

char * convert(char * charset, char *s) {
	iconv_t cd;
	size_t inbytesleft, outbytesleft;
	char *oinbuf, *inbuf, *ooutbuf, *outbuf, *c;

	if ( !charset || !s )
		return NULL;

	if ( (cd = iconv_open("", charset)) == (iconv_t)-1 )
		return strdup(s);

	inbuf = oinbuf = strdup(s);
	inbytesleft = strlen(inbuf);
	outbytesleft = inbytesleft * 4; /* 8bit -> utf-32 */
	outbuf = ooutbuf = (char*)smalloc(outbytesleft + 1);

	if ( outbuf == NULL )
		exit(EXIT_FAILURE);

	outbuf[0] = 0;

	if ( iconv(cd, &inbuf, &inbytesleft, &outbuf, &outbytesleft) == (size_t)-1 )
		c = strdup(s);
	else
		c = strdup(ooutbuf);

	iconv_close(cd);

	sfree(oinbuf);
	sfree(ooutbuf);

	return c;
}

void handle_qw(char *charset, char *encoding, char *s) {
	char *d, *c;

	if ( !charset || !encoding || !s )
		return;

	if ( !strcmp(encoding, "Q") ) {
		if ( (d = decode_qp(s)) == NULL )
			d = strdup(s);
	} else if ( !strcmp(encoding, "B") )
		/* base64 - not implemented */
		d = strdup(s);
	else
		d = strdup(s);

	c = convert(charset, d);
	printf("%s", c);
	
	sfree(d);
	sfree(c);
}

int main(int argc, char * argv[]) {
	int opt;
	while ( (opt = getopt(argc, argv, "y")) != -1) {
		switch(opt) {
			case 'y':
				yydebug = 1;
				break;
			default: /* ? */
				fprintf(stderr, "Usage: %s [-y]\n", argv[0]);
				exit(EXIT_FAILURE);
		}
	}
	(void)setlocale(LC_ALL, "");
	yyparse();
	return 0;
}