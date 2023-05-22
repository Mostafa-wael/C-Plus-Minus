y.tab.c: main.y
	yacc -d  main.y
	# yacc -d -Wcounterexamples main.y

lex.yy.c: y.tab.c main.l
	lex main.l

build: lex.yy.c y.tab.c
	gcc -g lex.yy.c y.tab.c -o main 

run: build
	./main

decleration: build
	./main < ./test/decleration.c > ./test/out/decleration.out
operations: build
	./main < ./test/operations.c > ./test/out/operations.out
conditions: build
	./main < ./test/conditions.c > ./test/out/conditions.out
loops: build
	./main < ./test/loops.c > ./test/out/loops.out
functions: build
	./main < ./test/functions.c > ./test/out/functions.out
enum: build
	./main < ./test/enum.c > ./test/out/enum.out
mixed: build
	./main < ./test/mixed.c > ./test/out/mixed.out
custom: build
	./main < ./test/custom.c > ./test/out/custom.out

testAll: decleration operations conditions loops functions enum
	echo "All tests passed"

	
clean: 
	rm -rf lex.yy.c y.tab.c y.tab.h main main.dSYM ./test/out/*.out