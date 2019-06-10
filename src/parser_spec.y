%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gmodule.h>
#include "def.h"

GHashTable *symtab;
static int globoffset;
static int tempcounter;


void yyerror (char *s);
int yylex();
extern int yylineno; // export from yacc

// -------- stuff --------

Entry *newentry(char *name)
{
    Entry *entry = malloc(sizeof(*entry));
    entry->name = name;
    g_hash_table_insert(symtab, entry->name, entry);
    return entry;
}

Addr *newaddr(Entry *entry)
{
    Addr *addr = malloc(sizeof(*addr));
    addr->addrvalue.entry = entry;
    addr->addrvaluetype = ENTRYPTR_TYPE;
    return addr;
}

Addr *newtemp()
{
    char *temp = malloc(sizeof(*temp) * 13);
    sprintf(temp, "t%d", tempcounter++);
    return newaddr(newentry(temp));
}

void emit(char *op, Expression *exp1, Expression *exp2, Expression *res)
{
    if (exp1->addr->addrvaluetype == ENTRYPTR_TYPE)
    {
        if (exp2->addr->addrvaluetype == ENTRYPTR_TYPE)
            printf("%s = %s %s %s\n",
                res->addr->addrvalue.entry->name,
                exp1->addr->addrvalue.entry->name,
                op,
                exp2->addr->addrvalue.entry->name);
        else printf("%s = %s %s %d\n",
                res->addr->addrvalue.entry->name,
                exp1->addr->addrvalue.entry->name,
                op,
                exp2->addr->addrvalue.intval); 
    }
    else
    {
        if (exp2->addr->addrvaluetype == ENTRYPTR_TYPE)
            printf("%s = %d %s %s\n",
                res->addr->addrvalue.entry->name,
                exp1->addr->addrvalue.intval,
                op,
                exp2->addr->addrvalue.entry->name);
        else printf("%s = %d %s %d\n",
                res->addr->addrvalue.entry->name,
                exp1->addr->addrvalue.intval,
                op,
                exp2->addr->addrvalue.intval);
    }
}

%}

/*
statement:  TK_IDEN '=' expression 
            {
            }
|           TK_IF '(' expression ')' '{' statement '}'
            {
                printf("if (%d) { some statement }", $1);
            }
|           expression
;
*/

%union
{
    Expression *expr;
    char *name;
    int intval;
}

// %type <stmt> statement
%type <expr> expression
%token <intval> TK_INT_LIT
%token <name> TK_IDEN
%token TK_IF
%left TK_EQ TK_NE
%left '<' '>' TK_LE TK_GE
%left '+' '-'
%left '*' '/'
%nonassoc TK_UMINUS

%%


expression: expression '+' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                emit("+", $1, $3, $$);
            }
|           expression '-' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                emit("-", $1, $3, $$);
            }
|           expression '*' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                emit("*", $1, $3, $$);
            }
// |           expression '<' expression       { $$ = $1 < $3; }
// |           expression '>' expression       { $$ = $1 > $3; }
// |           expression TK_EQ expression     { $$ = $1 == $3; }
// |           expression TK_NE expression     { $$ = $1 != $3; }
// |           expression TK_LE expression     { $$ = $1 <= $3; }
// |           expression TK_GE expression     { $$ = $1 >= $3; }
|           '-' expression %prec TK_UMINUS
            {
                // $$->addr = malloc(sizeof($$->addr));
                // newtemp($$->addr);
                // if ($2->addr->addrvaluetype == ENTRYPTR_TYPE)
                //     printf("%s = -%s", $$->addr->addrvalue.entry->name, $2->addr->addrvalue.entry->name);
                // else printf("%s = -%d", $$->addr->addrvalue.entry->name, $2->addr->addrvalue.intval);
            }
|           '(' expression ')'
            {
                // $$->addr = $2->addr;
            }
|           TK_IDEN
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newaddr(newentry($1));
                $$ = expr;

                // TODO move to lexer
                // Entry *p = g_hash_table_lookup(symtab, $1->name);
                // if (p)
                // {
                // }
                // else error
            }
|           TK_INT_LIT
            {
                Expression *expr = malloc(sizeof(*expr));
                Addr *addr = malloc(sizeof(*addr));
                expr->addr = addr;
                expr->addr->addrvalue.intval = yylval.intval;
                expr->addr->addrvaluetype = INT_TYPE;
                $$ = expr;
            }
;

%%

int main(void)
{
    tempcounter = 0;
    symtab = g_hash_table_new(g_str_hash, g_str_equal);
    yyparse();

    return 0;
}

void yyerror (char *s) {
	fprintf (stderr, "\nError at line %d: %s\n\n", yylineno, s);
}