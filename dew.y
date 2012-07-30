%{
#include <stdio.h>
#include "dew.h"

#define YYDEBUG 1
int yydebug = 0;

extern int yylex(void);

int yyerror(char *s __attribute__ ((unused))) {
	printf("<invalid encoded word skipped>");
	return 0;
}

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
