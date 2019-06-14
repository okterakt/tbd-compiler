# From root directory

tbd: setting lex.yy.c y.tab.c ./src/util.c
	gcc -o ./build/tbd ./build/lex.yy.c ./build/y.tab.c ./src/util.c -ly -ll `pkg-config --cflags --libs glib-2.0`
	@echo "\nCompilation completed!"

lex.yy.c: src/tbd_lexspec.l
	flex -o ./build/lex.yy.c src/tbd_lexspec.l

y.tab.c: src/tbd_parspec.y
	bison -vd src/tbd_parspec.y -b ./build/y

setting: 
	@echo "Starting compilation...\n"
	rm -rf ./build && mkdir build