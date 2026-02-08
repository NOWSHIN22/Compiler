%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

extern FILE* yyin;
extern int yylex();
void yyerror(char* s);
int yyparse();

FILE *tac;
FILE *asmfile;

int tempCounter = 1;
int regCounter = 0;

char* createTemp() {
    char* temp = (char*)malloc(10);
    sprintf(temp, "t%d", tempCounter++);
    return temp;
}

char* assignReg() {
    char* reg = (char*)malloc(5);
    sprintf(reg, "R%d", regCounter++);
    return reg;
}

char* regStack[100];
int top = -1;

void push(char* x) {
    top++;
    regStack[top] = strdup(x);
}

char* pop() {
    if(top < 0) return NULL;
    char* topReg = regStack[top];
    top--;
    return topReg;
}

void emitTAC(char* dest, char* src1, char* op, char* src2) {
    if(src2 == NULL) {
        if(strcmp(op, "NEG") == 0 || strcmp(op, "UMINUS") == 0) {
            fprintf(tac, "%s = -%s\n", dest, src1);
        } else {
            fprintf(tac, "%s = %s(%s)\n", dest, op, src1);
        }
    } else if(strcmp(op, "pow") == 0) {
        fprintf(tac, "%s = %s(%s, %s)\n", dest, op, src1, src2);
    } else {
        fprintf(tac, "%s = %s %s %s\n", dest, src1, op, src2);
    }
}

void emitASM(char* op, char* arg1, char* arg2) {
    if(strcmp(op, "MOV") == 0) {
        fprintf(asmfile, "MOV %s, %s\n", arg1, arg2);
    } else if(strcmp(op, "ADD") == 0) {
        fprintf(asmfile, "ADD %s, %s\n", arg1, arg2);
    } else if(strcmp(op, "SUB") == 0) {
        fprintf(asmfile, "SUB %s, %s\n", arg1, arg2);
    } else if(strcmp(op, "MUL") == 0) {
        fprintf(asmfile, "MUL %s, %s\n", arg1, arg2);
    } else if(strcmp(op, "DIV") == 0) {
        fprintf(asmfile, "DIV %s, %s\n", arg1, arg2);
    } else if(strcmp(op, "MOD") == 0) {
        fprintf(asmfile, "MOD %s, %s\n", arg1, arg2);
    } else if(strcmp(op, "NEG") == 0) {
        fprintf(asmfile, "NEG %s\n", arg1);
    } else if(strcmp(op, "SQRT") == 0) {
        fprintf(asmfile, "SQRT %s\n", arg1);
    } else if(strcmp(op, "POW") == 0) {
        fprintf(asmfile, "POW %s, %s\n", arg1, arg2);
    } else if(strcmp(op, "LOG") == 0) {
        fprintf(asmfile, "LOG %s\n", arg1);
    } else if(strcmp(op, "EXP") == 0) {
        fprintf(asmfile, "EXP %s\n", arg1);
    } else if(strcmp(op, "SIN") == 0) {
        fprintf(asmfile, "SIN %s\n", arg1);
    } else if(strcmp(op, "COS") == 0) {
        fprintf(asmfile, "COS %s\n", arg1);
    } else if(strcmp(op, "TAN") == 0) {
        fprintf(asmfile, "TAN %s\n", arg1);
    } else if(strcmp(op, "ABS") == 0) {
        fprintf(asmfile, "ABS %s\n", arg1);
    }
}

%}

%union {
    char* str;
}

%token <str> ID NUM NL
%token SQRT POW LOG EXP SIN COS TAN ABS
%type <str> Expression Term Factor FunctionCall Primary

/* Operator precedence - FIXED to avoid conflicts */
%nonassoc UMINUS
%left '+' '-'
%left '*' '/' '%'
%right '='

%%

Program: Statements;

Statements: /* empty */
    | Statements Statement;

Statement: Assignment NL
    | NL;

Assignment: ID '=' Expression {
                // Reset counters for new statement
                tempCounter = 1;
                regCounter = 0;
                top = -1;
                
                // Emit TAC
                fprintf(tac, "%s = %s\n", $1, $3);
                
                // Emit assembly
                char* resultReg = pop();
                if(resultReg) {
                    emitASM("MOV", $1, resultReg);
                    fprintf(asmfile, "\n");
                }
                
                free($1);
                free($3);
            };

Expression: Expression '+' Term {
                char* temp = createTemp();
                emitTAC(temp, $1, "+", $3);
                
                // Assembly
                char* reg2 = pop();
                char* reg1 = pop();
                if(reg1 && reg2) {
                    emitASM("ADD", reg1, reg2);
                    push(reg1);
                }
                
                $$ = temp;
                free($1);
                free($3);
            }
    | Expression '-' Term {
                char* temp = createTemp();
                emitTAC(temp, $1, "-", $3);
                
                // Assembly
                char* reg2 = pop();
                char* reg1 = pop();
                if(reg1 && reg2) {
                    emitASM("SUB", reg1, reg2);
                    push(reg1);
                }
                
                $$ = temp;
                free($1);
                free($3);
            }
    | Term { $$ = $1; };

Term: Term '*' Factor {
                char* temp = createTemp();
                emitTAC(temp, $1, "*", $3);
                
                // Assembly
                char* reg2 = pop();
                char* reg1 = pop();
                if(reg1 && reg2) {
                    emitASM("MUL", reg1, reg2);
                    push(reg1);
                }
                
                $$ = temp;
                free($1);
                free($3);
            }
    | Term '/' Factor {
                char* temp = createTemp();
                emitTAC(temp, $1, "/", $3);
                
                // Assembly
                char* reg2 = pop();
                char* reg1 = pop();
                if(reg1 && reg2) {
                    emitASM("DIV", reg1, reg2);
                    push(reg1);
                }
                
                $$ = temp;
                free($1);
                free($3);
            }
    | Term '%' Factor {
                char* temp = createTemp();
                emitTAC(temp, $1, "%", $3);
                
                // Assembly
                char* reg2 = pop();
                char* reg1 = pop();
                if(reg1 && reg2) {
                    emitASM("MOD", reg1, reg2);
                    push(reg1);
                }
                
                $$ = temp;
                free($1);
                free($3);
            }
    | Factor { $$ = $1; };

Factor: '-' Factor %prec UMINUS {
                char* temp = createTemp();
                emitTAC(temp, $2, "UMINUS", NULL);
                
                // Assembly
                char* reg = pop();
                if(reg) {
                    emitASM("NEG", reg, NULL);
                    push(reg);
                }
                
                $$ = temp;
                free($2);
            }
    | Primary { $$ = $1; };

Primary: '(' Expression ')' { $$ = $2; }
    | FunctionCall { $$ = $1; }
    | ID {
                // For TAC
                $$ = strdup($1);
                
                // For assembly - load into register
                char* reg = assignReg();
                emitASM("MOV", reg, $1);
                push(reg);
                
                free($1);
            }
    | NUM {
                // For TAC
                $$ = strdup($1);
                
                // For assembly - load immediate into register
                char* reg = assignReg();
                char imm[20];
                sprintf(imm, "#%s", $1);
                emitASM("MOV", reg, imm);
                push(reg);
                
                free($1);
            };

FunctionCall: SQRT '(' Expression ')' {
                char* temp = createTemp();
                emitTAC(temp, $3, "sqrt", NULL);
                
                // Assembly
                char* reg = pop();
                if(reg) {
                    emitASM("SQRT", reg, NULL);
                    push(reg);
                }
                
                $$ = temp;
                free($3);
            }
    | POW '(' Expression ',' Expression ')' {
                char* temp = createTemp();
                emitTAC(temp, $3, "pow", $5);
                
                // Assembly
                char* reg2 = pop();
                char* reg1 = pop();
                if(reg1 && reg2) {
                    emitASM("POW", reg1, reg2);
                    push(reg1);
                }
                
                $$ = temp;
                free($3);
                free($5);
            }
    | LOG '(' Expression ')' {
                char* temp = createTemp();
                emitTAC(temp, $3, "log", NULL);
                
                // Assembly
                char* reg = pop();
                if(reg) {
                    emitASM("LOG", reg, NULL);
                    push(reg);
                }
                
                $$ = temp;
                free($3);
            }
    | EXP '(' Expression ')' {
                char* temp = createTemp();
                emitTAC(temp, $3, "exp", NULL);
                
                // Assembly
                char* reg = pop();
                if(reg) {
                    emitASM("EXP", reg, NULL);
                    push(reg);
                }
                
                $$ = temp;
                free($3);
            }
    | SIN '(' Expression ')' {
                char* temp = createTemp();
                emitTAC(temp, $3, "sin", NULL);
                
                // Assembly
                char* reg = pop();
                if(reg) {
                    emitASM("SIN", reg, NULL);
                    push(reg);
                }
                
                $$ = temp;
                free($3);
            }
    | COS '(' Expression ')' {
                char* temp = createTemp();
                emitTAC(temp, $3, "cos", NULL);
                
                // Assembly
                char* reg = pop();
                if(reg) {
                    emitASM("COS", reg, NULL);
                    push(reg);
                }
                
                $$ = temp;
                free($3);
            }
    | TAN '(' Expression ')' {
                char* temp = createTemp();
                emitTAC(temp, $3, "tan", NULL);
                
                // Assembly
                char* reg = pop();
                if(reg) {
                    emitASM("TAN", reg, NULL);
                    push(reg);
                }
                
                $$ = temp;
                free($3);
            }
    | ABS '(' Expression ')' {
                char* temp = createTemp();
                emitTAC(temp, $3, "abs", NULL);
                
                // Assembly
                char* reg = pop();
                if(reg) {
                    emitASM("ABS", reg, NULL);
                    push(reg);
                }
                
                $$ = temp;
                free($3);
            };

%%

void yyerror(char* s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char* argv[]) {
    // Open input file
    if(argc > 1) {
        yyin = fopen(argv[1], "r");
        if(!yyin) {
            printf("Error: Cannot open file %s\n", argv[1]);
            return 1;
        }
    } else {
        yyin = fopen("input.txt", "r");
        if(!yyin) {
            printf("Error: Cannot open input.txt\n");
            return 1;
        }
    }
    
    // Open output files
    tac = fopen("tac.txt", "w");
    asmfile = fopen("assembly.txt", "w");
    
    if(!tac || !asmfile) {
        printf("Error: Cannot open output files\n");
        return 1;
    }
    
    // Parse input
    yyparse();
    
    // Close files
    fclose(tac);
    fclose(asmfile);
    fclose(yyin);
    
    return 0;
}