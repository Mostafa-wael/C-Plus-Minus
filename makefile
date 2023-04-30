y.tab.c: main.y
	# yacc -d  main.y
	yacc -d -Wcounterexamples main.y

lex.yy.c: y.tab.c main.l
	lex main.l

build: lex.yy.c y.tab.c
	gcc -g lex.yy.c y.tab.c -o main 

run: build
	./main

test1: build
	./main < ./tests/test1.txt
test2: build
	./main < ./tests/test2.txt	

clean: 
	rm -rf lex.yy.c y.tab.c y.tab.h main main.dSYM