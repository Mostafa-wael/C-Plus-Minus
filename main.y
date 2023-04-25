%{
/* C declarations used in actions */
// Some useful includes
#include <stdio.h>     
#include <stdlib.h>
#include <ctype.h>
void yyerror (char *s); // in case of errors
int yylex();
// Symbol table
int symbolTable [52]; // 26 for lower case, 26 for upper case
int symbolVal(char symbol); // returns the value of a given symbol
void updateSymbolVal(char symbol, int val); // updates the value of a given symbol
%}
/* Yacc definitions */
// %union is used to define the types of the tokens that can be returned   
%union {int num; char* str; char letter;} // here we dfined two types: num as integres and letter as characters
%start statment // defines the starting symbol
/* Tokens */
// this will be added to the header file y.tab.h, hence the lexical analyzer will know about them
%token print
%token exit_command
%token <num> number // this is a token called number returned by the lexical analyzer with as num
%token <letter> identifier // this is a token called identifier returned by the lexical analyzer with as letter
%token <str> string // this is a token called string returned by the lexical analyzer with as str
/* Types */
%type <num> statment exp term // this defines the type of the non-terminals
%type <letter> assignment // this defines the type of the non-terminals

%%

/* descriptions of expected inputs corresponding actions (in C) */

statment    : assignment ';'		{;}
            | exit_command ';'		{exit(EXIT_SUCCESS);}
            | print exp ';'			{printf("Value is: %d\n", $2);}
            | statment  assignment ';'	{;}
            | statment  print exp ';'	{printf("Value is: %d\n", $3);}
            | statment  exit_command ';'	{exit(EXIT_SUCCESS);}
            ;

assignment  : identifier '=' exp  { updateSymbolVal($1,$3); }
			;
exp    	    : term                  {$$ = $1;}
            | exp '+' term          {$$ = $1 + $3;}
            | exp '-' term          {$$ = $1 - $3;}
            ;
term   	    : number                {$$ = $1;}
            | identifier			{$$ = symbolVal($1);} 
            ;

%%                     
/* C code */
int computeSymbolIndex(char token)
{
	int idx = -1;
	if(islower(token)) {
		idx = token - 'a' + 26;
	} else if(isupper(token)) {
		idx = token - 'A';
	}
	return idx;
} 

/* returns the value of a given symbol */
int symbolVal(char symbol)
{
	int bucket = computeSymbolIndex(symbol);
	return symbolTable [bucket];
}

/* updates the value of a given symbol */
void updateSymbolVal(char symbol, int val)
{
	int bucket = computeSymbolIndex(symbol);
	symbolTable [bucket] = val;
}

int main (void) {
	/* init symbol table */
	int i;
	for(i=0; i<52; i++) {
		symbolTable [i] = 0;
	}

	return yyparse ( );
}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);} 

