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
// here we dfined two types: 2nd term with type of the 1st term
%union {int INT; 
        float FLOAT;
        char* STR; 
        int BOOL;
        char LETTER;}
%start statment // defines the starting symbol
/* Tokens */
// this will be added to the header file y.tab.h, hence the lexical analyzer will know about them
%token <INT> number // this is a token called number returned by the lexical analyzer with as num
%token <FLOAT> float_number // this is a token called float_number returned by the lexical analyzer with as float_num
%token <LETTER> identifier // this is a token called identifier returned by the lexical analyzer with as letter
%token <STR> string // this is a token called string returned by the lexical analyzer with as str
%token <BOOL> true_command 
%token <BOOL> false_command 

%token print
%token exit_command

%token IF ELSE ELIF ENDIF WHILE FOR BREAK CONTINUE FUNCTION RETURN
%left  AND OR NOT// this defines the associativity of the operators 

%left  '+' '-' // this defines the associativity of the operators
%left  '*' '/' // this defines the associativity of the operators
%left '^' '|' '&' '~'// this defines the associativity of the operators
%right '=' // this defines the associativity of the operators
/* Types */
%type <INT> statment exp term // this defines the type of the non-terminals
%type <LETTER> assignment // this defines the type of the non-terminals

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
            | '(' exp ')'           {$$ = $2;}
            /* TODO: strings notworking yet */
            //| string                {$$ = $1;}
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

