# compiler-project
Project for the Formal Languages and Compilers course

## How to compile
Execute the following from the main project directory
```
cd src/
yacc -d parser_spec.y -b ../build/y
lex -o ../build/lex.yy.c lexer_spec.l
cd ../build/
gcc -o runner y.tab.c lex.yy.c -ly -ll `pkg-config --cflags --libs glib-2.0`
cd ..
```