# suppose you are in root directory of project

proj: setting lex.yy.c y.tab.c

	@echo "\nCompiling using glib package...\n"
	gcc -s ./build/lex.yy.c ./build/y.tab.c -o ./proj `pkg-config --cflags --libs glib-2.0`
	@echo "\nProject Compiled!"

lex.yy.c: y.tab.c src/lexer_spec.l
	flex -o ./build/lex.yy.c src/lexer_spec.l

y.tab.c: src/parser_spec.y
	yacc -d src/parser_spec.y -b ./build/y

setting: 
	@echo "Starting Compiling...\n"
	rm -rf ./build && mkdir build
	cp src/def.h build/def.h