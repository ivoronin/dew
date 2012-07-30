#ifndef _DEW_H_
#define _DEW_H_

extern int yydebug;
extern int yyparse();
void handle_qw(char*, char*, char*);
void sfree(void*);

#endif /* _DEW_H_ */