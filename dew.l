%option nounput
%option noinput
%option noyywrap

%{
#include "dew_parser.h"
int q = 0;
%}

%x EW_CHARSET EW_ENCODING EW_TEXT

%% 

<INITIAL>"=?" {
	BEGIN EW_CHARSET;
	return EW_START;
}

<EW_CHARSET,EW_ENCODING>"?" { 
	if ( ++q == 1 )
		BEGIN EW_ENCODING;
	else if ( q == 2 )
		BEGIN EW_TEXT;

	return Q;
}

%{ /*
	Any CHAR except SPACE, CTLs, and especials>
  	especials = "(" / ")" / "<" / ">" / "@" / "," / ";" / ":" / "
                <"> / "/" / "[" / "]" / "?" / "." / "="

    \x21      !
    \x23-\x27 # $ % & ´
    \x2a-\x2b * +
    \x2d      -
    \x30-\x39 0-9
    \x41-\x5a A-Z
    \x5c      \
    \x5e-\x7e ^ _ ` a-z { | } ~  
*/ %}
<EW_CHARSET,EW_ENCODING>[\x21\x23-\x27\x2a-\x2b\x2d\x30-\x39\x41-\x5a\x5c\x5e-\x7e]+ { 
	yylval.string = strdup(yytext);
	return TOKEN; 
}

%{ /* Any printable ASCII character other than "?" or SPACE */ %}
<EW_TEXT>[\x21-\x3e\x40-\x7e]+ {
	yylval.string = strdup(yytext);
	return TEXT;
}

<EW_CHARSET,EW_ENCODING,EW_TEXT>.|\n {
	return CHAR;
}

<EW_TEXT>"?=" {
	BEGIN INITIAL;
	q = 0;
	return EW_END;
}
