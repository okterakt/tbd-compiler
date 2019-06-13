#ifndef __DEF_H__
#define __DEF_H__
#include <gmodule.h>

// SYMTAB ENTRY
typedef struct SymEntry
{
    char *name;
    // enum Type type;
    // int offset;
    // int width;
} SymEntry;

// enum Type {
//     int;
//     float;
//     string;
// };

// ADDR
enum AddrValueType
{
    ENTRYPTR_TYPE,
    INT_TYPE
};

typedef struct Addr
{
    union AddrValue
    {
        SymEntry *entry;
        int intval;
    } addrvalue;
    enum AddrValueType addrvaluetype;
} Addr;

typedef struct Expression
{
    // attributes
    Addr *addr;
    GSList *truelist;
    GSList *falselist;
} Expression;

typedef struct Statement
{
    GSList *nextlist;
} Statement;

typedef struct Program
{
    GSList *nextlist;
} Program;

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