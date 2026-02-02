%{
#include "lab52.tab.h"
#include <stdlib.h>
#include <string.h>
extern int line_num;
void yyerror(const char* s);
%}

%option noyywrap nounput noinput

DIGIT    [0-9]
ID       [a-zA-Z][a-zA-Z0-9]*
NEWLINE  \n
WHITESPACE [ \t\r]+

%%

"sqrt"    { return SQRT; }
"pow"     { return POW; }
"log"     { return LOG; }
"exp"     { return EXP_FUNC; }
"sin"     { return SIN; }
"cos"     { return COS; }
"tan"     { return TAN; }
"abs"     { return ABS; }

"+"       { return ADD; }
"-"       { return SUB; }
"*"       { return MUL; }
"/"       { return DIV; }
"%"       { return MOD; }
"="       { return ASSIGN; }
"("       { return LPAREN; }
")"       { return RPAREN; }
","       { return COMMA; }

{DIGIT}+  { yylval.str = strdup(yytext); return NUM; }
{ID}      { yylval.str = strdup(yytext); return ID; }
{NEWLINE} { line_num++; return NEWLINE; }
{WHITESPACE}   { /* ignore whitespace */ }

.         { yyerror("Invalid character"); }

%%