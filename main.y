%{
/* C declarations used in actions */
//==============================================================================
// Some useful includes
//======================
#include <stdio.h>     
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
void yyerror (char *s); // in case of errors
int yylex();
extern int line;
extern int yyleng;


// Quadruples
//======================
#define SHOW_Quads 1
void quadPopIdentifier(char symbol);
void quadInstruction(const char* instruction);
void quadPushInt(int val);
void quadPushFloat(float val);
void quadPushIdentifier(char symbol);
void quadPushString(char* str);
void quadStartFunction(char function);
void quadEndFunction(char function);
void quadCallFunction(char function);
void quadReturn();
void quadJumpFalseLabel(int labelNum);
void quadPopLabel();

void quadJumpEndLabel();
void quadPushEndLabel(int endLabelNum);
void quadPopEndLabel();

#define MAX_STACK_SIZE 100
int labelNum = 0;
int labelStackPointer = -1;
int labelStack[MAX_STACK_SIZE];

int endLabelNum = 0;
int endLabelstackPointer = -1;
int endLabelStack[MAX_STACK_SIZE];

void quadPushLastIdentifierStack(char identifier);
void quadPeakLastIdentifierStack();
void quadPopLastIdentifierStack();

int lastIdentifierStackPointer = -1;
char lastIdentifierStack[MAX_STACK_SIZE];


void quadJumpStartLabel();
void quadPushStartLabel(int startLabelNum);
void quadPopStartLabel();

int startLabelNum = 0;
int startLabelstackPointer = -1;
int startLabelStack[MAX_STACK_SIZE];
// Semantic Erros
//======================
#define SHOW_SEMANTIC_ERROR 1
#define TYPE_MISMATCH 1
#define UNDECLARED 2
#define UNINITIALIZED 3
#define UNUSED 4
#define REDECLARED 5
#define CONSTANT 6
#define OUT_OF_SCOPE 7
#define CONSTANT_IF 8
void Log_SEMANTIC_ERROR(int semanticError, char var)
{
        int errorLine = line;
        if(SHOW_SEMANTIC_ERROR)
        {
        switch(semanticError)
        {
                case TYPE_MISMATCH:
                        printf("Semantic error (%d) Type mismatch error with %c\n", errorLine, var);
                        break;
                case UNDECLARED: // TODO
                        printf("Semantic error (%d) Undeclared variable %c\n", errorLine, var);
                        break;
                case UNINITIALIZED:
                        printf("Semantic error (%d) Uninitialized variable %c\n", errorLine, var);
                        break;
                case UNUSED:
                        printf("Semantic error (%d) Unused variable %c\n", errorLine, var);
                        break;
                case REDECLARED:
                        printf("Semantic error (%d) Redeclared variable %c\n", errorLine, var);
                        break;
                case CONSTANT:
                        printf("Semantic error (%d) Constant variable %c\n", errorLine, var);
                        break;
                case OUT_OF_SCOPE:
                        printf("Semantic error (%d) Variable %c out of scope\n", errorLine, var);
                        break;
                case CONSTANT_IF:
                        printf("Semantic error (%d) If statement is always %s\n", errorLine, (var ? "True" : "False"));
                        break;
                default:
                        printf("Semantic error (%d) Unknown error at\n", errorLine);
                        break;
        }
        printSymbolTable();
        // exit(EXIT_FAILURE);
        }
}
char buffer[500];

int scope_idx = 1;
int scope_cnt = 1;
int scopes[100];

// Scope functions
//======================
void enterScope();
void exitScope();

// Op functions
//======================
struct nodeType* arithmatic(struct nodeType* op1, struct nodeType*op2, char op);
struct nodeType* bitwise(struct nodeType* op1, struct nodeType*op2, char op);
struct nodeType* logical(struct nodeType* op1, struct nodeType*op2, char op);
struct nodeType* comparison(struct nodeType* op1, struct nodeType*op2, char* op);
struct nodeType* convertTo(struct nodeType* term, char *type);

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
        int isConst; // this is used to check if the expression is a constant, which helps in if statements with constant expressions
};
// type functions
struct nodeType* intNode();
struct nodeType* floatNode();
struct nodeType* boolNode();
struct nodeType* stringNode();
struct nodeType* enumNode();

// used to fill enum values
struct nodeType* enumVal;

void typeCheck(struct nodeType* type1, struct nodeType* type2);
void checkConstant(char name);
void checkInitialization(char name);
int checkDeclaration(char name);
void checkUsage();
void checkConstIf(struct nodeType* exp);
int isConstVar(char name);

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
%type <TYPE_VOID> codeBlock functionArgs functionParams  
// %type <TYPE_INT> exp
// %type <TYPE_INT> term
// %type <TYPE_INT> assignment
// %type <TYPE_DATA_TYPE> dataType declaration
%type <TYPE_DATA_MODIFIER> dataModifier

%type <TYPE_NODE> term exp assignment dataType declaration functionCall

//==============================================================================
// To solve some shift/reduce conflicts

%%

/* descriptions of expected inputs corresponding actions (in C) */
program                 : statements                            {;}
                        | functionDef                           {;}
                        | statements program                    {;}
                        | functionDef program                   {;}
                        ;
statements	            : statement ';'                         {;}
                        | '{'{enterScope();} codeBlock '}'{exitScope();}
                        | controlstatement                      {;}
                        | statements '{'{enterScope();} codeBlock '}'{exitScope();}          {;}
                        | statements statement ';'              {;}
                        | statements controlstatement           {;}
                        ;
codeBlock               :  statements                           {;}
                        ;
controlstatement        : {quadPushEndLabel(++endLabelNum);} ifCondition {quadPopEndLabel();}
                        | {quadPushStartLabel(++startLabelNum);} whileLoop {quadPopStartLabel();}
                        | forLoop {quadPopStartLabel();}
                        | {quadPushStartLabel(++startLabelNum);} repeatUntilLoop {quadPopStartLabel();}
                        | {quadPushEndLabel(++endLabelNum);} switchCaseLoop {quadPopEndLabel();}
                        ;      
                                                 
statement               : assignment 		                {;}
                        | exp                                   {;}
                        | declaration 		                {;}
                        | EXIT 		                        {exit(EXIT_SUCCESS);}
                        | BREAK 		                    {quadJumpEndLabel();}
                        | CONTINUE 		                    {;}
                        | RETURN 		                    {quadReturn();}
                        | RETURN exp 		                {quadReturn();}
                        | PRINT '(' IDENTIFIER ')' 		    {printNode(symbolVal($3)); setUsed($3);}
                        | PRINT '(' exp ')' 		        {printNode($3);}
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
                    
declaration             : dataType IDENTIFIER 		            {checkSameScope($2);
                                                                insert($2, $1->type, 0, 0, 0, scopes[scope_idx-1]);/*Check declared when inserting*/quadPopIdentifier($2);}
                        | dataType IDENTIFIER                   {checkSameScope($2);} '=' exp {typeCheck($1, $5); insert($2, $1->type, 0, 0, 0, scopes[scope_idx-1]); updateSymbolVal($2,$5); setInit($2); quadPopIdentifier($2);}
                        | dataModifier dataType IDENTIFIER      {checkSameScope($3);} '=' exp 
                                                                {typeCheck($2, $6); insert($3, $2->type, 1, 0, 0, scopes[scope_idx-1]); updateSymbolVal($3,$6); setInit($3); quadPopIdentifier($2);}
                        ;
assignment              : IDENTIFIER '=' exp                    {checkOutOfScope($1); checkConstant($1); 
                                                                typeCheck2($1, $3); setUsed($1); updateSymbolVal($1,$3); $$ = $3; setInit($1); quadPopIdentifier($1);}

                        | enumDef                               {;}             //
                        | dataType enumDeclaration              {/*Check declared*/;}
                        ;
exp    	                : term                                  {$$ = $1;}
                        | functionCall                          {$$->isConst=0;}
                        /* Conversion */
                        | '(' dataType ')' term                 {$$ = convertTo($4, $2->type); $$->isConst = $4->isConst;} // TODO add quad instruction
                        /* Negation */
                        | '-' term                              {quadInstruction("NEG"); if($2->type == "int"){$$ = intNode(); $$->value.intVal = -$2->value.intVal;} else if($2->type == "float"){$$ = floatNode(); $$->value.floatVal = -$2->value.floatVal;} else exit(EXIT_FAILURE);    $$->isConst=$2->isConst;}
                        | '~' term                              {quadInstruction("COMPLEMENT"); if($2->type == "int"){$$ = intNode(); $$->value.intVal = ~$2->value.intVal;} else exit(EXIT_FAILURE); $$->isConst=$2->isConst;}
                        | NOT term                              {quadInstruction("NOT"); if($2->type == "bool"){$$ = boolNode(); $$->value.boolVal = !$2->value.boolVal;} else{ if($2->value.intVal){$$ = boolNode(); $$->value.boolVal = 0;} else{$$ = boolNode(); $$->value.boolVal = 1;}} $$->isConst=$2->isConst;}
                        // /* Arithmatic */
                        | exp '+' exp                           {quadInstruction("ADD"); $$ = arithmatic($1,$3,'+'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp '-' exp                           {quadInstruction("SUB"); $$ = arithmatic($1,$3,'-'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp '*' exp                           {quadInstruction("MUL"); $$ = arithmatic($1,$3,'*'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp '/' exp                           {quadInstruction("DIV"); $$ = arithmatic($1,$3,'/'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp '%' exp                           {quadInstruction("MOD"); $$ = arithmatic($1,$3,'%'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        // /* Bitwise */
                        | exp '|' exp                           {quadInstruction("BITWISE_OR"); $$ = bitwise($1,$3,'|');  $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp '&' exp                           {quadInstruction("BITWISE_AND"); $$ = bitwise($1,$3,'&'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp '^' exp                           {quadInstruction("BITWISE_XOR"); $$ = bitwise($1,$3,'^'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp SHL exp                           {quadInstruction("SHL"); $$ = bitwise($1,$3,'<'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp SHR exp                           {quadInstruction("SHR"); $$ = bitwise($1,$3,'>'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        // /* Logical */
                        | exp OR exp                            {quadInstruction("LOGICAL_OR");  $$ = logical($1,$3,'|'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp AND exp                           {quadInstruction("LOGICAL_AND"); $$ = logical($1,$3,'&'); $$->isConst=(($1->isConst)&&($3->isConst));}
                        // /* Comparison */
                        | exp EQ exp                            {quadInstruction("EQ");  $$ = comparison($1,$3,"==");  $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp NEQ exp                           {quadInstruction("NEQ"); $$ = comparison($1,$3,"!=");  $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp GT exp                            {quadInstruction("GT");  $$ = comparison($1,$3,">");   $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp GEQ exp                           {quadInstruction("GEQ"); $$ = comparison($1,$3,">=");  $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp LT exp                            {quadInstruction("LT");  $$ = comparison($1,$3,"<");   $$->isConst=(($1->isConst)&&($3->isConst));}
                        | exp LEQ exp                           {quadInstruction("LEQ"); $$ = comparison($1,$3,"<=");  $$->isConst=(($1->isConst)&&($3->isConst));}
                        ;
term   	                : NUMBER                                {quadPushInt($1); $$ = intNode(); $$->value.intVal = $1; $$->isConst=1;  /*Pass value & type*/}
                        | FLOAT_NUMBER                          {quadPushFloat($1); $$ = floatNode(); $$->value.floatVal = $1; $$->isConst=1; /*Pass value & type*/}
                        | TRUE_VAL                              {quadPushInt(1); $$ = boolNode();  $$->value.boolVal = 1; $$->isConst=1; /*Pass value & type*/}
                        | FALSE_VAL                             {quadPushInt(0); $$ = boolNode();  $$->value.boolVal = 0; $$->isConst=1; /*Pass value & type*/}
                        | IDENTIFIER	                        {quadPushIdentifier($1); checkOutOfScope($1); checkInitialization($1); $$ = symbolVal($1); $$->isConst=isConstVar($1); setUsed($1);/*Decl, Initialize checks*/ /*Set Used*/ /*Rev. symbolVal*/ /*Pass value & type*/} 
                        | STRING                                {quadPushString($1); $$ = stringNode(); $$->value.stringVal = strdup($1); $$->isConst=1; /*Pass value & type*/}
                        | '(' exp ')'                           {$$ = $2;}
                        ;
//======================
/* Conditions */
//======================
ifCondition             : IF '(' exp {checkConstIf($3); quadJumpFalseLabel(++labelNum);} ')' '{'{enterScope();} codeBlock '}'{quadJumpEndLabel(); exitScope(); quadPopLabel();} ElseCondition {;}
                        ;
ElseCondition           : {;}
                        | ELSE {;} ifCondition {;}
                        | ELSE {;}'{'{enterScope();} codeBlock '}'{exitScope();} {;}
                        ;
case                    : CASE exp {quadPeakLastIdentifierStack(); quadJumpFalseLabel(++labelNum);} ':' statements {quadPopLabel();}
                        | DEFAULT ':' statements                {;}
                        ;
caseList                : caseList case
                        | case
                        ;
switchCaseLoop          : SWITCH '(' IDENTIFIER ')' {quadPushLastIdentifierStack($3);setInit($3);} '{'{enterScope();} caseList '}'{exitScope();}   {quadPopLastIdentifierStack();}
                        ;
//======================
/* Loops */
//======================
whileLoop               : WHILE '(' exp ')' {quadJumpFalseLabel(++labelNum);} '{'{enterScope();} codeBlock '}'{/*end*/ exitScope(); quadJumpStartLabel(); quadPopLabel();}    {;}
                        ;
forLoop                 : FOR '(' assignment ';' {quadPushStartLabel(++startLabelNum);} exp ';' {quadJumpFalseLabel(++labelNum);} assignment ')' '{'{enterScope();} codeBlock '}'{exitScope(); quadJumpStartLabel(); quadPopLabel();} {;}
                        ;
repeatUntilLoop         : REPEAT '{'{enterScope();} codeBlock '}'{exitScope();} UNTIL '(' exp ')' ';' {quadJumpFalseLabel(++labelNum); quadJumpStartLabel(); quadPopLabel();}
                        ;

//======================
/* Functions */
//======================                        
functionArgs            : dataType IDENTIFIER                   {quadPopIdentifier($2);}
                        | dataType IDENTIFIER ',' functionArgs  {quadPopIdentifier($2);}
                        ;
functionParams          : term                                  {}
                        | term ',' functionParams               {}
                        ;
functionDef             : dataType IDENTIFIER {quadStartFunction($2);} functionDefRest {checkSameScope($2); insert($2, $1->type, 0, 0, 0, scopes[scope_idx-1]);} 
                                                            '{'{enterScope();} codeBlock '}' {exitScope(); quadEndFunction($2);}
                        ;
functionDefRest            : '(' functionArgs ')' 
                        | '('              ')' 
                        ;
functionCall            : IDENTIFIER functionCallRest     {checkOutOfScope($1); $$ = symbolVal($1); quadCallFunction($1);}
                        ;
functionCallRest        : '(' functionParams ')'             {;}
                        | '('              ')'               {;}
                        ;
//======================
/* Enumerations */
//======================
enumDef	                : ENUM IDENTIFIER {checkSameScope($2); insert($2, "enum", 1, 1, 0, scopes[scope_idx-1]);} '{' enumBody '}'
                        ;
enumBody		        : IDENTIFIER                            {checkSameScope($1); insert($1, "int", 1, 1, 0, scopes[scope_idx-1]); enumVal->value.intVal = 0; updateSymbolVal($1, enumVal);}
                        | IDENTIFIER '=' exp                    {checkSameScope($1); typeCheck(enumVal, $3); insert($1, "int", 1, 1, 0, scopes[scope_idx-1]); enumVal->value.intVal = $3->value.intVal; updateSymbolVal($1, enumVal);}
                        | enumBody ',' IDENTIFIER               {checkSameScope($3); insert($3, "int", 1, 1, 0, scopes[scope_idx-1]); enumVal->value.intVal++; updateSymbolVal($3, enumVal);}
                        | enumBody ',' IDENTIFIER '=' exp       {checkSameScope($3); typeCheck(enumVal, $5); insert($3, "int", 1, 1, 0, scopes[scope_idx-1]); enumVal->value.intVal = $5->value.intVal; updateSymbolVal($3, enumVal);}
                        ;
enumDeclaration         : IDENTIFIER IDENTIFIER                 {checkOutOfScope($1); typeCheck2($1,enumNode()); checkSameScope($2); insert($2, "int", 0, 0, 0, scopes[scope_idx-1]);}
                        | IDENTIFIER IDENTIFIER '=' exp         {checkOutOfScope($1); typeCheck2($1,enumNode()); checkSameScope($2); insert($2, "int", 0, 1, 0, scopes[scope_idx-1]); typeCheck($4,intNode()); updateSymbolVal($2,$4);}
                        ;

//======================
/* Other */
//======================

%%  
//======================
/* Quadruples */
//======================  
void quadStartFunction(char function) // TODO: make it string isnetad of char
{
        if (SHOW_Quads) {
                printf("Quads(%d) \tPROC %c\n", line, function);
        }
}
void quadEndFunction(char function)
{
        if (SHOW_Quads) {
                printf("Quads(%d) \tEND PROC %c\n", line, function);
        }
}
void quadCallFunction(char function)
{
        if (SHOW_Quads) {
                printf("Quads(%d) \tCALL function %c\n", line, function);
        }
}
void quadReturn()
{
        if (SHOW_Quads) {
                printf("Quads(%d) \tRET\n", line);
        }
}
void quadInstruction(const char* instruction)
{
        if (SHOW_Quads) {
               
                printf("Quads(%d) \t%s\n", line, instruction);
        }
}
void quadPushInt(int val)
{
       if (SHOW_Quads) {
               printf("Quads(%d) \tPUSH %d\n", line, val);
       }
}
void quadPushFloat(float val)
{
       if (SHOW_Quads) {
               printf("Quads(%d) \tPUSH %f\n", line, val);
       }
}
void quadPushIdentifier(char symbol)
{
       if (SHOW_Quads) {
               printf("Quads(%d) \tPUSH %c\n", line, symbol);
       }
}
void quadPushString(char* str)
{
       if (SHOW_Quads) {
               printf("Quads(%d) \tPUSH %s\n", line, str);
       }
}
void quadPopIdentifier(char symbol)
{
       if (SHOW_Quads) {
            printf("Quads(%d) \tPOP %c\n\n", line, symbol);
       }
}
void quadPushEndLabel(int endLabelNum)
{
       if (SHOW_Quads) {
            /* push the labelNum to the stack */
            endLabelStack[++endLabelstackPointer] = endLabelNum;
       }
}
void quadJumpEndLabel() // jump to the first end label in the stack
{
      if (SHOW_Quads) {
        /* get last  endLabelNum from the stack*/
        int endLabelNum = endLabelStack[endLabelstackPointer];
        printf("Quads(%d) \tJMP EndLabel_%d\n", line, endLabelNum);
       }
}
void quadPopEndLabel(){
        if (endLabelstackPointer < 0){
            printf("Quads(%d) Error: No end label to add. Segmenration Fault\n", line);
            return;
        }
        /* get the last endLabelNum from the stack */
        int endLabelNum = endLabelStack[endLabelstackPointer--];
        if (SHOW_Quads) {
                printf("Quads(%d) EndLabel_%d:\n", line, endLabelNum);
        }
}
void quadJumpFalseLabel(int labelNum)
{
       if (SHOW_Quads) {
               printf("Quads(%d) \tJF Label_%d\n", line, labelNum);
               /* push the labelNum to the stack */
                labelStack[labelStackPointer++] = labelNum;
       }
}
void quadPopLabel(){
        if (labelStackPointer < 0){
            printf("Quads(%d) Error: No end label to add. Segmenration Fault\n", line);
            return;
        }
        /* get the last labelNum from the stack */
        int labelNum = labelStack[--labelStackPointer];
        if (SHOW_Quads) {
                printf("Quads(%d) Label_%d:\n",line, labelNum);
        }
}
void quadPushLastIdentifierStack(char identifier){
        if (SHOW_Quads) {
            /* add the IDENTIFIER to the stack */
            lastIdentifierStack[++lastIdentifierStackPointer] = identifier;
        }
}
void quadPeakLastIdentifierStack(){
    if (lastIdentifierStackPointer < 0){
        printf("Quads(%d) Error: No last identifier to peak. Segmenration Fault\n", line);
        return;
    }
    /* get the last identifier from the stack */
    char identifier = lastIdentifierStack[lastIdentifierStackPointer];
    if (SHOW_Quads) {
            printf("Quads(%d) \tPUSH %c\n", line, identifier);
    }
}
void quadPopLastIdentifierStack(){
    if (lastIdentifierStackPointer < 0){
        printf("Quads(%d) Error: No last identifier to pop. Segmenration Fault\n", line);
        return;
    }
    /* get the last IDENTIFIER from the stack */
    char identifier = lastIdentifierStack[lastIdentifierStackPointer--];
}


void quadPushStartLabel(int startLabelNum){
        if (SHOW_Quads) {
            /* push the labelNum to the stack */
            startLabelStack[++startLabelstackPointer] = startLabelNum;
            if (SHOW_Quads) {
                printf("Quads(%d) StartLabel_%d:\n", line, startLabelNum);
            }
        }
}
void quadJumpStartLabel(){
        if (SHOW_Quads) {
        /* get last  startLabelNum from the stack*/
        int startLabelNum = startLabelStack[startLabelstackPointer];
        printf("Quads(%d) \tJMP StartLabel_%d\n", line, startLabelNum);
       }
}
void quadPopStartLabel(){
    if (startLabelstackPointer < 0){
            printf("Quads(%d) Error: No start label to add. Segmenration Fault\n", line);
            return;
        }
    /* get the last endLabelNum from the stack */
    int startLabelNum = startLabelStack[startLabelstackPointer--];
}
//======================
// Symbol table functions
//======================
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

void printNode(struct nodeType* x)
{
    if(strcmp(x->type, "int") == 0)
        printf("%d\n", x->value.intVal);
    else if(strcmp(x->type, "float") == 0)
        printf("%f\n", x->value.floatVal);
    else if(strcmp(x->type, "bool") == 0)
        printf("%d\n", x->value.boolVal);
    else if(strcmp(x->type, "string") == 0)
        printf("%s\n", x->value.stringVal);
}

void printSymbolTable(){

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
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
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
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
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
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
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
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
        }
    }
    else{
        /* printf("Type Error\n"); */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
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
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
        }
    }
    else{
        /* printf("Type Error\n"); */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
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
                Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
        }
    }
    else{
        /* printf("Type Error\n"); /// ISSUE HERE
        printf("%s\n", op1->type);
        printf("%s\n", op2->type); */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type); // TODO
    }
    return p;
}

struct nodeType* comparison(struct nodeType* op1, struct nodeType*op2, char* op){
    struct nodeType* p = malloc(sizeof(struct nodeType));
    p->type = "bool";
    if(strcmp(op1->type, op2->type) != 0)
    {
        /* printf("Type mismatch\n"); */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type); // TODO
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
            Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
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
            Log_SEMANTIC_ERROR(TYPE_MISMATCH, op2->type);
        }
    }
    return p;
}

struct nodeType* convertTo(struct nodeType* term, char *type){

    struct nodeType* p = malloc(sizeof(struct nodeType));


    if(strcmp(type, "int") == 0){   // convert to int
        p->type = "int";
        if(strcmp(term->type, "float") == 0){
            p->value.intVal = (int)term->value.floatVal;
        }
        else if(strcmp(term->type, "bool") == 0){
            p->value.intVal = (int)term->value.boolVal;
        }
        else if(strcmp(term->type, "string") == 0){
            // remove double quotes from start and end of string
            char *str = strdup(term->value.stringVal);
            str++;
            str[strlen(str)-1] = '\0';
            p->value.intVal = atoi(str);
        }
        else{
            /* printf("Invalid type\n"); */
            Log_SEMANTIC_ERROR(TYPE_MISMATCH, term->type);
        }
    }
    else if(strcmp(type, "float") == 0){  // convert to float
        p->type = "float";
        if(strcmp(term->type, "int") == 0){
            p->value.floatVal = (float)term->value.intVal;
        }
        else if(strcmp(term->type, "bool") == 0){
            p->value.floatVal = (float)term->value.boolVal;
        }
        else if(strcmp(term->type, "string") == 0){
            // remove double quotes from start and end of string
            char *str = strdup(term->value.stringVal);
            str++;
            str[strlen(str)-1] = '\0';
            p->value.floatVal = atof(str);
        }
        else{
            Log_SEMANTIC_ERROR(TYPE_MISMATCH, term->type);
        }
    }
    else if(strcmp(type, "bool") == 0){  // convert to bool
        p->type = "bool";
        if(strcmp(term->type, "int") == 0){
            p->value.boolVal = (int)term->value.intVal!=0;
        }
        else if(strcmp(term->type, "float") == 0){
            p->value.boolVal = (int)term->value.floatVal!=0;
        }
        else if(strcmp(term->type, "string") == 0){
            // remove double quotes from start and end of string
            char *str = strdup(term->value.stringVal);
            str++;
            str[strlen(str)-1] = '\0';
            p->value.boolVal = str[0] != '\0';
        }
        else{
            Log_SEMANTIC_ERROR(TYPE_MISMATCH, term->type);
        }
    }
    else if(strcmp(type, "string") == 0){ // convert to string
        p->type = "string";
        if(strcmp(term->type, "int") == 0){
            char t[100];
            sprintf(t, "%d", term->value.intVal);
            p->value.stringVal = strdup(t);
        }
        else if(strcmp(term->type, "float") == 0){
            char t[100];
            sprintf(t, "%f", term->value.floatVal);
            p->value.stringVal = strdup(t);
        }
        else if(strcmp(term->type, "bool") == 0){
            char t[100];
            sprintf(t, "%d", term->value.boolVal);
            p->value.stringVal = strdup(t);
        }
        else{
            Log_SEMANTIC_ERROR(TYPE_MISMATCH, term->type);
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

struct nodeType* enumNode() {
    struct nodeType* p = malloc(sizeof(struct nodeType));;
    p->type = "enum";
    p->value.intVal = 0;
    return p;
}

void typeCheck(struct nodeType* type1, struct nodeType* type2) {
    if(strcmp(type1->type, type2->type) != 0) {
        /* printf("Type Error\n"); //To-Do: */
        Log_SEMANTIC_ERROR(TYPE_MISMATCH, type2->type); // TODO
    }
    return;
}

void typeCheck2(char symbol, struct nodeType* type2) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == symbol) {
            for(int j=scope_idx-1;j>=0;j--) {
                if(symbol_Table[i].scope == scopes[j]) {
                    if(strcmp(symbol_Table[i].type, type2->type) != 0) {
                        Log_SEMANTIC_ERROR(TYPE_MISMATCH, symbol_Table[i].name);
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
                Log_SEMANTIC_ERROR(REDECLARED, name);
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
    Log_SEMANTIC_ERROR(OUT_OF_SCOPE, name);

}
// this function checks if a variable is initialized before use
void checkInitialization(char name) {
    for(int i=sym_table_idx-1;i>=0;i--) {
        
        if(symbol_Table[i].name == name) {
            if(symbol_Table[i].isInit == 0) {
                /* printf("Variable %c not initialized\n", name); */
                Log_SEMANTIC_ERROR(UNINITIALIZED, name);
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
            Log_SEMANTIC_ERROR(UNUSED, symbol_Table[i].name);
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
                        Log_SEMANTIC_ERROR(CONSTANT, name);
                        
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

void checkConstIf(struct nodeType* exp)
{
    if(exp->isConst == 1){
        Log_SEMANTIC_ERROR(CONSTANT_IF, exp->value.boolVal != 0);
    }
}

int isConstVar(char name){
    for(int i=sym_table_idx-1;i>=0;i--) {
        if(symbol_Table[i].name == name) {
            for(int j=scope_idx-1;j>=0;j--) {
                if(symbol_Table[i].scope == scopes[j]) {
                    if(symbol_Table[i].isConst == 1) {
                        return 1;
                    }
                    else{
                        return 0;
                    }
                }
            }
        }
    }
    return 0;
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
    
        enumVal = intNode();
        
        yyparse ( );  
        checkUsage();
        printSymbolTable();

    return 0;
}


/* void yyerror (char *s) {printf ("%s at line %d\n", s, line-1);}  */
void yyerror(char* s) {
    printf("Syntax error (%d) Near line %d.\n", line, line);
    fprintf(stderr, "Syntax error (%d) Near line %d.\n", line, line);
    printSymbolTable();
    exit(EXIT_FAILURE);
}