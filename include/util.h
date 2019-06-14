#ifndef UTIL_H
#define UTIL_H
#include "def.h"
#include <stdio.h>
#include <stdlib.h>
#include <gmodule.h>

void *safemalloc(size_t size);
char *concat(char *str1, char *str2);
char *inttostr(int i);
char *addrtostr(Addr *addr);
void printlist(GSList *list);
void printquad(Quad *quad);
void printcode(GPtrArray *quadarray);

#endif