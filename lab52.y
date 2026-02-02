%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_num = 1;
int temp_count = 1;

char* new_temp();
void generate_code(char* op, char* arg1, char* arg2, char* result);
void generate_unary_code(char* op, char* arg, char* result);
void generate_function_code(char* func_name, char* arg1, char* arg2, char* result);
void generate_assign_code(char* target, char* source);

extern FILE* yyin;
extern int yylex();
void yyerror(const char* s);

%}

%union {
    char* str;
}

%token NEWLINE
%token <str> ID NUM
%token ASSIGN ADD SUB MUL DIV MOD
%token SQRT POW LOG EXP_FUNC SIN COS TAN ABS
%token LPAREN RPAREN COMMA

%left ADD SUB
%left MUL DIV MOD
%right UMINUS

%type <str> expression term factor function_call
%type <str> statement

%%

program: statement_list
        ;

statement_list: statement
              | statement_list NEWLINE statement
              ;

statement: ID ASSIGN expression {
            char* temp = new_temp();
            generate_assign_code($3, temp);
            printf("%d %s = %s\n", line_num, $1, temp);
            free($1);
            free($3);
            free(temp);
          }
        ;

expression: expression ADD term {
            char* temp = new_temp();
            generate_code("+", $1, $3, temp);
            $$ = temp;
            free($1);
            free($3);
          }
        | expression SUB term {
            char* temp = new_temp();
            generate_code("-", $1, $3, temp);
            $$ = temp;
            free($1);
            free($3);
          }
        | term { $$ = $1; }
        ;

term: term MUL factor {
        char* temp = new_temp();
        generate_code("*", $1, $3, temp);
        $$ = temp;
        free($1);
        free($3);
      }
    | term DIV factor {
        char* temp = new_temp();
        generate_code("/", $1, $3, temp);
        $$ = temp;
        free($1);
        free($3);
      }
    | term MOD factor {
        char* temp = new_temp();
        generate_code("%", $1, $3, temp);
        $$ = temp;
        free($1);
        free($3);
      }
    | factor { $$ = $1; }
    ;

factor: function_call { $$ = $1; }
      | LPAREN expression RPAREN { $$ = $2; }
      | ID { $$ = strdup($1); }
      | NUM { $$ = strdup($1); }
      | SUB factor %prec UMINUS {
            char* temp = new_temp();
            generate_unary_code("-", $2, temp);
            $$ = temp;
            free($2);
          }
      ;

function_call: SQRT LPAREN expression RPAREN {
            char* temp = new_temp();
            generate_function_code("sqrt", $3, NULL, temp);
            $$ = temp;
            free($3);
          }
        | POW LPAREN expression COMMA expression RPAREN {
            char* temp = new_temp();
            generate_function_code("pow", $3, $5, temp);
            $$ = temp;
            free($3);
            free($5);
          }
        | LOG LPAREN expression RPAREN {
            char* temp = new_temp();
            generate_function_code("log", $3, NULL, temp);
            $$ = temp;
            free($3);
          }
        | EXP_FUNC LPAREN expression RPAREN {
            char* temp = new_temp();
            generate_function_code("exp", $3, NULL, temp);
            $$ = temp;
            free($3);
          }
        | SIN LPAREN expression RPAREN {
            char* temp = new_temp();
            generate_function_code("sin", $3, NULL, temp);
            $$ = temp;
            free($3);
          }
        | COS LPAREN expression RPAREN {
            char* temp = new_temp();
            generate_function_code("cos", $3, NULL, temp);
            $$ = temp;
            free($3);
          }
        | TAN LPAREN expression RPAREN {
            char* temp = new_temp();
            generate_function_code("tan", $3, NULL, temp);
            $$ = temp;
            free($3);
          }
        | ABS LPAREN expression RPAREN {
            char* temp = new_temp();
            generate_function_code("abs", $3, NULL, temp);
            $$ = temp;
            free($3);
          }
        ;

%%

char* new_temp() {
    char* temp = malloc(10);
    sprintf(temp, "t%d", temp_count++);
    return temp;
}

void generate_code(char* op, char* arg1, char* arg2, char* result) {
    printf("%d %s = %s %s %s\n", line_num, result, arg1, op, arg2);
}

void generate_unary_code(char* op, char* arg, char* result) {
    printf("%d %s = %s %s\n", line_num, result, op, arg);
}

void generate_function_code(char* func_name, char* arg1, char* arg2, char* result) {
    if (arg2 == NULL) {
        printf("%d %s = %s (%s)\n", line_num, result, func_name, arg1);
    } else {
        printf("%d %s = %s (%s, %s)\n", line_num, result, func_name, arg1, arg2);
    }
}

void generate_assign_code(char* target, char* source) {
    printf("%d %s = %s\n", line_num, source, target);
}

void yyerror(const char* s) {
    fprintf(stderr, "Error at line %d: %s\n", line_num, s);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s input.txt\n", argv[0]);
        return 1;
    }
    
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        perror("Error opening input file");
        return 1;
    }
    
    printf("Generated Three-Address Code:\n");
    printf("==============================\n");
    yyparse();
    
    fclose(yyin);
    return 0;
}