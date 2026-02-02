%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_num = 1;
int temp_count = 1;

char* new_temp();
void generate_code(char* op, char* arg1, char* arg2, char* result);
void generate_unary_code(char* op, char* arg, char* result);
void generate_assign_code(char* target, char* source);

extern FILE* yyin;
extern int yylex();
void yyerror(const char* s);

%}

%union {
    char* str;
    int op_type;
}

%token NEWLINE
%token <str> ID NUM
%token ASSIGN ADD SUB MUL DIV EXP INTDIV MOD
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN EXP_ASSIGN
%token AND OR NOT
%token LPAREN RPAREN
%token GT LT

%left OR
%left AND
%left NOT
%left GT LT
%left ADD SUB
%left MUL DIV INTDIV MOD
%right EXP
%right UMINUS

%type <str> expression term factor unary primary
%type <str> statement
%type <op_type> opassign

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
        | ID opassign expression {
            char* temp1 = new_temp();
            char* temp2 = new_temp();
            char op[3];
            
            switch($2) {
                case 1: strcpy(op, "+"); break;
                case 2: strcpy(op, "-"); break;
                case 3: strcpy(op, "*"); break;
                case 4: strcpy(op, "/"); break;
                case 5: strcpy(op, "%"); break;
                case 6: strcpy(op, "**"); break;
            }
            
            generate_code("*", $1, $3, temp1);
            generate_code(op, $1, temp1, temp2);
            printf("%d %s = %s\n", line_num, $1, temp2);
            free($1);
            free($3);
            free(temp1);
            free(temp2);
          }
        ;

opassign: ADD_ASSIGN { $$ = 1; }
        | SUB_ASSIGN { $$ = 2; }
        | MUL_ASSIGN { $$ = 3; }
        | DIV_ASSIGN { $$ = 4; }
        | MOD_ASSIGN { $$ = 5; }
        | EXP_ASSIGN { $$ = 6; }
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
        | expression OR term {
            char* temp = new_temp();
            generate_code("||", $1, $3, temp);
            $$ = temp;
            free($1);
            free($3);
          }
        | expression GT term {
            char* temp = new_temp();
            generate_code(">", $1, $3, temp);
            $$ = temp;
            free($1);
            free($3);
          }
        | expression LT term {
            char* temp = new_temp();
            generate_code("<", $1, $3, temp);
            $$ = temp;
            free($1);
            free($3);
          }
        | expression AND term {
            char* temp = new_temp();
            generate_code("&&", $1, $3, temp);
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
    | term INTDIV factor {
        char* temp = new_temp();
        generate_code("//", $1, $3, temp);
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

factor: factor EXP unary {
        char* temp = new_temp();
        generate_code("**", $1, $3, temp);
        $$ = temp;
        free($1);
        free($3);
      }
    | unary { $$ = $1; }
    ;

unary: NOT unary {
        char* temp = new_temp();
        generate_unary_code("!", $2, temp);
        $$ = temp;
        free($2);
      }
    | SUB unary %prec UMINUS {
        char* temp = new_temp();
        generate_unary_code("-", $2, temp);
        $$ = temp;
        free($2);
      }
    | primary { $$ = $1; }
    ;

primary: ID { $$ = strdup($1); }
       | NUM { $$ = strdup($1); }
       | LPAREN expression RPAREN { $$ = $2; }
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