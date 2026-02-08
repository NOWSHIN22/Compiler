%{
#include "lab62.tab.h"
#include <stdlib.h>
#include <string.h>

extern int yylineno;
%}

DIGIT    [0-9]
LETTER   [a-zA-Z]
ID       {LETTER}({LETTER}|{DIGIT})*
NUM      {DIGIT}+
NEWLINE  \n
WHITESPACE [ \t]+

%%

"sqrt"       { return SQRT; }
"pow"        { return POW; }
"log"        { return LOG; }
"exp"        { return EXP; }
"sin"        { return SIN; }
"cos"        { return COS; }
"tan"        { return TAN; }
"abs"        { return ABS; }

"="          { return '='; }
"+"          { return '+'; }
"-"          { return '-'; }
"*"          { return '*'; }
"/"          { return '/'; }
"%"          { return '%'; }
"("          { return '('; }
")"          { return ')'; }
","          { return ','; }

{NUM}        { 
                yylval.str = strdup(yytext); 
                return NUM; 
            }

{ID}         { 
                yylval.str = strdup(yytext); 
                return ID; 
            }

{NEWLINE}    { return NL; }
{WHITESPACE} { /* ignore whitespace */ }

.            { 
                printf("Unexpected character: %c\n", yytext[0]); 
                return yytext[0]; 
            }

%%

int yywrap() {
    return 1;
}