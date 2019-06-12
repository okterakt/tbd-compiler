%{
#include "def.h"
#include "y.tab.h"
%}

digit       [0-9]
letter      [a-zA-Z]
identifier  {letter}({letter}|{digit})*

%%
{digit}*        {
                    yylval.intval = atoi(yytext);
                    return TK_INT_LIT;
                }
"if"            { return TK_IF; }
"and"           { return TK_AND; }
"or"            { return TK_OR; }
"not"           { return TK_NOT; }
"var"           { return TK_VAR; }
"=="            { return TK_EQ; }
"!="            { return TK_NE; }
"<="            { return TK_LE; }
">="            { return TK_GE; }
{identifier}    {
                    yylval.name = strdup(yytext);
                    return TK_IDEN;
                }
[ \t\n]         ; // ignore whitespace
<<EOF>>         { yyterminate(); }
.               return yytext[0];
%%
// \n              return 0; //logical EOF