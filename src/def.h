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
    int v;
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
    // Addr trueaddr;
    // Addr falseaddr;
} Expression;

typedef struct Statement
{
    char *begin;
    char *next;
} Statement;

#endif