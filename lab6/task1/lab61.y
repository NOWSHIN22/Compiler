%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

extern FILE *yyin;
extern int yyparse();
extern int yylineno;

/* Symbol table and code generation structures */
typedef struct {
    char op;
    char arg1[50];
    char arg2[50];
    char result[50];
} ThreeAddressCode;

ThreeAddressCode tac_code[1000];
int temp_count = 1;
int tac_count = 0;

/* Function prototypes */
void generate_tac(char *result, char *arg1, char op, char *arg2);
void generate_assembly();
char* new_temp();
void print_tac();
void yyerror(const char *s);

%}

%union {
    int num_val;
    char *str_val;
}

%token <num_val> NUM
%token <str_val> ID OP_ASSIGN
%token NEW_LINE AND OR POWER INT_DIV GE LE EQ NE

/* Operator precedence */
%nonassoc '=' OP_ASSIGN
%left OR
%left AND
%nonassoc '!' 
%left '<' '>' LE GE EQ NE
%left '+' '-'
%left '*' '/' '%' INT_DIV
%right POWER
%nonassoc UMINUS

%type <str_val> expr

%%

program: stmt_list { print_tac(); generate_assembly(); return 0; }
    ;

stmt_list: stmt
    | stmt_list NEW_LINE stmt
    ;

stmt: ID '=' expr {
        if (strcmp($1, $3) != 0) {
            generate_tac($1, $3, '=', "");
        }
        free($1);
        free($3);
    }
    | ID OP_ASSIGN expr {
        char temp1[50], temp2[50];
        char op;
        
        if (strstr($2, "+=")) op = '+';
        else if (strstr($2, "-=")) op = '-';
        else if (strstr($2, "*=")) op = '*';
        else if (strstr($2, "/=")) op = '/';
        else if (strstr($2, "%=")) op = '%';
        else if (strstr($2, "**=")) op = '^';
        else if (strstr($2, "//=")) op = '\\';
        else op = '=';
        
        sprintf(temp1, "t%d", temp_count++);
        generate_tac(temp1, $3, op, "");
        
        sprintf(temp2, "t%d", temp_count++);
        generate_tac(temp2, $1, '+', temp1);
        
        generate_tac($1, temp2, '=', "");
        free($1);
        free($2);
        free($3);
    }
    ;

expr: expr OR expr {
        $$ = new_temp();
        generate_tac($$, $1, '|', $3);
        free($1);
        free($3);
    }
    | expr AND expr {
        $$ = new_temp();
        generate_tac($$, $1, '&', $3);
        free($1);
        free($3);
    }
    | expr '<' expr {
        $$ = new_temp();
        generate_tac($$, $1, '<', $3);
        free($1);
        free($3);
    }
    | expr '>' expr {
        $$ = new_temp();
        generate_tac($$, $1, '>', $3);
        free($1);
        free($3);
    }
    | expr LE expr {
        $$ = new_temp();
        generate_tac($$, $1, 'L', $3);
        free($1);
        free($3);
    }
    | expr GE expr {
        $$ = new_temp();
        generate_tac($$, $1, 'G', $3);
        free($1);
        free($3);
    }
    | expr EQ expr {
        $$ = new_temp();
        generate_tac($$, $1, 'E', $3);
        free($1);
        free($3);
    }
    | expr NE expr {
        $$ = new_temp();
        generate_tac($$, $1, 'N', $3);
        free($1);
        free($3);
    }
    | expr '+' expr {
        $$ = new_temp();
        generate_tac($$, $1, '+', $3);
        free($1);
        free($3);
    }
    | expr '-' expr {
        $$ = new_temp();
        generate_tac($$, $1, '-', $3);
        free($1);
        free($3);
    }
    | expr '*' expr {
        $$ = new_temp();
        generate_tac($$, $1, '*', $3);
        free($1);
        free($3);
    }
    | expr '/' expr {
        $$ = new_temp();
        generate_tac($$, $1, '/', $3);
        free($1);
        free($3);
    }
    | expr '%' expr {
        $$ = new_temp();
        generate_tac($$, $1, '%', $3);
        free($1);
        free($3);
    }
    | expr INT_DIV expr {
        $$ = new_temp();
        generate_tac($$, $1, '\\', $3);
        free($1);
        free($3);
    }
    | expr POWER expr {
        $$ = new_temp();
        generate_tac($$, $1, '^', $3);
        free($1);
        free($3);
    }
    | '!' expr {
        $$ = new_temp();
        generate_tac($$, $2, '!', "");
        free($2);
    }
    | '-' expr %prec UMINUS {
        $$ = new_temp();
        generate_tac($$, "0", '-', $2);
        free($2);
    }
    | '(' expr ')' {
        $$ = $2;
    }
    | ID {
        $$ = strdup($1);
        free($1);
    }
    | NUM {
        $$ = (char*)malloc(20);
        sprintf($$, "%d", $1);
    }
    ;

%%

/* Error handling function */
void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", yylineno, s);
}

void generate_tac(char *result, char *arg1, char op, char *arg2) {
    strcpy(tac_code[tac_count].result, result);
    strcpy(tac_code[tac_count].arg1, arg1);
    tac_code[tac_count].op = op;
    if (arg2 != NULL && strlen(arg2) > 0) {
        strcpy(tac_code[tac_count].arg2, arg2);
    } else {
        tac_code[tac_count].arg2[0] = '\0';
    }
    tac_count++;
}

char* new_temp() {
    char *temp = (char*)malloc(20);
    sprintf(temp, "t%d", temp_count++);
    return temp;
}

void print_tac() {
    int i;
    printf("Three-Address Code:\n");
    for (i = 0; i < tac_count; i++) {
        printf("%d ", i+1);
        if (tac_code[i].op == '=' && tac_code[i].arg2[0] == '\0') {
            printf("%s = %s\n", tac_code[i].result, tac_code[i].arg1);
        } else if (tac_code[i].op == '!') {
            printf("%s = ! %s\n", tac_code[i].result, tac_code[i].arg1);
        } else if (tac_code[i].arg2[0] != '\0') {
            if (tac_code[i].op == '<') printf("%s = %s < %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else if (tac_code[i].op == '>') printf("%s = %s > %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else if (tac_code[i].op == 'L') printf("%s = %s <= %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else if (tac_code[i].op == 'G') printf("%s = %s >= %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else if (tac_code[i].op == 'E') printf("%s = %s == %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else if (tac_code[i].op == 'N') printf("%s = %s != %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else if (tac_code[i].op == '|') printf("%s = %s || %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else if (tac_code[i].op == '&') printf("%s = %s && %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else if (tac_code[i].op == '\\') printf("%s = %s // %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else if (tac_code[i].op == '^') printf("%s = %s ** %s\n", tac_code[i].result, tac_code[i].arg1, tac_code[i].arg2);
            else printf("%s = %s %c %s\n", tac_code[i].result, tac_code[i].arg1, 
                   tac_code[i].op, tac_code[i].arg2);
        } else {
            printf("%s = %c %s\n", tac_code[i].result, tac_code[i].op, tac_code[i].arg1);
        }
    }
    printf("\n");
}

void generate_assembly() {
    int i, line_num;
    char op;
    char *arg1, *arg2, *result;
    
    printf("\nAssembly Code:\n");
    line_num = 1;
    
    for (i = 0; i < tac_count; i++) {
        op = tac_code[i].op;
        arg1 = tac_code[i].arg1;
        arg2 = tac_code[i].arg2;
        result = tac_code[i].result;
        
        if (op == '=' && tac_code[i].arg2[0] == '\0' && strcmp(arg1, result) != 0) {
            if (isdigit(arg1[0]) || (arg1[0] == '-' && isdigit(arg1[1]))) {
                printf("%d MOV R0, #%s\n", line_num++, arg1);
            } else {
                printf("%d MOV R0, %s\n", line_num++, arg1);
            }
            printf("%d MOV %s, R0\n", line_num++, result);
            continue;
        }
        
        switch(op) {
            case '+':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0]) || (arg2[0] == '-' && isdigit(arg2[1]))) {
                    printf("%d ADD R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d ADD R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '-':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0]) || (arg2[0] == '-' && isdigit(arg2[1]))) {
                    printf("%d SUB R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d SUB R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '*':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d MUL R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d MUL R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '/':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d DIV R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d DIV R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '\\':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d IDIV R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d IDIV R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '%':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d MOD R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d MOD R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '^':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d POW R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d POW R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '!':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                printf("%d NOT R0\n", line_num++);
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '&':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d AND R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d AND R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '|':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d OR R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d OR R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '<':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d CMPLT R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d CMPLT R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case '>':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d CMPGT R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d CMPGT R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case 'L':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d CMPLE R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d CMPLE R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case 'G':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d CMPGE R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d CMPGE R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case 'E':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d CMPEQ R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d CMPEQ R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
            case 'N':
                printf("%d MOV R0, %s\n", line_num++, arg1);
                if (isdigit(arg2[0])) {
                    printf("%d CMPNE R0, #%s\n", line_num++, arg2);
                } else {
                    printf("%d CMPNE R0, %s\n", line_num++, arg2);
                }
                printf("%d MOV %s, R0\n", line_num++, result);
                break;
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s input.txt\n", argv[0]);
        return 1;
    }
    
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Error: Cannot open file %s\n", argv[1]);
        return 1;
    }
    
    yyparse();
    
    fclose(yyin);
    return 0;
}