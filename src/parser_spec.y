%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gmodule.h>
#include "def.h"

GHashTable *symtab;
static int globoffset;
static int tempcounter;
static int labelcounter;

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
    int len = 14;
    char *temp = malloc(sizeof(*temp) * len);
    snprintf(temp, len, "t%d", tempcounter++);
    return newaddr(newentry(temp));
}

char *newlabel()
{
    char *label = malloc(sizeof(*label) * 13);
    sprintf(label, "L%d", labelcounter++);
    return label;
}

void emitunop(char *op, Expression *exp, Expression *res)
{
    if (exp->addr->addrvaluetype == ENTRYPTR_TYPE)
    {
        printf("%s = %s%s\n",
            res->addr->addrvalue.entry->name,
            op,
            exp->addr->addrvalue.entry->name);
    }
    else
    {
        printf("%s = %s%d\n",
            res->addr->addrvalue.entry->name,
            op,
            exp->addr->addrvalue.intval);
    }
}

void emitbinop(char *op, Expression *exp1, Expression *exp2, Expression *res)
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

void emitgoto(char *label)
{

}

char *genunop(char *op, Addr *addr, Addr *res)
{
    int len = 0;
    char *gencode;
    if (addr->addrvaluetype == ENTRYPTR_TYPE)
    {
        len = snprintf(NULL, 0, "%s = %s%s\n",
            res->addrvalue.entry->name,
            op,
            addr->addrvalue.entry->name);
        gencode = malloc(sizeof(*gencode) * len + 1);
        snprintf(gencode, len + 1, "%s = %s%s\n",
            res->addrvalue.entry->name,
            op,
            addr->addrvalue.entry->name);
    }
    else
    {
        len = snprintf(NULL, 0, "%s = %s%d\n",
            res->addrvalue.entry->name,
            op,
            addr->addrvalue.intval);
        gencode = malloc(sizeof(*gencode) * len + 1);
        snprintf(gencode, len + 1, "%s = %s%d\n",
            res->addrvalue.entry->name,
            op,
            addr->addrvalue.intval);
    }
    return gencode;
}

char *genbinop(char *op, Addr *addr1, Addr *addr2, Addr *res)
{
    int len = 0;
    char *gencode;
    if (addr1->addrvaluetype == ENTRYPTR_TYPE)
    {
        if (addr2->addrvaluetype == ENTRYPTR_TYPE)
        {
            len = snprintf(NULL, 0, "%s = %s %s %s\n",
                res->addrvalue.entry->name,
                addr1->addrvalue.entry->name,
                op,
                addr2->addrvalue.entry->name);
            gencode = malloc(sizeof(*gencode) * len + 1);
            snprintf(gencode, len + 1, "%s = %s %s %s\n",
                res->addrvalue.entry->name,
                addr1->addrvalue.entry->name,
                op,
                addr2->addrvalue.entry->name);
        }
        else
        {
            len = snprintf(NULL, 0, "%s = %s %s %d\n",
                res->addrvalue.entry->name,
                addr1->addrvalue.entry->name,
                op,
                addr2->addrvalue.intval);
            gencode = malloc(sizeof(*gencode) * len + 1);
            snprintf(gencode, len + 1, "%s = %s %s %d\n",
                res->addrvalue.entry->name,
                addr1->addrvalue.entry->name,
                op,
                addr2->addrvalue.intval);
        }
    }
    else
    {
        if (addr2->addrvaluetype == ENTRYPTR_TYPE)
        {
            len = snprintf(NULL, 0, "%s = %d %s %s\n",
                res->addrvalue.entry->name,
                addr1->addrvalue.intval,
                op,
                addr2->addrvalue.entry->name);
            gencode = malloc(sizeof(*gencode) * len + 1);
            snprintf(gencode, len + 1, "%s = %d %s %s\n",
                res->addrvalue.entry->name,
                addr1->addrvalue.intval,
                op,
                addr2->addrvalue.entry->name);
        }
        else
        {
            len = snprintf(NULL, 0, "%s = %d %s %d\n",
                res->addrvalue.entry->name,
                addr1->addrvalue.intval,
                op,
                addr2->addrvalue.intval);
            gencode = malloc(sizeof(*gencode) * len + 1);
            snprintf(gencode, len + 1, "%s = %d %s %d\n",
                res->addrvalue.entry->name,
                addr1->addrvalue.intval,
                op,
                addr2->addrvalue.intval);
        }
    }
    return gencode;
}

char *gengoto()
{

}

char *genlabel(char *label)
{   
    int len = snprintf(NULL, 0, "%s:\n", label);
    char *gencode = malloc(sizeof(*gencode) * len + 1);
    snprintf(gencode, len + 1, "%s:\n", label);
    return gencode;
}

char *concat(char *str1, char *str2)
{
    int len = snprintf(NULL, 0, "%s%s", str1, str2);
    char *res = malloc(sizeof(*res) * len + 1);
    snprintf(res, len + 1, "%s%s", str1, str2);
    return res;
}
%}

%union
{
    Program *prgm;
    Statement *stmt;
    Expression *expr;
    char *name;
    int intval;
}

%type <prgm> program
%type <stmt> statement
%type <expr> expression
%token <intval> TK_INT_LIT
%token <name> TK_IDEN
%token TK_IF
%nonassoc TK_VAR
%left TK_OR
%left TK_AND
%left TK_EQ TK_NE
%left '<' '>' TK_LE TK_GE
%left '+' '-'
%left '*' '/'
%right TK_NOT
%nonassoc TK_UMINUS

%%
program: 
            {
                $<name>$ = newlabel();
                printf("S.next: %s\n", $<name>$);
            }
            statement
            {
                Program *prgm = malloc(sizeof(*prgm));
                $<stmt>2->labnext = $<name>1;
                prgm->code = concat($2->code, genlabel($2->labnext));
                $<prgm>$ = prgm;
                printf("%s\n", prgm->code);
            }
;

statement:  TK_VAR TK_IDEN ';'
            {
                newentry($2);
                Statement *stmt = malloc(sizeof(*stmt));
                stmt->code = strdup("");
                $$ = stmt;
            }
|           TK_IDEN '=' expression ';'
            {
                Statement *stmt = malloc(sizeof(*stmt));
                Expression *expr = malloc(sizeof(*expr));
                Entry *entry = g_hash_table_lookup(symtab, $1);
                if (entry)
                {
                    expr->addr = newaddr(entry);
                    stmt->code = concat($3->code, genunop("", $3->addr, expr->addr));
                    // emitunop("", $3, expr);
                }
                else
                {
                    fprintf(stderr, "Attempted use of undeclared variable\n");
                    exit(0);
                }
                // printf("gen: %s", stmt->code);
                $$ = stmt;
            }
|           TK_IF
            {
                Expression *tmpexpr = malloc(sizeof(tmpexpr));
                tmpexpr->labtrue = newlabel();
                tmpexpr->labfalse = $<name>0;
                $<expr>$ = tmpexpr;
            }
            '(' expression ')'
            {
                $4->labtrue = $<expr>2->labtrue;
                $4->labfalse = $<expr>2->labfalse;
                $<expr>$ = $4;
            }
            '{' statement '}'
            {
                $8->labnext = $<name>0;
                Statement *stmt = malloc(sizeof(*stmt));
                stmt->code = concat(concat($4->code, genlabel($4->labtrue)), $8->code);
                $$ = stmt;
                printf("E.true: %s\n", $4->labtrue);
                printf("E.false: %s\n", $4->labfalse);
            }
|           expression ';'
            {
                Statement *stmt = malloc(sizeof(*stmt));
                stmt->code = $1->code;
                $$ = stmt;
            }
;

expression: expression '+' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                expr->code = concat(concat($1->code, $3->code),
                    genbinop("+", $1->addr, $3->addr, expr->addr));
                // emitbinop("+", $1, $3, $$);
            }
|           expression '-' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                expr->code = concat(concat($1->code, $3->code),
                    genbinop("-", $1->addr, $3->addr, expr->addr));
                $$ = expr;
                // emitbinop("-", $1, $3, $$);
            }
|           expression '*' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                expr->code = concat(concat($1->code, $3->code),
                    genbinop("*", $1->addr, $3->addr, expr->addr));
                $$ = expr;
                // emitbinop("*", $1, $3, $$);
            }
|           expression '<' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                
            }
// |           expression '>' expression       { $$ = $1 > $3; }
// |           expression TK_EQ expression     { $$ = $1 == $3; }
// |           expression TK_NE expression     { $$ = $1 != $3; }
// |           expression TK_LE expression     { $$ = $1 <= $3; }
// |           expression TK_GE expression     { $$ = $1 >= $3; }
|           '-' expression %prec TK_UMINUS
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                char *gen = genunop("-", $2->addr, expr->addr);
                expr->code = concat($2->code, gen);
                $$ = expr;
                // emitunop("-", $2, $$);
            }
|           {
                // E1.true := newlabel(); E1.false := E.false;
                Expression *tmpexpr = malloc(sizeof(*tmpexpr));
                tmpexpr->labtrue = newlabel();
                tmpexpr->labfalse = $<expr>0->labfalse;
                $<expr>$ = tmpexpr;
            }
            expression
            {
                $2->labtrue = $<expr>1->labtrue;
                $2->labfalse = $<expr>1->labfalse;
                // E2.true := E.true; E2.false := E.false; 
                // reuse previous expression and set only E2.true; E2.false = E1.false = E.false
                $<expr>$ = $<expr>1;
                $<expr>$->labtrue = $<expr>0->labtrue;
            }
            TK_AND expression
            {
                $<expr>5->labtrue = $<expr>3->labtrue;
                $<expr>5->labfalse = $<expr>3->labfalse;
                Expression *expr = malloc(sizeof(*expr));
                expr->code = concat(concat($<expr>2->code,
                                genlabel($<expr>2->labtrue)), $<expr>5->code);
                // E.code := E1.code || gen(E1.true ′:′) || E2.code
                $<expr>$ = expr;
            }
|           TK_NOT 
            {
                $<expr>$ = $<expr>-1;
            }
            expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->labtrue = $<expr>2->labfalse;
                expr->labfalse = $<expr>2->labtrue;
                expr->addr = $<expr>3->addr;
                expr->code = $<expr>3->code;
                $<expr>$ = expr;
            }
|           '('
            {
                $<expr>$ = $<expr>-1;
            }
            expression ')'
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->labtrue = $<expr>2->labtrue;
                expr->labfalse = $<expr>2->labfalse;
                expr->addr = $<expr>3->addr;
                expr->code = $<expr>3->code;
                $<expr>$ = expr;
            }
|           TK_IDEN
            {
                Expression *expr = malloc(sizeof(*expr));
                Entry *entry = g_hash_table_lookup(symtab, yylval.name);
                if (entry)
                {
                    expr->addr = newaddr(entry);
                    expr->code = strdup("");
                }
                else
                {
                    fprintf(stderr, "Attempted use of undeclared variable\n");
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
                expr->code = strdup("");
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