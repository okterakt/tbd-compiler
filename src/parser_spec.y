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
    if (entry == NULL){
        yyerror("Can't allocate the memory!");
        exit(0);
    }
    entry->name = name;
    g_hash_table_insert(symtab, entry->name, entry);
    return entry;
}

Addr *newaddr(Entry *entry)
{
    Addr *addr = malloc(sizeof(*addr));
    if (addr == NULL){
        yyerror("Can't allocate the memory!");
        exit(0);
    }
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

void emit1(Expression *exp, Expression *res)
{
    if (exp->addr->addrvaluetype == ENTRYPTR_TYPE)
    {
        printf("%s = %s\n",
            res->addr->addrvalue.entry->name,
            exp->addr->addrvalue.entry->name);
    }
    else
    {
        printf("%s = %d\n",
            res->addr->addrvalue.entry->name,
            exp->addr->addrvalue.intval);
    }
}

void emit2(char *op, Expression *exp1, Expression *exp2, Expression *res)
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

%union
{
    Statement *stmt;
    Expression *expr;
    char *name;
    int intval;
}

%type <stmt> statement
%type <expr> expression
%token <intval> TK_INT_LIT
%token <name> TK_IDEN
%token TK_IF TK_VAR TK_EXIT

%nonassoc TK_VAR
%left TK_EQ TK_NE
%left '<' '>' TK_LE TK_GE
%left '+' '-'
%left '*' '/'
%nonassoc TK_UMINUS

%%
statements: statements statement
|           statement
;

statement:  TK_VAR TK_IDEN ';'
            {
                newentry($2);
                Statement *stmt = malloc(sizeof(*stmt));
                $$ = stmt;
            }
|           TK_IDEN '=' expression ';'
            {
                Expression *expr = malloc(sizeof(*expr));
                Entry *entry = g_hash_table_lookup(symtab, $1);
                if (entry)
                {
                    expr->addr = newaddr(entry);
                    emit1($3, expr);
                }
                else
                {
                    fprintf(stderr, "Name not found in symbol table");
                    exit(0);
                }
                Statement *stmt = malloc(sizeof(*stmt));
                $$ = stmt;
            }
|           TK_IF '(' expression ')' '{' statement '}'
            {
                // printf("if (%d) { some statement }", $1);
            }
|           expression ';'
            {
                Statement *stmt = malloc(sizeof(*stmt));
                $$ = stmt;
            }
;

expression: expression '+' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                emit2("+", $1, $3, $$);
            }
|           expression '-' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                emit2("-", $1, $3, $$);
            }
|           expression '*' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                emit2("*", $1, $3, $$);
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
                Entry *entry = g_hash_table_lookup(symtab, yylval.name);
                if (entry)
                {
                    expr->addr = newaddr(entry);
                }
                else
                {
                    yyerror( "Name not found in symbol table");
                    exit(0);
                }
                $$ = expr;
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
|           TK_EXIT {
                printf("Exiting\n");
                exit(0);
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