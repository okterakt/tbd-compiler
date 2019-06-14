# From root directory

runner: setting lex.yy.c y.tab.c ./src/util.c
	gcc -o ./build/runner ./build/lex.yy.c ./build/y.tab.c ./src/util.c -ly -ll `pkg-config --cflags --libs glib-2.0`
	@echo "\nCompilation completed!"

lex.yy.c: src/lexer_spec.l
	flex -o ./build/lex.yy.c src/lexer_spec.l

y.tab.c: src/parser_spec.y
	bison -vd src/parser_spec.y -b ./build/y

setting: 
	@echo "Starting compilation...\n"
	rm -rf ./build && mkdir build