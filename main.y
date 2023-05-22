%{
/* C declarations used in actions */
//==============================================================================
// Some useful includes
//======================
#include <stdio.h>     
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define SHOW_Quads 1
void yyerror (char *s); // in case of errors
int yylex();
// show semantic erros
#define SHOW_SEMANTIC_ERROR 1
#define TYPE_MISMATCH 1
#define UNDECLARED 2
#define UNINITIALIZED 3
#define UNUSED 4
#define REDECLARED 5
#define CONSTANT 6
#define OUT_OF_SCOPE 7
void Log_SEMANTIC_ERROR(int semanticError, char var, int line)
{
    if(SHOW_SEMANTIC_ERROR)
    {
        switch(semanticError)
        {
                case TYPE_MISMATCH:
                        printf("SemanticError(%d) Type mismatch error with %c\n", line, var);
                        break;
                case UNDECLARED: // TODO
                        printf("SemanticError(%d) Undeclared variable %c at line %d\n", var, line);
                        break;
                case UNINITIALIZED:
                        printf("SemanticError(%d) Uninitialized variable %c\n", line, var);
                        break;
                case UNUSED:
                        printf("SemanticError(%d) Unused variable %c\n", line, var);
                        break;
                case REDECLARED:
                        printf("SemanticError(%d) Redeclared variable %c\n", line, var);
                        break;
                case CONSTANT:
                        printf("SemanticError(%d) Constant variable %c\n", line, var);
                        break;
                case OUT_OF_SCOPE:
                        printf("SemanticError(%d) Variable %c out of scope\n", line, var);
                        break;
                default:
                        printf("SemanticError(%d) Unknown error at line %c\n", line);
                        break;
        }
        printSymbolTable();
        exit(EXIT_FAILURE);
    }
}
char buffer[500];

int scope_idx = 1;
int scope_cnt = 0;
int scopes[100];

// Scope functions
void enterScope();
void exitScope();

// Op functions
struct nodeType* arithmatic(struct nodeType* op1, struct nodeType*op2, char op);
struct nodeType* bitwise(struct nodeType* op1, struct nodeType*op2, char op);
struct nodeType* logical(struct nodeType* op1, struct nodeType*op2, char op);
struct nodeType* comparison(struct nodeType* op1, struct nodeType*op2, char* op);

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
        int isDecl, isConst, isInit, isUsed, scope;
};
// Symbol table functions
struct symbol symbol_Table [100]; // 26 for lower case, 26 for upper case
void insert(char name, char* type, int isConst, int isInit, int isUsed, int scope);
struct nodeType* symbolVal(char symbol); // returns the value of a given symbol
void updateSymbolName(char symbol, char newName);
void updateSymbolVal(char symbol, struct nodeType* val); // updates the value of a given symbol

void checkSameScope(char name);
void checkOutOfScope(char name);

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
                        | '{'{enterScope();} codeBlock '}'{exitScope();}
                        | controlstatement                      {;}
                        | statements '{'{enterScope();} codeBlock '}'{exitScope();}          {;}
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
                    
declaration             : dataType IDENTIFIER 		        {checkSameScope($2);
                                                                insert($2, $1->type, 0, 0, 0, scopes[scope_idx-1]);/*Check declared when inserting*/}
                        | dataType IDENTIFIER                   {checkSameScope($2);} '=' exp {typeCheck($1, $5); insert($2, $1->type, 0, 0, 0, scopes[scope_idx-1]); updateSymbolVal($2,$5); setInit($2);}
                        | dataModifier dataType IDENTIFIER      {checkSameScope($3);} '=' exp 
                                                                {typeCheck($2, $6); insert($3, $2->type, 1, 0, 0, scopes[scope_idx-1]); updateSymbolVal($3,$6); setInit($3);}
                        ;
assignment              : IDENTIFIER '=' exp                    {checkOutOfScope($1); checkConstant($1); 
                                                                typeCheck2($1, $3); setUsed($1); updateSymbolVal($1,$3); $$ = $3; setInit($1);}
                        | IDENTIFIER '=' STRING                 {checkOutOfScope($1);  checkConstant($1); 
                                                                /*Const, Decl, Type checks*/ /*Set Used*/ updateSymbolVal($1,atoi($3)); setInit($1);}
                        | enumDef                               {;}             //
                        | dataType enumDeclaration              {/*Check declared*/;}
                        ;
exp    	                : term                                  {$$ = $1;}
                        | functionCall                          {;}
                        /* Negation */
                        | '-' term                              {quadInstruction("NEG"); if($2->type == "int"){$$ = intNode(); $$->value.intVal = -$2->value.intVal;} else if($2->type == "float"){$$ = floatNode(); $$->value.floatVal = -$2->value.floatVal;} else exit(EXIT_FAILURE);}
                        | '~' term                              {quadInstruction("COMPLEMENT"); if($2->type == "int"){$$ = intNode(); $$->value.intVal = ~$2->value.intVal;} else exit(EXIT_FAILURE);}
                        | NOT term                              {quadInstruction("NOT"); if($2->type == "bool"){$$ = boolNode(); $$->value.boolVal = !$2->value.boolVal;} else{ if($2->value.intVal){$$ = boolNode(); $$->value.boolVal = 0;} else{$$ = boolNode(); $$->value.boolVal = 1;}}}
                        // /* Arithmatic */
                        | exp '+' exp                           {quadInstruction("ADD"); $$ = arithmatic($1,$3,'+');}
                        | exp '-' exp                           {quadInstruction("SUB"); $$ = arithmatic($1,$3,'-');}
                        | exp '*' exp                           {quadInstruction("MUL"); $$ = arithmatic($1,$3,'*');}
                        | exp '/' exp                           {quadInstruction("DIV"); $$ = arithmatic($1,$3,'/');}
                        | exp '%' exp                           {quadInstruction("MOD"); $$ = arithmatic($1,$3,'%');}
                        // /* Bitwise */
                        | exp '|' exp                           {quadInstruction("BITWISE_OR"); $$ = bitwise($1,$3,'|');}
                        | exp '&' exp                           {quadInstruction("BITWISE_AND"); $$ = bitwise($1,$3,'&');}
                        | exp '^' exp                           {quadInstruction("BITWISE_XOR"); $$ = bitwise($1,$3,'^');}
                        | exp SHL exp                           {quadInstruction("SHL"); $$ = bitwise($1,$3,'<');}
                        | exp SHR exp                           {quadInstruction("SHR"); $$ = bitwise($1,$3,'>');}
                        // /* Logical */
                        | exp OR exp                            {quadInstruction("LOGICAL_OR"); $$ = logical($1,$3,'|');}
                        | exp AND exp                           {quadInstruction("LOGICAL_AND"); $$ = logical($1,$3,'&');}
                        // /* Comparison */
                        | exp EQ exp                            {quadInstruction("EQ"); $$ = comparison($1,$3,"==");}
                        | exp NEQ exp                           {quadInstruction("NEQ"); $$ = comparison($1,$3,"!=");}
                        | exp GT exp                            {quadInstruction("GT"); $$ = comparison($1,$3,">");}
                        | exp GEQ exp                           {quadInstruction("GEQ"); $$ = comparison($1,$3,">=");}
                        | exp LT exp                            {quadInstruction("LT"); $$ = comparison($1,$3,"<");}
                        | exp LEQ exp                           {quadInstruction("LEQ"); $$ = comparison($1,$3,"<=");}
                        ;
term   	                : NUMBER                                {quadPushInt($1); $$ = intNode(); $$->value.intVal = $1;  /*Pass value & type*/}
                        | FLOAT_NUMBER                          {quadPushFloat($1); $$ = floatNode(); $$->value.floatVal = $1; /*Pass value & type*/}
                        | TRUE_VAL                              {quadPushInt(1); $$ = boolNode();  $$->value.boolVal = 1;/*Pass value & type*/}
                        | FALSE_VAL                             {quadPushInt(0); $$ = boolNode();  $$->value.boolVal = 0;/*Pass value & type*/}
                        | IDENTIFIER	                        {quadPushIdentifier($1); checkOutOfScope($1); checkInitialization($1); $$ = symbolVal($1);/*Decl, Initialize checks*/ /*Set Used*/ /*Rev. symbolVal*/ /*Pass value & type*/} 
                        | '(' exp ')'                           {$$ = $2;}
                        ;
//======================
/* Conditions */
//======================
ifCondition             : IF '(' exp ')' '{'{enterScope();} codeBlock '}'{exitScope();} ElseCondition {;}
                        ;
ElseCondition           : {;}
                        | ELSE '{'{enterScope();} codeBlock '}'{exitScope();} {;}
                        | ELSE IF '(' exp ')' '{'{enterScope();} codeBlock '}'{exitScope();} ElseCondition {;}
                        ;
case                    : CASE exp ':' statements               {;}
                        | DEFAULT ':' statements                {;}
                        ;
caseList                : caseList case
                        | case
                        ;
switchCaseLoop          : SWITCH '(' exp ')' '{'{enterScope();} caseList '}'{exitScope();}   {;}
                        ;
//======================
/* Loops */
//======================
whileLoop               : WHILE '(' exp ')' '{'{enterScope();} codeBlock '}'{exitScope();}   {;}
                        ;
forLoop                 : FOR '(' assignment ';' exp ';' assignment ')' '{'{enterScope();} codeBlock '}'{exitScope();} {;}
                        ;
repeatUntilLoop         : REPEAT '{'{enterScope();} codeBlock '}'{exitScope();} UNTIL '(' exp ')' ';'         {;}
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
functionDef             : dataType IDENTIFIER '(' functionArgs ')' {checkSameScope($2); insert($2, $1->type, 0, 0, 0, scopes[scope_idx-1]);} 
                        '{'{enterScope();} codeBlock '}' {exitScope();}
                        | dataType IDENTIFIER '(' ')' '{'{enterScope();} codeBlock '}'              {exitScope();}
                        ;
functionCall            : IDENTIFIER '(' functionParams ')'     {checkOutOfScope($1);}
                        | IDENTIFIER '(' ')'                    {checkOutOfScope($1);}
                        ;
//======================
/* Enumerations */
//======================
enumDef	                : ENUM IDENTIFIER {checkSameScope($2); insert($2, "enum", 0, 0, 0, scopes[scope_idx-1]);} 
                        '{'{enterScope();} enumBody '}'{exitScope();}
                        ;
enumBody		        : IDENTIFIER                            {;}
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
//======================
/* Quadruples */
//======================    
void quadInstruction(const char* instruction)
{
        if (SHOW_Quads) {
               
                printf("Quads() %s\n", instruction);
        }
}
void quadPushInt(int val)
{
       if (SHOW_Quads) {
               printf("Quads() push %d\n", val);
       }
}
void quadPushFloat(float val)
{
       if (SHOW_Quads) {
               printf("Quads() push %f\n", val);
       }
}
void quadPushIdentifier(char symbol)
{
       if (SHOW_Quads) {
               printf("Quads() push %c\n", symbol);
       }
}
void quadPop(char symbol)
{
       if (SHOW_Quads) {
               printf("Quads() pop %c\n\n", symbol);
       }
}
int sym_table_idx = 0;

/* C code */
int computeSymbolIndex(char token){
    int lvl;
    for(int i=sym_table_idx-1; i>=0 ;i--) {
        if(symbol_Table[i].name == token) {
            lvl = symbol_Table[i].scope;
            for(int j=scope_idx-1;j>=0;j--) {
                if(lvl == scopes[j]) {
                    return i;
                }
            }
        }
    }
} 

//======================
// Symbol table functions
//======================
void insert(char name, char* type, int isConst, int isInit, int isUsed, int scope){

    symbol_Table [sym_table_idx].name = name;
    symbol_Table [sym_table_idx].type = type;
    symbol_Table [sym_table_idx].isDecl = 1;
    symbol_Table [sym_table_idx].isConst = isConst;

    symbol_Table [sym_table_idx].isInit = isInit;
    symbol_Table [sym_table_idx].isUsed = isUsed;
    symbol_Table [sym_table_idx].scope = scope;
    ++sym_table_idx;

    /* printf("SymbolTable() inserted: %c, declared:%d, const:%d, Symbol table idx:%d\n", symbol_Table [sym_table_idx-1].name, symbol_Table [sym_table_idx-1].isDecl, symbol_Table [sym_table_idx-1].isConst, sym_table_idx); */
}

/* returns the value of a given symbol */
struct nodeType* symbolVal(char symbol){

    int bucket = computeSymbolIndex(symbol);
    struct nodeType* p = malloc(sizeof(struct nodeType));;
    p->type = symbol_Table[bucket].type;

    if(strcmp(symbol_Table[bucket].type, "int") == 0)
        p->value.intVal = symbol_Table[bucket].value.intVal;
    else if(strcmp(symbol_Table[bucket].type, "float") == 0)
        p->value.floatVal = symbol_Table[bucket].value.floatVal;
    else if(strcmp(symbol_Table[bucket].type, "bool") == 0)
        p->value.boolVal = symbol_Table[bucket].value.boolVal;
    else if(strcmp(symbol_Table[bucket].type, "string") == 0)
        p->value.stringVal = symbol_Table[bucket].value.stringVal;

    return p;
}

void updateSymbolName(char symbol, char newName){
    int bucket = computeSymbolIndex(symbol);
    symbol_Table [bucket].name = newName;
}


/* updates the value of a given symbol */
void updateSymbolVal(char symbol, struct nodeType* val){
	int bucket = computeSymbolIndex(symbol);
    if(strcmp(symbol_Table[bucket].type, "int") == 0)
        symbol_Table [bucket].value.intVal = val->value.intVal;
    else if(strcmp(symbol_Table[bucket].type, "float") == 0)
        symbol_Table[bucket].value.floatVal = val->value.floatVal;
    else if(strcmp(symbol_Table[bucket].type, "bool") == 0)
        symbol_Table[bucket].value.boolVal = val->value.boolVal;
    else if(strcmp(symbol_Table[bucket].type, "string") == 0)
        symbol_Table[bucket].value.stringVal = val->value.stringVal;
}

void printSymbolTable(){
    printf("Symbol Table:\n");
    for(int i=0;i<sym_table_idx;i++){
        printf("Name:%c,Type:%s,Value:%d,Declared:%d,Initialized:%d,Used:%d,Const:%d,Scope:%d\n", symbol_Table[i].name, symbol_Table[i].type, symbol_Table[i].value.intVal, symbol_Table[i].isDecl, symbol_Table[i].isInit, symbol_Table[i].isUsed, symbol_Table[i].isConst, symbol_Table[i].scope);
    }

    // Print to file
    FILE *f = fopen("symbol_table.txt", "w");
    if (f == NULL)
    {
        printf("Error opening file!\n");
        exit(EXIT_FAILURE);
    }

    /* print some text */
    fprintf(f, "Symbol Table:\n");
    for(int i=0;i<sym_table_idx;i++){
        fprintf(f, "Name:%c,Type:%s,Value:%d,Declared:%d,Initialized:%d,Used:%d,Const:%d,Scope:%d\n", symbol_Table[i].name, symbol_Table[i].type, symbol_Table[i].value.intVal, symbol_Table[i].isDecl, symbol_Table[i].isInit, symbol_Table[i].isUsed, symbol_Table[i].isConst, symbol_Table[i].scope);
    }
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
                /* printf("Invalid operator\n"); */
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
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
                /* printf("Invalid operator\n"); */
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
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
                /* printf("Invalid operator\n"); */
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
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
                /* printf("Invalid operator\n"); */
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
        }
    }
    else{
        /* printf("Type Error\n"); */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
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
                /* printf("Invalid operator\n"); */
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
        }
    }
    else{
        /* printf("Type Error\n"); */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
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
                /* printf("Invalid operator\n"); */
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
        }
    }
    else{
        /* printf("Type Error\n"); /// ISSUE HERE
        printf("%s\n", op1->type);
        printf("%s\n", op2->type); */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0); // TODO
    }
    return p;
}

struct nodeType* comparison(struct nodeType* op1, struct nodeType*op2, char* op){
    struct nodeType* p = malloc(sizeof(struct nodeType));
    p->type = "bool";
    if(strcmp(op1->type, op2->type) != 0)
    {
        /* printf("Type mismatch\n"); */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0); // TODO
    }

    if( strcmp(op1->type,"float") == 0){
        if(strcmp(op, "==") == 0){
            p->value.boolVal = op1->value.floatVal == op2->value.floatVal;
        }
        else if(strcmp(op, "!=") == 0){
            p->value.boolVal = op1->value.floatVal != op2->value.floatVal;
        }
        else if(strcmp(op, ">") == 0){
            p->value.boolVal = op1->value.floatVal > op2->value.floatVal;
        }
        else if(strcmp(op, ">=") == 0){
            p->value.boolVal = op1->value.floatVal >= op2->value.floatVal;
        }
        else if(strcmp(op, "<") == 0){
            p->value.boolVal = op1->value.floatVal < op2->value.floatVal;
        }
        else if(strcmp(op, "<=") == 0){
            p->value.boolVal = op1->value.floatVal <= op2->value.floatVal;
        }
        else{
            /* printf("Invalid operator\n"); */
            Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
        }
    }
    else{
        if(strcmp(op, "==") == 0){
            p->value.boolVal = op1->value.intVal == op2->value.intVal;
        }
        else if(strcmp(op, "!=") == 0){
            p->value.boolVal = op1->value.intVal != op2->value.intVal;
        }
        else if(strcmp(op, ">") == 0){
            p->value.boolVal = op1->value.intVal > op2->value.intVal;
        }
        else if(strcmp(op, ">=") == 0){
            p->value.boolVal = op1->value.intVal >= op2->value.intVal;
        }
        else if(strcmp(op, "<") == 0){
            p->value.boolVal = op1->value.intVal < op2->value.intVal;
        }
        else if(strcmp(op, "<=") == 0){
            p->value.boolVal = op1->value.intVal <= op2->value.intVal;
        }
        else{
            /* printf("Invalid operator\n"); */
            Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type, 0);
        }
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
        /* printf("Type Error\n"); //To-Do: */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, type2->type, 0); // TODO
    }
    return;
}

void typeCheck2(char symbol, struct nodeType* type2) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == symbol) {
            for(int j=scope_idx-1;j>=0;j--) {
                if(symbol_Table[i].scope == scopes[j]) {
                    if(strcmp(symbol_Table[i].type, type2->type) != 0) {
                        Log_SEMANTIC_ERROR(TYPE_MISMATCH, symbol_Table[i].name, 0);
                        /* printf("Type Errrror\n"); //To-Do:
                        printf("%s\n", symbol_Table[i].type); */
                    }
                    else{
                        return;
                    }
                }
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

void checkSameScope(char name) {
    int lvl;
    for(int i=0; i<sym_table_idx ;i++) {
        if(symbol_Table[i].name == name) {
            lvl = symbol_Table[i].scope;
            if(lvl == scopes[scope_idx-1]) {
                /* printf("Variable %c already declared in the same scope\n", name); */
                Log_SEMANTIC_ERROR(REDECLARED, name, 0);
            }
        }
    }
}

void checkOutOfScope(char name) {
    int lvl;
    for(int i=sym_table_idx-1; i>=0 ;i--) {
        if(symbol_Table[i].name == name) {
            lvl = symbol_Table[i].scope;
            for(int j=scope_idx-1;j>=0;j--) {
                if(lvl == scopes[j]) {
                    return;
                }
            }
        }
    }
    /* printf("Variable %c out of scope(undeclared or removed)\n", name); */
    Log_SEMANTIC_ERROR(OUT_OF_SCOPE, name, 0);

}
// this function checks if a variable is initialized before use
void checkInitialization(char name) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        
        if(symbol_Table[i].name == name) {
            if(symbol_Table[i].isInit == 0) {
                /* printf("Variable %c not initialized\n", name); */
                Log_SEMANTIC_ERROR(UNINITIALIZED, name, 0);
                return;
            }
        }
    }
}

// this function checks that all variables are used
void checkUsage() {
    for(int i=0;i<sym_table_idx;i++) {
        if(symbol_Table[i].isUsed == 0) {
            /* printf("Variable %c not used\n", symbol_Table[i].name); */
            Log_SEMANTIC_ERROR(UNUSED, symbol_Table[i].name, 0);
        }
    }
}

// this function checks if a constant variable is re-assigned a value  
void checkConstant(char name) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == name) {
            for(int j=scope_idx-1;j>=0;j--) {
                if(symbol_Table[i].scope == scopes[j]) {
                    if(symbol_Table[i].isConst == 1) {
                        /* printf("Constant variable %c cannot be assigned a value\n", name); */
                        Log_SEMANTIC_ERROR(CONSTANT, name, 0);
                        
                        return;
                    }
                    else{
                        return;
                    }
                }
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
// ------------------------------------------------------------------------------- 
// Scope functions 
// -------------------------------------------------------------------------------  
void enterScope() {
    scopes[scope_idx] = scope_cnt;
    scope_idx++;
    scope_cnt++;
}

void exitScope() {
    scope_idx--;
}
//-------------------------------------------------------------------------------
int main (void) {

        /* init symbol table */
    
        yyparse ( );  
        checkUsage();
        printSymbolTable();

    return 0;
}

void yyerror (char *s) {printf ("%s\n", s);} 