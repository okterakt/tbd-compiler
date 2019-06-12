#ifndef __DEF_H__
#define __DEF_H__

// SYMTAB ENTRY
typedef struct Entry
{
    char *name;
    // enum Type type;
    // int offset;
    // int width;
} Entry;

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
        Entry *entry;
        int intval;
    } addrvalue;
    enum AddrValueType addrvaluetype;
} Addr;

typedef struct Expression
{
    // attributes
    Addr *addr;
    char *labtrue;
    char *labfalse;
    char *code;
} Expression;

typedef struct Statement
{
    char *labbegin;
    char *labnext;
    char *code;
} Statement;

typedef struct Program
{
    char *code;
} Program;

#endif