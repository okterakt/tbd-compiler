# compiler-project
Project for the Formal Languages and Compilers course

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
Execute the following from the root of the project directory `./proj`

### usage:
Run `./proj` and then type arithmatic operation to generate intermediate code.

`5+6*9/3+5`
