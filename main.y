%{
/* C declarations used in actions */
//==============================================================================
// Some useful includes
//======================
#include <stdio.h>     
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
/* if this is defined, then the vector will double in capacity each
 * time it runs out of space. if it is not defined, then the vector will
 * be conservative, and will have a capacity no larger than necessary.
 * having this defined will minimize how often realloc gets called.
 */
#define CVECTOR_LOGARITHMIC_GROWTH
#include "src/cvector.h"

void yyerror (char *s); // in case of errors
int yylex();

char buffer[500];


// Types
//======================
struct nodeType {
        char *type;
        // add a union that carries the value of the type
        union {
                int intVal;
                float floatVal;
                char* stringVal;
                int boolVal;
        }value;
};
// type functions
struct nodeType* intNode();
struct nodeType* floatNode();
struct nodeType* boolNode();
struct nodeType* stringNode();
void typeCheck(struct nodeType* type1, struct nodeType* type2);


// Symbol table
//======================
struct symbol {
        char *name;
        char *type;
        union {
                int intVal;
                float floatVal;
                char* stringVal;
                int boolVal;
        }value;
        int isDecl, isConst, isInit, isUsed;
};
// Symbol table functions
struct symbol symbol_Table [52]; // 26 for lower case, 26 for upper case
int symbolTable [52]; // 26 for lower case, 26 for upper case
struct nodeType* symbolVal(char symbol); // returns the value of a given symbol
void updateSymbolVal(char symbol, struct nodeType* val); // updates the value of a given symbol

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
        char* TYPE_DATA_MODIFIER;
        float TYPE_FLOAT;
        char* TYPE_STR; 
        int TYPE_BOOL;
        void* TYPE_VOID;

        struct nodeType* TYPE_NODE;
;}
/* Tokens */// this will be added to the header file y.tab.h, hence the lexical analyzer will know about them

// Control Commands
//======================
%token PRINT
%token ASSERT
%token EXIT

// Control Flow
//======================
%token IF ELSE  
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
%token <TYPE_DATA_MODIFIER> CONST
%token <TYPE_DATA_TYPE> INT_DATA_TYPE FLOAT_DATA_TYPE STRING_DATA_TYPE BOOL_DATA_TYPE VOID_DATA_TYPE
%token <TYPE_NODE> IDENTIFIER // this is a token called IDENTIFIER returned by the lexical analyzer with as TYPE_NODE

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
%type <TYPE_VOID> program statements statement controlstatement 
%type <TYPE_VOID> ifCondition whileLoop forLoop repeatUntilLoop switchCaseLoop case caseList 
%type <TYPE_VOID> codeBlock functionArgs functionParams  functionCall 
// %type <TYPE_INT> exp
// %type <TYPE_INT> term
// %type <TYPE_INT> assignment
// %type <TYPE_DATA_TYPE> dataType declaration
%type <TYPE_DATA_MODIFIER> dataModifier

%type <TYPE_NODE> term exp assignment dataType declaration

//==============================================================================
// To solve some shift/reduce conflicts

%%

/* descriptions of expected inputs corresponding actions (in C) */
program                 : statements                            {;}
                        | functionDef                           {;}
                        | statements program                    {;}
                        | functionDef program                   {;}
                        ;
statements	        : statement ';'                         {;}
                        | '{' codeBlock '}'                     {;}
                        | controlstatement                      {;}
                        | statements '{' codeBlock '}'          {;}
                        | statements statement ';'              {;}
                        | statements controlstatement           {;}
                        ;
codeBlock               :  statements                           {;}
                        ;
controlstatement        : ifCondition
                        | whileLoop
                        | forLoop
                        | repeatUntilLoop
                        | switchCaseLoop
                        ;      
                                                 
statement               : assignment 		                {;}
                        | exp                                   {;}
                        | declaration 		                {;}
                        | EXIT 		                        {exit(EXIT_SUCCESS);}
                        | BREAK 		                {;}
                        | CONTINUE 		                {;}
                        | RETURN 		                {;}
                        | RETURN exp 		                {;}
                        | PRINT '(' exp ')' 		        {printf("%d\n", $3->value.intVal);}
                        | PRINT '(' STRING ')' 	                {printf("%s\n", $3);}
                        /* | PRINT FLOAT_NUMBER 	                {printf("%f\n", $2);} */
                        ;
//======================
/* Decleration */
//======================                    
dataModifier            : CONST                                 {;}
                        ;
dataType                : INT_DATA_TYPE                         {$$ = intNode();}
                        | FLOAT_DATA_TYPE                       {$$ = floatNode();}
                        | STRING_DATA_TYPE                      {$$ = stringNode();}
                        | BOOL_DATA_TYPE                        {$$ = boolNode();}
                        | VOID_DATA_TYPE                        {;}
                        ;
declaration             : dataType IDENTIFIER 		            {/*Check declared*/}
                        | dataType IDENTIFIER '=' exp	        {/*Check declared & check type*/updateSymbolVal($2,$4); typeCheck($1, $4);}
                        | dataModifier dataType IDENTIFIER '=' exp 	    {/*Check declared*/;}
                        ;
assignment              : IDENTIFIER '=' exp                    {/*Const, Decl, Type checks*/ /*Set Used*/updateSymbolVal($1,$3); $$ = $3;}
                        | IDENTIFIER '=' STRING                 {/*Const, Decl, Type checks*/ /*Set Used*/ updateSymbolVal($1,atoi($3));}
                        | enumDef                               {;}             //
                        | dataType enumDeclaration              {/*Check declared*/;}
                        ;
exp    	                : term                                  {$$ = $1;}
                        | functionCall                          {;}
                        /* Negation */
                        | '-' term                              {if($2->type == "int"){$$ = intNode(); $$->value.intVal = -$2->value.intVal;} else if($2->type == "float"){$$ = floatNode(); $$->value.floatVal = -$2->value.floatVal;} else exit(EXIT_FAILURE);}
                        | '~' term                              {if($2->type == "int"){$$ = intNode(); $$->value.intVal = ~$2->value.intVal;} else exit(EXIT_FAILURE);}
                        | NOT term                              {if($2->type == "bool"){$$ = boolNode(); $$->value.boolVal = !$2->value.boolVal;} else{ if($2->value.intVal){$$ = boolNode(); $$->value.boolVal = 0;} else{$$ = boolNode(); $$->value.boolVal = 1;}}}
                        // /* Arithmatic */
                        | exp '+' exp                           {if($1->type == "int" && $3->type == "int"){$$ = intNode(); $$->value.intVal = $1->value.intVal + $3->value.intVal;} else if($1->type == "float" && $3->type == "float"){$$ = floatNode(); $$->value.floatVal = $1->value.floatVal + $3->value.floatVal;} else exit(EXIT_FAILURE);}
                        | exp '-' exp                           {if($1->type == "int" && $3->type == "int"){$$ = intNode(); $$->value.intVal = $1->value.intVal - $3->value.intVal;} else if($1->type == "float" && $3->type == "float"){$$ = floatNode(); $$->value.floatVal = $1->value.floatVal - $3->value.floatVal;} else exit(EXIT_FAILURE);}
                        | exp '*' exp                           {if($1->type == "int" && $3->type == "int"){$$ = intNode(); $$->value.intVal = $1->value.intVal * $3->value.intVal;} else if($1->type == "float" && $3->type == "float"){$$ = floatNode(); $$->value.floatVal = $1->value.floatVal * $3->value.floatVal;} else exit(EXIT_FAILURE);}
                        | exp '/' exp                           {if($1->type == "int" && $3->type == "int"){$$ = intNode(); $$->value.intVal = $1->value.intVal / $3->value.intVal;} else if($1->type == "float" && $3->type == "float"){$$ = floatNode(); $$->value.floatVal = $1->value.floatVal / $3->value.floatVal;} else exit(EXIT_FAILURE);}
                        | exp '%' exp                           {if($1->type == "int" && $3->type == "int"){$$ = intNode(); $$->value.intVal = $1->value.intVal % $3->value.intVal;} else exit(EXIT_FAILURE);}
                        // /* Bitwise */
                        // | exp '|' exp                           {$$ = $1 | $3;}
                        // | exp '&' exp                           {$$ = $1 & $3;}
                        // | exp '^' exp                           {$$ = $1 ^ $3;}
                        // | exp SHL exp                           {$$ = $1 << $3;}
                        // | exp SHR exp                           {$$ = $1 >> $3;}
                        // /* Logical */
                        // | exp AND exp                           {$$ = $1 && $3;}
                        // | exp OR exp                            {$$ = $1 || $3;}
                        // /* Comparison */
                        // | exp EQ exp                            {$$ = $1 == $3;}
                        // | exp NEQ exp                           {$$ = $1 != $3;}
                        // | exp GT exp                            {$$ = $1 > $3;}
                        // | exp GEQ exp                           {$$ = $1 >= $3;}
                        // | exp LT exp                            {$$ = $1 < $3;}
                        // | exp LEQ exp                           {$$ = $1 <= $3;}
                        ;
term   	                : NUMBER                                {$$ = intNode(); $$->value.intVal = $1;  /*Pass value & type*/}
                        | FLOAT_NUMBER                          {$$ = floatNode(); $$->value.floatVal = $1; /*Pass value & type*/}
                        | TRUE_VAL                              {$$ = boolNode();  $$->value.boolVal = 1;/*Pass value & type*/}
                        | FALSE_VAL                             {$$ = boolNode();  $$->value.boolVal = 0;/*Pass value & type*/}
                        | IDENTIFIER	                        {$$ = symbolVal($1);/*Decl, Initialize checks*/ /*Set Used*/ /*Rev. symbolVal*/ /*Pass value & type*/} 
                        | '(' exp ')'                           {$$ = $2;}
                        ;
//======================
/* Conditions */
//======================
ifCondition             : IF '(' exp ')' '{' codeBlock '}'      {;}
                        | IF '(' exp ')' '{' codeBlock '}' ELSE '{' codeBlock '}'       {;}
                        | IF '(' exp ')' '{' codeBlock '}' ELSE IF '(' exp ')' '{' codeBlock '}' {;}
                        | IF '(' exp ')' '{' codeBlock '}' ELSE IF '(' exp ')' '{' codeBlock '}' ELSE '{' codeBlock '}' {;}
                        ;
case                    : CASE exp ':' statements               {;}
                        | DEFAULT ':' statements                {;}
                        ;
caseList                : caseList case
                        | case
                        ;
switchCaseLoop          : SWITCH '(' exp ')' '{' caseList '}'   {;}
                        ;
//======================
/* Loops */
//======================
whileLoop               : WHILE '(' exp ')' '{' codeBlock '}'   {;}
                        ;
forLoop                 : FOR '(' assignment ';' exp ';' assignment ')' '{' codeBlock '}' {;}
                        ;
repeatUntilLoop         : REPEAT '{' codeBlock '}' UNTIL '(' exp ')' ';'         {;}
                        ;

//======================
/* Functions */
//======================                        
functionArgs            : dataType IDENTIFIER                   {;}
                        | dataType IDENTIFIER ',' functionArgs  {;}
                        ;
functionParams          : term                                  {;}
                        | term ',' functionParams               {;}
                        ;
functionDef             : dataType IDENTIFIER '(' functionArgs ')' '{' codeBlock '}' {;}
                        | dataType IDENTIFIER '(' ')' '{' codeBlock '}'         {printf("functionDef\n");}
                        ;
functionCall            : IDENTIFIER '(' functionParams ')'     {;}
                        | IDENTIFIER '(' ')'                    {;}
                        ;
//======================
/* Enumerations */
//======================
enumDef	                : ENUM IDENTIFIER '{' enumBody '}'      {;}
                        ;
enumBody		: IDENTIFIER                            {;}
                        | IDENTIFIER '=' exp                    {;}
                        | enumBody ',' IDENTIFIER               {;}
                        | enumBody ',' IDENTIFIER '=' exp       {;}
                        ;
enumDeclaration         : IDENTIFIER IDENTIFIER                 {;}
                        | IDENTIFIER IDENTIFIER '=' exp         {;}
                        ;

//======================
/* Other */
//======================

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
struct nodeType* symbolVal(char symbol)
{
    int bucket = computeSymbolIndex(symbol);
	int value = symbolTable[bucket];

    struct nodeType* p = malloc(sizeof(struct nodeType));;
    p->type = "int";
    p->value.intVal = value;
    return p;
}

/* updates the value of a given symbol */
void updateSymbolVal(char symbol, struct nodeType* val)
{
	int bucket = computeSymbolIndex(symbol);
    if(val->type == "int"){
        printf("int\n");
        // char* value = malloc(sizeof(struct nodeType))
        // symbol_Table[bucket].value = val->value.intVal;
        // char result[50];
        // float num = 23.34;
        // sprintf(result, "%f", num);
        // printf("\n The string for the num is %s", result);
        // getchar();
    }
    else if(val->type == "float")
        printf("float\n");
    else if(val->type == "bool")
        printf("bool\n");
    else if(val->type == "string")
        printf("string\n");
	symbolTable [bucket] = val->value.intVal;
}

//------------------------------------------------------------------------------- 
// Type checking functions 
//-------------------------------------------------------------------------------  
struct nodeType* intNode() {
    struct nodeType* p = malloc(sizeof(struct nodeType));;
    p->type = "int";
    p->value.intVal = 0;
    return p;
}

struct nodeType* floatNode() {
    struct nodeType* p = malloc(sizeof(struct nodeType));;
    p->type = "float";
    p->value.intVal = 0;
    return p;
}

struct nodeType* boolNode() {
    struct nodeType* p = malloc(sizeof(struct nodeType));;
    p->type = "bool";
    p->value.intVal = 0;
    return p;
}

struct nodeType* stringNode() {
    struct nodeType* p = malloc(sizeof(struct nodeType));;
    p->type = "string";
    p->value.intVal = 0;
    return p;
}

void typeCheck(struct nodeType* type1, struct nodeType* type2) {
    if(strcmp(type1->type, type2->type) != 0) {
        printf("Type Error\n"); //To-Do:
        exit(EXIT_FAILURE);
    }
}

//-------------------------------------------------------------------------------
int main (void) {
	/* init symbol table */
	int i;
	for(i=0; i<52; i++) {
		symbolTable[i] = 0;
	}

	return yyparse ( );
}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);} 

