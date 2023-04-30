y.tab.c: main.y
	# yacc -d  main.y
	yacc -d -Wcounterexamples main.y

lex.yy.c: y.tab.c main.l
	lex main.l

build: lex.yy.c y.tab.c
	gcc -g lex.yy.c y.tab.c -o main 

run: build
	./main

decleration: build
	./main < ./tests/decleration.c
operations: build
	./main < ./tests/operations.c
conditions: build
	./main < ./tests/conditions.c
loops: build
	./main < ./tests/loops.c
functions: build
	./main < ./tests/functions.c
enum: build
	./main < ./tests/enum.c
mixed: build
	./main < ./tests/mixed.c

test: decleration operations conditions loops functions enum mixed
	echo "All tests passed"

	
clean: 
	rm -rf lex.yy.c y.tab.c y.tab.h main main.dSYM