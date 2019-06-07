# compiler-project
Project for the Formal Languages and Compilers course

## How to compile
Execute the following from the main project directory
```
cd src/
yacc -d parser.y -b ../build/y
lex -o ../build/lex.yy.c lexer.l
cd ../build/
gcc -o runner lex.yy.c y.tab.c -ly -ll
```