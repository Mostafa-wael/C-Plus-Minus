`yacc -d main.y`: create y.tab.h and y.tab.c
`lex main.l`: create lex.yy.c
`gcc -g lex.yy.c y.tab.c -o main`: create main
`./main`: run main
