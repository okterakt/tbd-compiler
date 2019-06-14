%{
#include "../include/def.h"
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
"else"          { return TK_ELSE; }
"while"         { return TK_WHILE; }
"and"           { return TK_AND; }
"or"            { return TK_OR; }
"not"           { return TK_NOT; }
"var"           { return TK_VAR; }
"=="            { return TK_EQ; }
"!="            { return TK_NE; }
"<="            { return TK_LE; }
">="            { return TK_GE; }

{identifier}    {
                    yylval.str = strdup(yytext);
                    return TK_IDEN;
                }
[ \t]           ; // ignore whitespace
\n              { } // new line
<<EOF>>         { yyterminate(); }
.               return yytext[0];
%%