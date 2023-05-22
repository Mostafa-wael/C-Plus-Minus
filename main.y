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

int scope_idx = 0;
int scope_cnt = 0;
int scopes[100];
for(int i=0;i<100;i++) {
    scopes[i] = -1;
}

struct nodeType* arithmatic(struct nodeType* op1, struct nodeType*op2, char op);
struct nodeType* bitwise(struct nodeType* op1, struct nodeType*op2, char op);
struct nodeType* logical(struct nodeType* op1, struct nodeType*op2, char op);

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
void checkConstant(char name);
void checkInitialization(char name);
int checkDeclaration(char name);
void checkUsage();

void setConst(char name);
void setInit(char name);
void setUsed(char name);
void setDecl(char name);

// Symbol table
//======================
struct symbol {
        char name;
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
struct symbol symbol_Table [100]; // 26 for lower case, 26 for upper case
void insert(char name, char* type, int isConst, int isInit, int isUsed);
struct nodeType* symbolVal(char symbol); // returns the value of a given symbol
void updateSymbolName(char symbol, char newName);
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
declaration             : dataType IDENTIFIER 		            {if(checkDeclaration($2)) exit(EXIT_FAILURE); 
                                                                insert($2, $1->type, 0, 0, 0);/*Check declared when inserting*/}
                        | dataType IDENTIFIER                   {if(checkDeclaration($2)) exit(EXIT_FAILURE);} '=' exp	    
                                                                {typeCheck($1, $5); insert($2, $1->type, 0, 0, 0); updateSymbolVal($2,$5); }
                        | dataModifier dataType IDENTIFIER      {if(checkDeclaration($3)) exit(EXIT_FAILURE);} '=' exp 
                                                                {typeCheck($2, $6); insert($3, $2->type, 1, 0, 0); updateSymbolVal($3,$6); }
                        ;
assignment              : IDENTIFIER '=' exp                    {if(!checkDeclaration($1)) exit(EXIT_FAILURE);  checkConstant($1); 
                                                                typeCheck2($1, $3); setUsed($1); updateSymbolVal($1,$3); $$ = $3;}
                        | IDENTIFIER '=' STRING                 {if(!checkDeclaration($1)) exit(EXIT_FAILURE);  checkConstant($1); 
                                                                /*Const, Decl, Type checks*/ /*Set Used*/ updateSymbolVal($1,atoi($3));}
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
                        | exp '+' exp                           {$$ = arithmatic($1,$3,'+');}
                        | exp '-' exp                           {$$ = arithmatic($1,$3,'-');}
                        | exp '*' exp                           {$$ = arithmatic($1,$3,'*');}
                        | exp '/' exp                           {$$ = arithmatic($1,$3,'/');}
                        | exp '%' exp                           {$$ = arithmatic($1,$3,'%');}
                        // /* Bitwise */
                        | exp '|' exp                           {$$ = bitwise($1,$3,'|');}
                        | exp '&' exp                           {$$ = bitwise($1,$3,'&');}
                        | exp '^' exp                           {$$ = bitwise($1,$3,'^');}
                        | exp SHL exp                           {$$ = bitwise($1,$3,'<');}
                        | exp SHR exp                           {$$ = bitwise($1,$3,'>');}
                        // /* Logical */
                        | exp AND exp                           {$$ = logical($1,$3,'&');}
                        | exp OR exp                            {$$ = logical($1,$3,'|');}
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
                        | IDENTIFIER	                        {$$ = symbolVal($1); checkDeclaration($1); checkInitialization($1); /*Decl, Initialize checks*/ /*Set Used*/ /*Rev. symbolVal*/ /*Pass value & type*/} 
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
functionCall            : IDENTIFIER '(' functionParams ')'     {checkDeclaration($1);}
                        | IDENTIFIER '(' ')'                    {checkDeclaration($1);}
                        ;
//======================
/* Enumerations */
//======================
enumDef	                : ENUM IDENTIFIER '{' enumBody '}'      {;}
                        ;
enumBody		        : IDENTIFIER                            {;}
                        | IDENTIFIER '=' exp                    {;}
                        | enumBody ',' IDENTIFIER               {;}
                        | enumBody ',' IDENTIFIER '=' exp       {;}
                        ;
enumDeclaration         : IDENTIFIER IDENTIFIER                 {checkDeclaration($1);}
                        | IDENTIFIER IDENTIFIER '=' exp         {checkDeclaration($1);}
                        ;

//======================
/* Other */
//======================

%%  

int sym_table_idx = 0;

/* C code */
int computeSymbolIndex(char token){
	int idx = -1;
	if(islower(token)) {
		idx = token - 'a' + 26;
	} else if(isupper(token)) {
		idx = token - 'A';
	}
	return idx;
} 

//======================
// Symbol table functions
//======================
void insert(char name, char* type, int isConst, int isInit, int isUsed){

    symbol_Table [sym_table_idx].name = name;
    symbol_Table [sym_table_idx].type = type;
    symbol_Table [sym_table_idx].isDecl = 1;
    symbol_Table [sym_table_idx].isConst = isConst;

    // symbol_Table [sym_table_idx].value.intVal = value;
    symbol_Table [sym_table_idx].isInit = isInit;
    symbol_Table [sym_table_idx].isUsed = isUsed;
    ++sym_table_idx;

    // printf("inserted: %c, declared:%d, Symbol table idx:%d\n", symbol_Table [sym_table_idx-1].name, symbol_Table [sym_table_idx-1].isDecl, sym_table_idx);
}

/* returns the value of a given symbol */
struct nodeType* symbolVal(char symbol){
    int bucket = computeSymbolIndex(symbol);
	int value = symbol_Table[bucket].value.intVal;

    struct nodeType* p = malloc(sizeof(struct nodeType));;
    p->type = "int";
    p->value.intVal = value;
    return p;
}

void updateSymbolName(char symbol, char newName){
    int bucket = computeSymbolIndex(symbol);
    symbol_Table [bucket].name = newName;
}


/* updates the value of a given symbol */
void updateSymbolVal(char symbol, struct nodeType* val){
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
	symbol_Table [bucket].value.intVal = val->value.intVal;
}

//------------------------------------------------------------------------------- 
// Op functions 
//-------------------------------------------------------------------------------  
struct nodeType* arithmatic(struct nodeType* op1, struct nodeType*op2, char op){
    struct nodeType* p = malloc(sizeof(struct nodeType));
    if(strcmp(op1->type, "int") == 0 && strcmp(op2->type, "int") == 0){
        p->type = "int";
        switch(op){
            case '+':
                p->value.intVal = op1->value.intVal + op2->value.intVal;
                break;
            case '-':
                p->value.intVal = op1->value.intVal - op2->value.intVal;
                break;
            case '*':
                p->value.intVal = op1->value.intVal * op2->value.intVal;
                break;
            case '/':
                p->value.intVal = op1->value.intVal / op2->value.intVal;
                break;
            case '%':
                p->value.intVal = op1->value.intVal % op2->value.intVal;
                break;
            default:
                printf("Invalid operator\n");
                exit(EXIT_FAILURE);
        }
    }
    else if(strcmp(op1->type, "float") == 0 && strcmp(op2->type, "float") == 0){
        p->type = "float";
        switch(op){
            case '+':
                p->value.floatVal = op1->value.floatVal + op2->value.floatVal;
                break;
            case '-':
                p->value.floatVal = op1->value.floatVal - op2->value.floatVal;
                break;
            case '*':
                p->value.floatVal = op1->value.floatVal * op2->value.floatVal;
                break;
            case '/':
                p->value.floatVal = op1->value.floatVal / op2->value.floatVal;
                break;
            default:
                printf("Invalid operator\n");
                exit(EXIT_FAILURE);
        }
    }
    else if (strcmp(op1->type, "int") == 0 && strcmp(op2->type, "float") == 0){
        p->type = "float";
        switch(op){
            case '+':
                p->value.floatVal = op1->value.intVal + op2->value.floatVal;
                break;
            case '-':
                p->value.floatVal = op1->value.intVal - op2->value.floatVal;
                break;
            case '*':
                p->value.floatVal = op1->value.intVal * op2->value.floatVal;
                break;
            case '/':
                p->value.floatVal = op1->value.intVal / op2->value.floatVal;
                break;
            default:
                printf("Invalid operator\n");
                exit(EXIT_FAILURE);
        }
    }
    else if (strcmp(op1->type, "float") == 0 && strcmp(op2->type, "int") == 0){
        p->type = "float";
        switch(op){
            case '+':
                p->value.floatVal = op1->value.floatVal + op2->value.intVal;
                break;
            case '-':
                p->value.floatVal = op1->value.floatVal - op2->value.intVal;
                break;
            case '*':
                p->value.floatVal = op1->value.floatVal * op2->value.intVal;
                break;
            case '/':
                p->value.floatVal = op1->value.floatVal / op2->value.intVal;
                break;
            default:
                printf("Invalid operator\n");
                exit(EXIT_FAILURE);
        }
    }
    else{
        printf("Type Error\n");
        exit(EXIT_FAILURE);
    }
    return p;
}

struct nodeType* bitwise(struct nodeType* op1, struct nodeType*op2, char op){
    struct nodeType* p = malloc(sizeof(struct nodeType));
    if(strcmp(op1->type, "int") == 0 && strcmp(op2->type, "int") == 0){
        p->type = "int";
        switch(op){
            case '|':
                p->value.intVal = op1->value.intVal | op2->value.intVal;
                break;
            case '&':
                p->value.intVal = op1->value.intVal & op2->value.intVal;
                break;
            case '^':
                p->value.intVal = op1->value.intVal ^ op2->value.intVal;
                break;
            case '<':
                p->value.intVal = op1->value.intVal << op2->value.intVal;
                break;
            case '>':
                p->value.intVal = op1->value.intVal >> op2->value.intVal;
                break;
            default:
                printf("Invalid operator\n");
                exit(EXIT_FAILURE);
        }
    }
    else{
        printf("Type Error\n");
        exit(EXIT_FAILURE);
    }
    return p;
}

struct nodeType* logical(struct nodeType* op1, struct nodeType*op2, char op){
    struct nodeType* p = malloc(sizeof(struct nodeType));
    if(strcmp(op1->type, "bool") == 0 && strcmp(op2->type, "bool") == 0){
        p->type = "bool";
        switch(op){
            case '&':
                p->value.boolVal = op1->value.boolVal && op2->value.boolVal;
                break;
            case '|':
                p->value.boolVal = op1->value.boolVal || op2->value.boolVal;
                break;
            default:
                printf("Invalid operator\n");
                exit(EXIT_FAILURE);
        }
    }
    else{
        printf("Type Error\n"); /// ISSUE HERE
        printf("%s\n", op1->type);
        printf("%s\n", op2->type);
        exit(EXIT_FAILURE);
    }
    return p;
}

//------------------------------------------------------------------------------- 
// Type checking functions 
//-------------------------------------------------------------------------------  
struct nodeType* intNode() {
    struct nodeType* p = malloc(sizeof(struct nodeType));
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
    return;
}

void typeCheck2(char symbol, struct nodeType* type2) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == symbol) {
            if(strcmp(symbol_Table[i].type, type2->type) != 0) {
                printf("Type Error\n"); //To-Do:
                exit(EXIT_FAILURE);
            }
        }
    }
    return;
}

// ------------------------------------------------------------------------------- 
// checking functions 
// -------------------------------------------------------------------------------  

// this function checks if a variable is used before declaration or out of scope
int checkDeclaration(char name) {

    //TODO: check for scope
    //TODO: use yytext 

    int found = 0;

    for(int i=0; i<sym_table_idx ;i++) {
            if(symbol_Table[i].name == name) {
                found = 1;
                break;
            }
    }

    // if(!found) {
    //     printf("Variable %c not declared\n", name);
    // }
    return found;
}

// this function checks if a variable is initialized before use
void checkInitialization(char name) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        
        if(symbol_Table[i].name == name) {
            if(symbol_Table[i].isInit == 0) {
                printf("Variable %c not initialized\n", name);
                return;
            }
        }
    }
}

// this function checks that all variables are used
void checkUsage() {
    for(int i=0;i<sym_table_idx;i++) {
        if(symbol_Table[i].isUsed == 0) {
            printf("Variable %c not used\n", symbol_Table[i].name);
        }
    }
}

// this function checks if a constant variable is re-assigned a value  
void checkConstant(char name) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == name) {
            printf("Variable %c, Constant:\n", name, symbol_Table[i].isConst);
            if(symbol_Table[i].isConst == 1) {
                printf("Constant variable %c cannot be assigned a value\n", name);
                exit(EXIT_FAILURE);
                return;
            }
        }
    }
}

// ------------------------------------------------------------------------------- 
// Setter functions 
// -------------------------------------------------------------------------------  
void setConst(char name) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == name) {
            symbol_Table[i].isConst = 1;
            return;
        }
    }
}

void setInit(char name) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == name) {
            symbol_Table[i].isInit = 1;
            return;
        }
    }
}

void setUsed(char name) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == name) {
            symbol_Table[i].isUsed = 1;
            return;
        }
    }
}

void setDecl(char name) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == name) { 
            symbol_Table[i].isDecl = 1;
            return;
        }
    }
}
//-------------------------------------------------------------------------------
int main (void) {
	/* init symbol table */
	
    
    yyparse ( );
	
    checkUsage();

    return 0;
}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);} 