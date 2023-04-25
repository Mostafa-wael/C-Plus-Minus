y.tab.c: main.y
	yacc -d main.y

lex.yy.c: y.tab.c main.l
	lex main.l

build: lex.yy.c y.tab.c
	gcc -g lex.yy.c y.tab.c -o main

clean: 
	rm -rf lex.yy.c y.tab.c y.tab.h main main.dSYM