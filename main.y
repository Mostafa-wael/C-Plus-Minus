%{
/* C declarations used in actions */
//==============================================================================
// Some useful includes
//======================
#include <stdio.h>     
#include <stdlib.h>
#include <ctype.h>
void yyerror (char *s); // in case of errors
int yylex();

// Symbol table
//======================
int symbolTable [52]; // 26 for lower case, 26 for upper case
int symbolVal(char symbol); // returns the value of a given symbol
void updateSymbolVal(char symbol, int val); // updates the value of a given symbol
%}
/* Yacc definitions */
//==============================================================================
%start statments // defines the starting symbol

// Symbols Types(in C)
//======================
// %union is used to define the types of the tokens that can be returned   
// here we defined those types where the 2nd term is definedwith type of the 1st term
%union {
        int TYPE_INT; 
        float TYPE_FLOAT;
        char* TYPE_STR; 
        int TYPE_BOOL;
        void* TYPE_VOID;
        char TYPE_LETTER
;}
/* Tokens */// this will be added to the header file y.tab.h, hence the lexical analyzer will know about them
// Data Types
//======================
%token <TYPE_INT> number // this is a token called number returned by the lexical analyzer with as TYPE_INT
%token <TYPE_FLOAT> float_number // this is a token called float_number returned by the lexical analyzer with as TYPE_FLOAT
%token <TYPE_LETTER> identifier // this is a token called identifier returned by the lexical analyzer with as TYPE_LETTER
%token <TYPE_STR> string // this is a token called string returned by the lexical analyzer with as TYPE_STR
%token <TYPE_BOOL> true_command 
%token <TYPE_BOOL> false_command 

// Control Commands
//======================
%token PRINT
%token ASSERT
%token EXIT

// Control Flow
//======================
%token IF ELSE ELIF ENDIF 
%token SWITCH CASE DEFAULT ENDSWITCH
%token WHILE FOR BREAK CONTINUE 
%token FUNCTION RETURN

// Operators
//======================
/* Order is imporetant here */
// this defines the associativity of the operators 
%right '=' 
%left  AND OR  
%left  '|' 
%left  '^' 
%left  '&' 
%left EQ NEQ 
%left GT GEQ LT LEQ 
%left SHR SHL
%left  '+' '-' 
%right NOT '!' '~' 
%left  '*' '/' '%' 
// Return Types
//======================
// this defines the type of the non-terminals
%type <TYPE_VOID> statments statment controlStatment 
%type <TYPE_VOID> ifCondition whileLoop forLoop
%type <TYPE_INT> exp 
%type <TYPE_INT> term 
%type <TYPE_LETTER> assignment 
%%

/* descriptions of expected inputs corresponding actions (in C) */
statments	                                : statment ';'
                                                | controlStatment
			                        | statments statment ';'
                                                | statments controlStatment
                                                ;
controlStatment                                 : ifCondition
                                                | whileLoop
                                                | forLoop
                                                /* | whileCondition
                                                | forCondition
                                                | switchCondition
                                                | functionCall
                                                | returnCommand
                                                | breakCommand
                                                | continueCommand */
                                                ;       
statment                                        : assignment 		                {;}
                                                | EXIT 		                        {exit(EXIT_SUCCESS);}
                                                | PRINT exp 		                {printf("%d\n", $2);}
                                                | PRINT string 	                        {printf("%s\n", $2);}
                                                /* | PRINT float_number 	                {printf("%f\n", $2);} */
                                                ;
assignment                                      : identifier '=' exp                    { updateSymbolVal($1,$3); }
			                        ;
exp    	                                        : term                                  {$$ = $1;}
                                                | '-' term                              {$$ = -$2;}
                                                | '~' term                              {$$ = ~$2;}
                                                | NOT term                              {$$ = !$2;}

                                                | exp '+' exp                           {$$ = $1 + $3;}
                                                | exp '-' exp                           {$$ = $1 - $3;}
                                                | exp '*' exp                           {$$ = $1 * $3;}
                                                | exp '/' exp                           {$$ = $1 / $3;}
                                                | exp '%' exp                           {$$ = $1 % $3;}

                                                | exp '|' exp                           {$$ = $1 | $3;}
                                                | exp '&' exp                           {$$ = $1 & $3;}
                                                | exp '^' exp                           {$$ = $1 ^ $3;}
                                                | exp SHL exp                           {$$ = $1 << $3;}
                                                | exp SHR exp                           {$$ = $1 >> $3;}

                                                | exp EQ exp                            {$$ = $1 == $3;}
                                                | exp NEQ exp                           {$$ = $1 != $3;}
                                                | exp GT exp                            {$$ = $1 > $3;}
                                                | exp GEQ exp                           {$$ = $1 >= $3;}
                                                | exp LT exp                            {$$ = $1 < $3;}
                                                | exp LEQ exp                           {$$ = $1 <= $3;}

                                                | exp AND exp                           {$$ = $1 && $3;}
                                                | exp OR exp                            {$$ = $1 || $3;}
                                                ;
term   	                                        : number                                {$$ = $1;}
                                                | float_number                          {$$ = $1;}
                                                | true_command                          {$$ = 1;}
                                                | false_command                         {$$ = 0;}
                                                | identifier	                        {$$ = symbolVal($1);} 
                                                | '(' exp ')'                           {$$ = $2;}
                                                ;

ifCondition                                     : IF '(' exp ')' '{' statments '}'      {;}
                                                | IF '(' exp ')' '{' statments '}' ELSE '{' statments '}' {;}
                                                | IF '(' exp ')' '{' statments '}' ELIF '(' exp ')' '{' statments '}' {;}
                                                | IF '(' exp ')' '{' statments '}' ELIF '(' exp ')' '{' statments '}' ELSE '{' statments '}' {;}
                                                ;
whileLoop                                       : WHILE '(' exp ')' '{' statments '}'   {;}
                                                ;
forLoop                                         : FOR '(' exp ';' exp ';' exp ')' '{' statments '}' {printf("for loop\n");}
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

