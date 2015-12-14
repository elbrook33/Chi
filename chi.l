%{
	#include "y.tab.h"
	void yyerror(const char *);
%}

%%

[ \t\n]
;

\".*\" {
	yylval.str = strdup(yytext); return QUOTE;
};

"memoryContent" {
	yylval.str = strdup(yytext); return DEREF;
};

"memoryAddress" {
	yylval.str = strdup(yytext); return REF;
};

[a-z][a-zA-Z0-9\_]* {
	yylval.str = strdup(yytext); return WORD;
};

[A-Z][a-zA-Z0-9\_]* {
	yylval.str = strdup(yytext); return CONST;
};

[0-9]+\.[0-9]+ {
	yylval.floatVal = atof(yytext); return FLOAT;
};

[0-9]+ {
	yylval.intVal = atoi(yytext); return INT;
};

([\+\-\*\/\>\<]|==|≠|≤|≥) {
	yylval.str = strdup(yytext); return OP;
};

» {
	yylval.str = strdup(yytext); return IN;
};

« {
	yylval.str = strdup(yytext); return OUT;
};

× {
	yylval.str = strdup(yytext); return CROSS;
};

. {
	return *yytext;
};

%%

int yywrap(void) {
	return 1;
}
