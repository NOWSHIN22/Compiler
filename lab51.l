%{
#include "lab51.tab.h"
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

"+"        { return ADD; }
"-"        { return SUB; }
"*"        { return MUL; }
"/"        { return DIV; }
"**"       { return EXP; }
"//"       { return INTDIV; }
"+="       { return ADD_ASSIGN; }
"-="       { return SUB_ASSIGN; }
"*="       { return MUL_ASSIGN; }
"/="       { return DIV_ASSIGN; }
"%="       { return MOD_ASSIGN; }
"**="      { return EXP_ASSIGN; }
"&&"       { return AND; }
"||"       { return OR; }
"!"        { return NOT; }
"%"        { return MOD; }
"="        { return ASSIGN; }
"("        { return LPAREN; }
")"        { return RPAREN; }
">"        { return GT; }
"<"        { return LT; }

{DIGIT}+   { yylval.str = strdup(yytext); return NUM; }
{ID}       { yylval.str = strdup(yytext); return ID; }
{NEWLINE}  { line_num++; return NEWLINE; }
{WHITESPACE}   { /* ignore whitespace */ }

.          { yyerror("Invalid character"); }

%%

/* Remove the yywrap() function entirely since we're using %option noyywrap */