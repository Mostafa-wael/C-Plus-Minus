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
%start program // defines the starting symbol

// Symbols Types(in C)
//======================
// %union is used to define the types of the tokens that can be returned   
// here we defined those types where the 2nd term is definedwith type of the 1st term
%union {
        int TYPE_INT; 
        char* TYPE_DATA_TYPE;
        char* TYPE_DATA_IDENTIFIER;
        float TYPE_FLOAT;
        char* TYPE_STR; 
        int TYPE_BOOL;
        void* TYPE_VOID;
        char TYPE_LETTER
;}
/* Tokens */// this will be added to the header file y.tab.h, hence the lexical analyzer will know about them

// Control Commands
//======================
%token PRINT
%token ASSERT
%token EXIT

// Control Flow
//======================
%token IF ELSE ELIF 
%token SWITCH CASE DEFAULT 
%token WHILE FOR BREAK CONTINUE REPEAT UNTIL
%token RETURN ENUM

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

// Declarations
//======================
%token <TYPE_DATA_IDENTIFIER> CONST
%token <TYPE_DATA_TYPE> INT_DATA_TYPE FLOAT_DATA_TYPE STRING_DATA_TYPE BOOL_DATA_TYPE VOID_DATA_TYPE
%token <TYPE_INT> IDENTIFIER // this is a token called IDENTIFIER returned by the lexical analyzer with as TYPE_LETTER

// Data Types
//======================
%token <TYPE_INT> NUMBER // this is a token called NUMBER returned by the lexical analyzer with as TYPE_INT
%token <TYPE_FLOAT> FLOAT_NUMBER // this is a token called FLOAT_NUMBER returned by the lexical analyzer with as TYPE_FLOAT
%token <TYPE_STR> STRING // this is a token called STRING returned by the lexical analyzer with as TYPE_STR
%token <TYPE_BOOL> TRUE_VAL 
%token <TYPE_BOOL> FALSE_VAL 
// Return Types
//======================
// this defines the type of the non-terminals
%type <TYPE_VOID> program statments statment controlStatment 
%type <TYPE_VOID> ifCondition whileLoop forLoop repeastUntilLoop switchCaseLoop case caseList 
%type<TYPE_VOID> codeBlock functionArgs functionParms  functionCall 
%type <TYPE_INT> exp 
%type <TYPE_INT> term 
%type <TYPE_LETTER> assignment 
%type <TYPE_DATA_TYPE> dataType declaration
%type <TYPE_DATA_IDENTIFIER> dataIdentifier
%%

/* descriptions of expected inputs corresponding actions (in C) */
program                 : statments                             {;}
                        | functionDef                           {;}
                        | statments program                      {;}
                        | functionDef program                    {;}
                        ;
statments	        : statment ';'                          {;}
                        | codeBlock                             {;}
                        | controlStatment                       {;}
                        | statments codeBlock                   {;}
                        | statments statment ';'                {;}
                        | statments controlStatment             {;}
                        ;
codeBlock               : '{' statments '}'                     {;}
                        | '{' '}'                               {;}
                        ;
controlStatment         : ifCondition
                        | whileLoop
                        | forLoop
                        | repeastUntilLoop
                        | switchCaseLoop
                        ;      
                                                 
statment                : assignment 		                {;}
                        | exp                                   {;}
                        | declaration 		                {;}
                        | EXIT 		                        {exit(EXIT_SUCCESS);}
                        | BREAK 		                {;}
                        | CONTINUE 		                {;}
                        | RETURN 		                {;}
                        | RETURN exp 		                {;}
                        | PRINT exp 		                {printf("%d\n", $2);}
                        | PRINT STRING 	                        {printf("%s\n", $2);}
                        /* | PRINT FLOAT_NUMBER 	                {printf("%f\n", $2);} */
                        ;
declaration             : dataType IDENTIFIER 		        {;}
                        | dataType assignment	                {;}
                        | dataIdentifier declaration 	        {;}
                        ;
assignment              : IDENTIFIER '=' exp                    {updateSymbolVal($1,$3);}
                        | IDENTIFIER '=' STRING                 {updateSymbolVal($1,atoi($3));}
                        | enumDeclaration
                        | enumDef
                        ;
exp    	                : term                                  {$$ = $1;}
                        | functionCall                          {;}
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
term   	                : NUMBER                                {$$ = $1;}
                        | FLOAT_NUMBER                          {$$ = $1;}
                        | TRUE_VAL                                  {$$ = 1;}
                        | FALSE_VAL                                 {$$ = 0;}
                        | IDENTIFIER	                        {$$ = symbolVal($1);} 
                        | '(' exp ')'                           {$$ = $2;}
                        ;
dataIdentifier          : CONST                                         {;}
                        ;
dataType                : INT_DATA_TYPE                                 {$$ = $1;}
                        | FLOAT_DATA_TYPE                               {$$ = $1;}
                        | STRING_DATA_TYPE                              {$$ = $1;}
                        | BOOL_DATA_TYPE                                {$$ = $1;}
                        | VOID_DATA_TYPE                                {$$ = $1;}
                        ;

ifCondition             : IF '(' exp ')' codeBlock                      {;}
                        | IF '(' exp ')' codeBlock ELSE codeBlock       {;}
                        | IF '(' exp ')' codeBlock ELIF '(' exp ')' codeBlock {;}
                        | IF '(' exp ')' codeBlock ELIF '(' exp ')' codeBlock ELSE codeBlock {;}
                        ;
whileLoop               : WHILE '(' exp ')' codeBlock                   {;}
                        ;
forLoop                 : FOR '(' assignment ';' exp ';' assignment ')' codeBlock {;}
                        ;
repeastUntilLoop        : REPEAT codeBlock UNTIL '(' exp ')' ';'        {;}
                        ;

case                    : CASE exp ':' statments                        {;}
                        | DEFAULT ':' statments                         {;}
                        ;
caseList                : caseList case
                        | case
                        ;
switchCaseLoop          : SWITCH '(' exp ')' '{' caseList '}'           {;}
                        ;
                                  
functionArgs            : dataType IDENTIFIER                           {;}
                        | dataType IDENTIFIER ',' functionArgs          {;}
                        ;
functionParms           : term                                          {;}
                        | term ',' functionParms                        {;}
                        ;
functionDef             : dataType IDENTIFIER '(' functionArgs ')' codeBlock {;}
                        | dataType IDENTIFIER '(' ')' codeBlock         {printf("functionDef\n");}
                        ;
functionCall            : IDENTIFIER '(' functionParms ')'              {;}
                        | IDENTIFIER '(' ')'                            {;}
                        ;

enumDef	                : ENUM IDENTIFIER '{' enumBody '}'              {;}
                        ;
enumBody		: IDENTIFIER                                    {;}
                        | IDENTIFIER '=' exp                            {;}
                        | enumBody ',' IDENTIFIER                       {;}
                        | enumBody ',' IDENTIFIER  '=' exp              {;}
                        ;
enumDeclaration         : IDENTIFIER IDENTIFIER                         {;}
                        | IDENTIFIER IDENTIFIER '=' exp                 {;}
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

