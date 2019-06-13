# compiler-project
Frontend of a simple compiler for the Formal Languages and Compilers course

## How to compile
Execute the following from the root of the project directory
```make```

Alternative way
```
cd src/
bison -d parser_spec.y -b ../build/y
lex -o ../build/lex.yy.c lexer_spec.l
cd ../build/
gcc -o runner y.tab.c lex.yy.c -ly -ll `pkg-config --cflags --libs glib-2.0`
```

## How to run
Execute the following from the root of the project directory `./build/runner`