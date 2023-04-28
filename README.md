`yacc -d main.y`: create y.tab.h and y.tab.c
`lex main.l`: create lex.yy.c
`gcc -g lex.yy.c y.tab.c -o main`: create main
`./main`: run main

---
# TODOs:
1. Required:
   - Variables and Constants declaration.
   - Mathematical and logical expressions.
   - Assignment statement.
   - If-then-else statement, while loops, repeat-until loops, for, loops, switch statement.
   - Block structure (nested scopes where variables may be declared at the beginning of blocks).
   - Enums
   - Functions
