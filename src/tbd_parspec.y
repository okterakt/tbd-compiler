%{
#include "../include/util.h"
#include "../include/def.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static GHashTable *symtab;
static GPtrArray *quadarray;
static int tempcounter;
static int nextquad;
char *emptystr;

FILE *yyin;
void yyerror(const char *msg);
int yylex();
extern int yylineno;

SymEntry *newsymentry(char *name)
{
    SymEntry *entry = safemalloc(sizeof(*entry));
    entry->name = name;
    g_hash_table_insert(symtab, entry->name, entry);
    return entry;
}

Addr *newaddr(SymEntry *entry)
{
    Addr *addr = safemalloc(sizeof(*addr));
    addr->addrvalue.entry = entry;
    addr->addrvaluetype = ENTRYPTR_TYPE;
    return addr;
}

Addr *newtemp()
{
    int len = 14;
    char *temp = safemalloc(sizeof(*temp) * len);
    snprintf(temp, len, "t%d", tempcounter++);
    return newaddr(newsymentry(temp));
}

Quad *makequad(char *op, char *arg1, char *arg2, char *result, enum QuadType quadtype)
{
    Quad *quad = safemalloc(sizeof(*quad));
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
    Statements *stmts;
    Statement *stmt;
    Expression *expr;
    BoolExpr *bexpr;
    char *str;
    int intval;
}

%type <stmts> statements
%type <stmt> statement
%type <expr> expression
%type <bexpr> boolexpr
%type <str> relop
%token <intval> TK_INT_LIT
%token <str> TK_IDEN
%token TK_IF TK_ELSE TK_WHILE
%nonassoc TK_VAR
%left TK_OR
%left TK_AND
%left TK_EQ TK_NE
%left '<' '>' TK_LE TK_GE
%left '+' '-'
%left '*' '/'
%right TK_NOT TK_UMINUS
%left '(' ')'
%nonassoc TK_ELSE
%%

statements: statements M statement
            {
                backpatch($1->nextlist, $<intval>2);
                Statements *stmts = safemalloc(sizeof(*stmts));
                stmts->nextlist = $3->nextlist;
                $$ = stmts;
            }
|           statement
            {
                Statements *stmts = safemalloc(sizeof(*stmts));
                stmts->nextlist = $1->nextlist;
                $$ = stmts;
            }
;

statement:  TK_VAR TK_IDEN ';'
            {
                newsymentry($2);
                Statement *stmt = safemalloc(sizeof(*stmt));
                stmt->nextlist = NULL;
                $$ = stmt;
            }
|           TK_IDEN '=' expression ';'
            {
                Statement *stmt = safemalloc(sizeof(*stmt));                
                SymEntry *entry = g_hash_table_lookup(symtab, $1);
                if (entry)
                {
                    stmt->nextlist = NULL;
                    makequad(emptystr, emptystr, addrtostr($3->addr), entry->name, UNASSIG_TYPE);
                }
                else
                {
                    yyerror("attempted use of undeclared variable");
                    exit(0);
                }
                $$ = stmt;
            }
|           TK_IF '(' boolexpr ')' M statement
            {
                backpatch($3->truelist, $<intval>5);
                Statement *stmt = safemalloc(sizeof(*stmt));
                stmt->nextlist = merge($3->falselist, $6->nextlist);
                $$ = stmt;
            }
|           TK_IF '(' boolexpr ')' M statement TK_ELSE N M statement
            {
                backpatch($3->truelist, $<intval>5);
                backpatch($3->falselist, $<intval>9);
                GSList *temp = merge($6->nextlist, $<stmt>8->nextlist);
                Statement *stmt = safemalloc(sizeof(*stmt));
                stmt->nextlist = merge(temp, $10->nextlist);
                $<stmt>$ = stmt;
            }
|           TK_WHILE M '(' boolexpr ')' M statement
            {
                backpatch($7->nextlist, $<intval>2);
                backpatch($4->truelist, $<intval>6);
                Statement *stmt = safemalloc(sizeof(*stmt));
                stmt->nextlist = $4->falselist;
                $<stmt>$ = stmt;
                makequad(emptystr, emptystr, emptystr, inttostr($<intval>2), GOTO_TYPE);
            }
|           '{' statements '}'
            {
                Statement *stmt = safemalloc(sizeof(*stmt));
                stmt->nextlist = $2->nextlist;
                $$ = stmt;
            }
|           expression ';'
            {
                Statement *stmt = safemalloc(sizeof(*stmt));
                $$ = stmt;
            }
;

M:          %empty { $<intval>$ = nextquad; } // marker M
;

N:          %empty // marker N
            {
                Statement *stmt = safemalloc(sizeof(*stmt));
                stmt->nextlist = makelist(nextquad);
                $<stmt>$ = stmt;
                makequad(emptystr, emptystr, emptystr, emptystr, GOTO_TYPE);
            }
; 

expression: expression '+' expression
            {
                Expression *expr = safemalloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                makequad(strdup("+"), addrtostr($1->addr),
                    addrtostr($3->addr), addrtostr($$->addr), BINASSIG_TYPE);
            }
|           expression '-' expression
            {
                Expression *expr = safemalloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                makequad(strdup("-"), addrtostr($1->addr),
                    addrtostr($3->addr), addrtostr($$->addr), BINASSIG_TYPE);
            }
|           expression '*' expression
            {
                Expression *expr = safemalloc(sizeof(*expr));
                expr->addr = newtemp();
                $$ = expr;
                makequad(strdup("*"), addrtostr($1->addr),
                    addrtostr($3->addr), addrtostr($$->addr), BINASSIG_TYPE);
            }
|           '-' expression %prec TK_UMINUS
            {
                Expression *expr = safemalloc(sizeof(*expr));
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
                Expression *expr = safemalloc(sizeof(*expr));
                SymEntry *entry = g_hash_table_lookup(symtab, yylval.str);
                if (entry)
                {
                    expr->addr = newaddr(entry);
                }
                else
                {
                    yyerror("attempted use of undeclared variable");
                    exit(0);
                }
                $$ = expr;
            }
|           TK_INT_LIT
            {
                Expression *expr = safemalloc(sizeof(*expr));
                Addr *addr = safemalloc(sizeof(*addr));
                addr->addrvalue.intval = yylval.intval;
                addr->addrvaluetype = INT_TYPE;
                expr->addr = addr;
                $$ = expr;
            }
;

boolexpr:   boolexpr TK_AND M boolexpr
            {
                backpatch($1->truelist, $<intval>3);
                BoolExpr *bexpr = safemalloc(sizeof(*bexpr));
                bexpr->truelist = $4->truelist;
                bexpr->falselist = merge($1->falselist, $4->falselist);
                $$ = bexpr;
            }
|           boolexpr TK_OR M boolexpr
            {
                backpatch($1->falselist, $<intval>3);
                BoolExpr *bexpr = safemalloc(sizeof(*bexpr));
                bexpr->truelist = merge($1->truelist, $4->truelist);
                bexpr->falselist = $4->falselist;
                $$ = bexpr;
            }
|           TK_NOT boolexpr
            {
                BoolExpr *bexpr = safemalloc(sizeof(*bexpr));
                bexpr->truelist = $2->falselist;
                bexpr->falselist = $2->truelist;
                $$ = bexpr;
            }
|           '(' boolexpr ')'
            {
                // BoolExpr *bexpr = safemalloc(sizeof(*bexpr));
                // bexpr->truelist = $2->truelist;
                // bexpr->falselist = $2->falselist;
                $$ = $2;
            }
|           expression relop expression
            {
                BoolExpr *bexpr = safemalloc(sizeof(*bexpr));
                bexpr->truelist = makelist(nextquad);
                bexpr->falselist = makelist(nextquad + 1);
                makequad(strdup($2), addrtostr($1->addr), addrtostr($3->addr), emptystr, IFGOTO_TYPE);
                makequad(emptystr, emptystr, emptystr, emptystr, GOTO_TYPE);
                $$ = bexpr;
            }

relop:      '<'     { $$ = "<"; }
|           '>'     { $$ = ">"; }
|           TK_EQ   { $$ = "=="; }
|           TK_NE   { $$ = "!="; }
|           TK_LE   { $$ = "<="; }
|           TK_GE   { $$ = ">="; }
%%

int main(int argc, char **argv)
{
    // open file
    if (argc != 2)
    {
        fprintf(stderr, "tbd: fatal error: no input file\n");
        exit(0);
    }
    yyin = fopen(argv[1], "r");

    // init global variables
    emptystr = strdup("");
    tempcounter = 0;
    nextquad = 0;
    symtab = g_hash_table_new(g_str_hash, g_str_equal);
    quadarray = g_ptr_array_new();
    
    // parse
    yyparse();
    fclose(yyin);
    printcode(quadarray);
    return 0;
}

void yyerror (const char *msg)
{
	fprintf(stderr, "\nError at line %d: %s\n", yylineno, msg);
    exit(0);
}