#ifndef DEF_H
#define DEF_H
#include <stdlib.h>
#include <gmodule.h>

typedef struct SymEntry
{
    char *name;
} SymEntry;

enum AddrValueType
{
    ENTRYPTR_TYPE,
    INT_TYPE
};

typedef struct Addr
{
    union AddrValue {
        SymEntry *entry;
        int intval;
    } addrvalue;
    enum AddrValueType addrvaluetype;
} Addr;

typedef struct Statements
{
    GSList *nextlist;
} Statements;

typedef struct Statement
{
    GSList *nextlist;
} Statement;

typedef struct Expression
{
    Addr *addr;
} Expression;

typedef struct BoolExpr
{
    GSList *truelist;
    GSList *falselist;
} BoolExpr;

enum QuadType
{
    UNASSIG_TYPE,
    BINASSIG_TYPE,
    IFGOTO_TYPE,
    GOTO_TYPE
};

typedef struct Quad
{
    char *op;
    char *arg1;
    char *arg2;
    char *result;
    enum QuadType quadtype;
} Quad;

#endif