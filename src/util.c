#include "../include/util.h"

void *safemalloc(size_t size)
{
    void *ptr = malloc(size);

    if (!ptr && (size > 0))
    {
        perror("malloc failed!");
        exit(EXIT_FAILURE);
    }

    return ptr;
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

void printcode(GPtrArray *quadarray)
{
    for (int i = 0; i < quadarray->len; i++)
    {
        Quad *quad = g_ptr_array_index(quadarray, i);
        printf("%d:\t", i);
        printquad(quad);
    }
}