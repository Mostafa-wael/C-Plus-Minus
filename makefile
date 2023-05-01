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
	./main < ./test/decleration.c
operations: build
	./main < ./test/operations.c
conditions: build
	./main < ./test/conditions.c
loops: build
	./main < ./test/loops.c
functions: build
	./main < ./test/functions.c
enum: build
	./main < ./test/enum.c
mixed: build
	./main < ./test/mixed.c

test: decleration operations conditions loops functions enum mixed
	echo "All tests passed"

	
clean: 
	rm -rf lex.yy.c y.tab.c y.tab.h main main.dSYM