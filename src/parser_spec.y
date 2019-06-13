%{
#include "../include/def.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gmodule.h>

static GHashTable *symtab;
static GPtrArray *quadarray;
static int tempcounter;
static int nextquad;
char *emptystr;

void yyerror(char *s);
int yylex();
extern int yylineno;

void printquad(Quad *quad)
{
    if (quad->quadtype == UNASSIG_TYPE)
        printf("%s = %s%s\n", quad->result, quad->op, quad->arg2);
    else if (quad->quadtype == BINASSIG_TYPE)
        printf("%s = %s %s %s\n", quad->result, quad->arg1, quad->op, quad->arg2);
    else if (quad->quadtype == IFGOTO_TYPE)
        printf("if %s %s %s goto %s\n", quad->arg1, quad->op, quad->arg2, quad->result);
    else
        printf("goto %s\n", quad->result); // GOTO_TYPE
}

void printlist(GSList *list)
{
    GSList *l = list;
    while (l != NULL)
    {
        printf("%d  ", GPOINTER_TO_INT(l->data));
        l = l->next;
    }
    printf("\n");
}

void printcode()
{
    for (int i = 0; i < quadarray->len; i++)
    {
        Quad *quad = g_ptr_array_index(quadarray, i);
        printf("%d:\t", i);
        printquad(quad);
    }
}

SymEntry *newsymentry(char *name)
{
    SymEntry *entry = malloc(sizeof(*entry));
    entry->name = name;
    g_hash_table_insert(symtab, entry->name, entry);
    return entry;
}

Addr *newaddr(SymEntry *entry)
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
    int len = 14;
    char *temp = malloc(sizeof(*temp) * len);
    snprintf(temp, len, "t%d", tempcounter++);
    return newaddr(newsymentry(temp));
}

char *concat(char *str1, char *str2)
{
    int len = snprintf(NULL, 0, "%s%s", str1, str2);
    char *res = malloc(sizeof(*res) * len + 1);
    snprintf(res, len + 1, "%s%s", str1, str2);
    return res;
}

char *inttostr(int i)
{
    int len = 13;
    char *str = malloc(sizeof(*str) * len);
    snprintf(str, len, "%d", i);
    return str;
}

char *addrtostr(Addr *addr)
{
    if (addr->addrvaluetype == ENTRYPTR_TYPE)
        return addr->addrvalue.entry->name;
    else
        return inttostr(addr->addrvalue.intval);
}

Quad *makequad(char *op, char *arg1, char *arg2, char *result, enum QuadType quadtype)
{
    Quad *quad = malloc(sizeof(*quad));
    // TODO: print something before exit
    if (quad == NULL)
        exit(0); 
    quad->op = op;
    quad->arg1 = arg1;
    quad->arg2 = arg2;
    quad->result = result;
    quad->quadtype = quadtype;
    g_ptr_array_add(quadarray, quad);
    nextquad++;
    return quad;
}

GSList *makelist(int i)
{
    GSList *list = NULL;
    return g_slist_prepend(list, GINT_TO_POINTER(i));
}

GSList *merge(GSList *list1, GSList *list2)
{
    return g_slist_concat(list1, list2);
}

void backpatch(GSList *list, int i)
{
    GSList *l = list;
    Quad *quad;
    while (l != NULL)
    {
        quad = g_ptr_array_index(quadarray, GPOINTER_TO_INT(l->data));
        quad->result = inttostr(i);
        l = l->next;
    }
}
%}

%union
{
    Program *prgm;
    Statement *stmt;
    Expression *expr;
    BoolExpr *bexpr;
    char *str;
    int intval;
}

%type <prgm> program
%type <stmt> statement
%type <expr> expression
%type <bexpr> boolexpr
%token <intval> TK_INT_LIT
%token <str> TK_IDEN
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

program:    program 
            {
                backpatch($1->nextlist, nextquad);
            }
            statement
            {
                Program *prgm = malloc(sizeof(*prgm));
                prgm->nextlist = $3->nextlist;
                $$ = prgm;
                printcode();
            }
|           statement
            {
                Program *prgm = malloc(sizeof(*prgm));
                prgm->nextlist = $1->nextlist;
                $$ = prgm;
            }
;

statement:  TK_VAR TK_IDEN ';'
            {
                newsymentry($2);
                Statement *stmt = malloc(sizeof(*stmt));
                stmt->nextlist = NULL;
                $$ = stmt;
            }
|           TK_IDEN '=' expression ';'
            {
                Statement *stmt = malloc(sizeof(*stmt));                
                SymEntry *entry = g_hash_table_lookup(symtab, $1);
                if (entry)
                {
                    stmt->nextlist = NULL;
                    makequad(emptystr, emptystr, addrtostr($3->addr), entry->name, UNASSIG_TYPE);
                }
                else
                {
                    fprintf(stderr, "Attempted use of undeclared variable\n");
                    exit(0);
                }
                $$ = stmt;
            }
|           TK_IF '(' boolexpr ')' '{'
            {
                backpatch($3->truelist, nextquad);
            }
            statement '}'
            {
                Statement *stmt = malloc(sizeof(*stmt));
                stmt->nextlist = merge($3->falselist, $7->nextlist);
                $$ = stmt;
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
                makequad(strdup("+"), addrtostr($1->addr),
                    addrtostr($3->addr), addrtostr($$->addr), BINASSIG_TYPE);
            }
|           expression '-' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                makequad(strdup("-"), addrtostr($1->addr),
                    addrtostr($3->addr), addrtostr($$->addr), BINASSIG_TYPE);
            }
|           expression '*' expression
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                makequad(strdup("*"), addrtostr($1->addr),
                    addrtostr($3->addr), addrtostr($$->addr), BINASSIG_TYPE);
            }
|           '-' expression %prec TK_UMINUS
            {
                Expression *expr = malloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                makequad(strdup("-"), emptystr, addrtostr($2->addr), addrtostr($$->addr), UNASSIG_TYPE);
            }
|           '(' expression ')'
            {
                $$ = $2;
            }
|           TK_IDEN
            {
                Expression *expr = malloc(sizeof(*expr));
                SymEntry *entry = g_hash_table_lookup(symtab, yylval.str);
                if (entry)
                {
                    expr->addr = newaddr(entry);
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
                addr->addrvalue.intval = yylval.intval;
                addr->addrvaluetype = INT_TYPE;
                expr->addr = addr;
                $$ = expr;
            }
;

boolexpr:   boolexpr TK_AND 
            {
                backpatch($1->truelist, nextquad);
            }
            boolexpr
            {
                BoolExpr *bexpr = malloc(sizeof(*bexpr));
                bexpr->truelist = $4->truelist;
                bexpr->falselist = merge($1->falselist, $4->falselist);
                $$ = bexpr;
            }
|           boolexpr TK_OR 
            {
                backpatch($1->truelist, nextquad);
            }
            boolexpr
            {
                BoolExpr *bexpr = malloc(sizeof(*bexpr));
                bexpr->truelist = merge($1->truelist, $4->truelist);
                bexpr->falselist = $4->falselist;
                $$ = bexpr;
            }
|           TK_NOT boolexpr
            {
                BoolExpr *bexpr = malloc(sizeof(*bexpr));
                bexpr->truelist = $2->falselist;
                bexpr->falselist = $2->truelist;
                $$ = bexpr;
            }
|           '(' boolexpr ')'
            {
                BoolExpr *bexpr = malloc(sizeof(*bexpr));
                bexpr->truelist = $2->truelist;
                bexpr->falselist = $2->falselist;
                $$ = bexpr;
            }
|           expression '<' expression
            {
                BoolExpr *bexpr = malloc(sizeof(*bexpr));
                bexpr->truelist = makelist(nextquad);
                bexpr->falselist = makelist(nextquad + 1);
                makequad(strdup("<"), addrtostr($1->addr), addrtostr($3->addr), emptystr, IFGOTO_TYPE);
                makequad(emptystr, emptystr, emptystr, emptystr, GOTO_TYPE);
                $$ = bexpr;
            }
// |           expression '>' expression       { $$ = $1 > $3; }
// |           expression TK_EQ expression     { $$ = $1 == $3; }
// |           expression TK_NE expression     { $$ = $1 != $3; }
// |           expression TK_LE expression     { $$ = $1 <= $3; }
// |           expression TK_GE expression     { $$ = $1 >= $3; }
%%

int main(void)
{
    emptystr = strdup("");
    tempcounter = 0;
    nextquad = 0;
    symtab = g_hash_table_new(g_str_hash, g_str_equal);
    quadarray = g_ptr_array_new();
    yyparse();

    return 0;
}

void yyerror (char *s)
{
	fprintf(stderr, "\nError at line %d: %s\n\n", yylineno, s);
}