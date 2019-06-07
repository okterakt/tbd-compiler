%{
#include <stdio.h>
%}

%token TK_INT_LIT
%token TK_IDEN
%token TK_EQ
%token TK_NE
%token TK_LE
%token TK_GE
%token TK_IF
%left TK_EQ TK_NE
%left '<' '>' TK_LE TK_GE
%left '+' '-'
%left '*' '/'
%nonassoc TK_UMINUS

%%
statement:  TK_IDEN '=' expression 
            {
                printf("=%d\n", $1);
            }
|           TK_IF '(' expression ')' '{' statement '}'
            {
                printf("if (%d) { some statement }", $1);
            }
|           expression
;

expression: TK_INT_LIT                      {
                                                printf("lit: %d\n", $1);
                                                $$ = yylval;
                                            }
|           TK_IDEN                         { $$ = yylval; /*TODO: get value of identifier*/ }
|           '(' expression ')'              { $$ = $2; }
|           expression '+' expression       { $$ = $1 + $3; }
|           expression '-' expression       { $$ = $1 - $3; }
|           expression '*' expression       { $$ = $1 * $3; }
|           expression '<' expression       { $$ = $1 < $3; }
|           expression '>' expression       { $$ = $1 > $3; }
|           expression TK_EQ expression     { $$ = $1 == $3; }
|           expression TK_NE expression     { $$ = $1 != $3; }
|           expression TK_LE expression     { $$ = $1 <= $3; }
|           expression TK_GE expression     { $$ = $1 >= $3; }
|           '-' expression %prec TK_UMINUS  { $$ = -$2; }
;