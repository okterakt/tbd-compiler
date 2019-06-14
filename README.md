# TBD
Frontend of a simple compiler for the Formal Languages and Compilers course.

## How to compile
Execute `make` from the root of the project directory.

## How to run
An input text file must be specified as argument for the parsing.
The three address code will be displayed in the terminal.

### Usage example
Execute the following from the root of the project directory `./build/tbd ./test/input01.txt` .

`tbd` is the main program and `input01.txt` is an example of an input file.

## Grammar
```
statements -> statements statement
            | statement

statement  -> var id ;
            | id = expression ;
            | if ( boolexpr ) statement
            | if ( boolexpr ) statement else statement
            | while ( boolexpr ) statement
            | { statements }
            | expression ;

expression -> expression + expression
            | expression - expression
            | expression * expression
            | - expression
            | ( expression )
            | id
            | intlit

boolexpr   -> boolexpr and boolexpr
            | boolexpr or boolexpr
            | not boolexpr
            | ( boolexpr )
            | expression relop expression

relop      -> == | != | < | > | <= | >=
```
