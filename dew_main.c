#include <iconv.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <openssl/bio.h>
#include <openssl/evp.h>
#include "dew.h"

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

char * decode_b64(char *s) {
	int l;
	BIO *b64, *bio;
	char *r;

	if (s == NULL)
		return NULL;

	l = strlen(s);

	if ( (b64 = BIO_new(BIO_f_base64())) == NULL )
		return NULL;
	BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
	bio = BIO_new_mem_buf(s, l);
	bio = BIO_push(b64, bio);

	r = (char*)smalloc(l);
	BIO_read(bio, r, l);

	BIO_free_all(bio);

	return r;
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
	char *d = NULL, *c;

	if ( !charset || !encoding || !s )
		return;

	if ( !strcasecmp(encoding, "Q") )
		d = decode_qp(s);
	else if ( !strcasecmp(encoding, "B") )
		d = decode_b64(s);

	if ( d == NULL )
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
