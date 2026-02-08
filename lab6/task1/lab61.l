%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lab61.tab.h"

extern int yylineno;
%}

%option noyywrap
%option yylineno

WHITESPACE      [ \t]+
NEWLINE         \n
ID              [a-zA-Z][a-zA-Z0-9]*
NUM             [0-9]+
OP_ASSIGN       "+="|"-="|"*="|"/="|"%="|"**="|"//="

%%

{WHITESPACE}    /* skip whitespace */
{NEWLINE}       { yylineno++; return NEW_LINE; }
"!"             return '!';
"&&"            return AND;
"||"            return OR;
"**"            return POWER;
"//"            return INT_DIV;
">"             return '>';
"<"             return '<';
">="            return GE;
"<="            return LE;
"=="            return EQ;
"!="            return NE;
"+"             return '+';
"-"             return '-';
"*"             return '*';
"/"             return '/';
"%"             return '%';
"="             return '=';
"("             return '(';
")"             return ')';
{OP_ASSIGN}     { 
                yylval.str_val = strdup(yytext); 
                return OP_ASSIGN; 
                }
{ID}            { 
                yylval.str_val = strdup(yytext); 
                return ID; 
                }
{NUM}           { 
                yylval.num_val = atoi(yytext); 
                return NUM; 
                }
.               { return yytext[0]; }

%%