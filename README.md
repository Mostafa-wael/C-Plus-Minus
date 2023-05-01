# Compilers Project

## Table of Contents
- [Compilers Project](#compilers-project)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Run Steps](#run-steps)
  - [Tools and Technologies](#tools-and-technologies)
  - [Tokens](#tokens)
  - [Syntax](#syntax)
    - [Data Types](#data-types)
    - [Operators](#operators)
    - [Conditional Statements](#conditional-statements)
    - [Loops](#loops)
    - [Functions](#functions)
    - [Enumerations](#enumerations)
  - [Production Rules](#production-rules)

## Introduction

The designed language is a `C` like programming language.

Sample program:

```c
const int a = 5;
float b = 6;
print ("Operations:");
if (a == 5) {
    print ("a is 5");
}
else {
    if (b == 6) {
        print ("b is 6");
    }
    else {
        print ("b is not 6");
    }
}
exit;
```

## Run Steps
- `yacc -d main.y`: create y.tab.h and y.tab.c
- `lex main.l`: create lex.yy.c
- `gcc -g lex.yy.c y.tab.c -o main`: create main
- `./main`: run main

For convenience, the above steps are combined in a makefile. To run the makefile, type `make <test case name>` in the terminal.


## Tools and Technologies
<ol>
   <li>Lex: It breaks down the input text into a sequence of tokens, which are then passed on to the parser for further processing.</li>
   <li>Yacc: It takes a sequence of tokens as input and produces a parse tree or an abstract syntax tree (AST) that represents the structure of the input according to the grammar rules.</li>
</ol>

## Tokens
<table>
   <tr>
      <th align="left">Token</th>
      <th align="left">Regex</th>
      <th align="left">Description</th>
   </tr>
   <tr>
      <td>DIGIT</td>
      <td>[0-9]</td>
      <td>Number between 0 and 9.</td>
   </tr>
   <tr>
      <td>ALPHABET</td>
      <td>[a-zA-Z]</td>
      <td>Upper case or lower case English letter.</td>
   </tr>
   <tr>
      <td>ALPHANUM</td>
      <td>[0-9a-zA-Z]</td>
      <td>Digit, upper case letter, or lower case letter.</td>
   </tr>
   <tr>
      <td>SPACE</td>
      <td>[ \r\t]</td>
      <td>Single space or tab.</td>
   </tr>
   <tr>
      <td>NEW_LINE</td>
      <td>\n</td>
      <td>New line.</td>
   </tr>
   <tr>
      <td>INLINE_COMMENT</td>
      <td>\/\/.*</td>
      <td>Single line comment.</td>
   </tr>
   <tr>
      <td>MULTILINE_COMMENT</td>
      <td>\/\*.*\*\/</td>
      <td>Multi-line comment.</td>
   </tr>
   <tr>
      <td>arithmeticOps</td>
      <td>[/+*%-]</td>
      <td>Arithmetic operators (+, -, *, /, %).</td>
   </tr>
   <tr>
      <td>bitwiseOps</td>
      <td>[&^~|]</td>
      <td>Bit-wise operators (AND, OR, NOT, XOR).</td>
   </tr>
   <tr>
      <td>endOfStatement</td>
      <td>[;]</td>
      <td>Semi-colon to mark the end of any statement.</td>
   </tr>
   <tr>
      <td>punctuators</td>
      <td>[()={}:,]</td>
      <td></td>
   </tr>
   <tr>
      <td>TRUE</td>
      <td>[tT]rue | 1 | [yY]es</td>
      <td></td>
   </tr>
   <tr>
      <td>FALSE</td>
      <td>[fF]alse| 0 | [nN]o</td>
      <td></td>
   </tr>
</table>

## Syntax
### Data Types
Tha language supports the following data types:
- Integer
- Float
- Boolean
- String

It supports modifiers like `const` as well.
```c
const int a = 10;
int b = 20;
float c = 10.5;
bool d = true;
string e = "Hello World";
```

### Operators
The language supports the common operators in C.
```c
// Arithmetic operators
a = b + c;
a = b - c;
a = b * c;
a = b / c;
a = b % c;
// Bitwise operators
a = b & c;
a = b | c;
a = b ^ c;
a = ~b;
// Logical operators
a = b && c;
a = b || c;
a = !b;
// Relational operators
a = b == c;
a = b != c;
a = b > c;
a = b >= c;
a = b < c;
a = b <= c;
// Shift operators
a = b << c;
a = b >> c;
```
### Conditional Statements
The language supports the if-else, if-elif-else, and switch-case statements.
```c
int a = 10;
// if statement
if (a == 10) {
    print("if");
    print("another if");
}
elif (a == 11) {
    print("elif");
    print("another elif");
}
else {
    print("else");
    print("another else");
    if (a == 10) {
        print("if");
        print("another if");
    }
    else {
        print("else");
        print("another else");
    }
}
if (a == 10) {
    print("if");
    print("another if");
}
elif(a == 11) {
    print("else");
    print("another else");
}
// switch-case statement
switch (a) {
    default:
        print("default");
        break;
}
switch (a) {
    case 1: 
        print("1");
        break;
    
    case 2: 
        print("2");
        break;
    
    case 3: 
        print("3");
        break;
}

switch (a) {
    case 1: 
        print("1");
        break;
    
    case 2: 
        print("2");
        break;
    
    case 3: 
        print("3");
        break;
    
    default: 
        print("default");
        break;
}
```
### Loops
The language supports the while, for, and repeat-until loops.
```c
// while loop
a = 0;
while (a < 20) {
    print(a);
    a = a + 1;
}
print(a);
while (a < 20) {
    if (a == 10) {
        print(a);
    }
    a = a + 1;
}
// for loop
for (a=2 ; a<10; a = a+1 ) {
    print(a);
}
for (a=2 ; a<10; a= a+1 ) {
    print(a);
    b = a;
    while (b < 10) {
        if (b == 5) {
            print("hi");
            print(b);
        }
        
        b = b + 1;
    }
}
// repeat-until loop
a = 0;
repeat {
    print(a);
    a = a + 1;
    print(a);
} until (a == 1);
repeat {
    print(a);
    a = a + 1;
    if (a == 1) {
        print(a);
    }
} until (a == 1);
```
### Functions
The language supports functions with and without parameters.
```c
int y (){
    print("y");
    return 1;
}
int x(int a, int b) {
    print("add");
    return a + b;
}
x(1, 2); // function call
a = y(); // function call and assignment
```
N.B.: you can't define a function inside any scope.

### Enumerations
The language supports enumerations.
```c
enum Color{
    RED=10,
    GREEN,
    BLUE=12,
    RED
};
{
    Color c1;
    Color c2=RED;
    Color c3=3+5;
}
```
## Production Rules
<ul>
   <li>program → statements | functionDef | statements program | functionDef program</li>
   <br>
   <li>statements → statement | codeBlock | controlstatement | statements codeBlock | statements statement | statements controlstatement</li>
   <br>
   <li>codeBlock → { statements } | { }</li>
   <br>
   <li>controlstatement → ifCondition | whileLoop | forLoop | repeatUntilLoop | switchCaseLoop</li>
   <br>
   <li>statement → assignment | exp | declaration | EXIT | BREAK | CONTINUE | RETURN | RETURN exp | PRINT ( exp ) | PRINT ( STRING )</li>
   <br>
   <li>declaration → dataType IDENTIFIER | dataType assignment | dataIdentifier declaration</li>
   <br>
   <li>assignment → IDENTIFIER = exp | IDENTIFIER = STRING | enumDeclaration | enumDef</li>
   <br>
   <li>exp → term | functionCall | - term | '~' term | NOT term | exp '+' exp | exp '-' exp | exp '*' exp | exp '/' exp | exp '%' exp | exp '|' exp | exp '&' exp | exp '^' exp | exp SHL exp | exp SHR exp | exp EQ exp | exp NEQ exp | exp GT exp | exp GEQ exp | exp LT exp | exp LEQ exp | exp AND exp | exp OR exp </li>
   <br>
   <li>term → NUMBER | FLOAT_NUMBER | TRUE_VAL | FALSE_VAL |IDENTIFIER | ( exp )</li>
   <br>
   <li>dataIdentifier → CONST</li>
   <br>
   <li>dataType → INT_DATA_TYPE | FLOAT_DATA_TYPE | STRING_DATA_TYPE | BOOL_DATA_TYPE | VOID_DATA_TYPE</li>
   <br>
   <li>ifCondition → IF ( exp ) codeBlock | IF ( exp ) codeBlock ELSE codeBlock | IF ( exp ) codeBlock ELIF ( exp ) codeBlock | IF ( exp ) codeBlock ELIF ( exp ) codeBlock ELSE codeBlock</li>
   <br>
   <li>whileLoop → WHILE ( exp ) codeBlock</li>
   <br>
   <li>forLoop → FOR ( assignment ; exp ; assignment ) codeBlock</li>
   <br>
   <li>repeatUntilLoop → REPEAT codeBlock UNTIL ( exp ) ;</li>
   <br>
   <li>case → CASE exp : statements | DEFAULT : statements</li>
   <br>
   <li>caseList → caseList case | case</li>
   <br>
   <li>switchCaseLoop → SWITCH ( exp ) { caseList }</li>
   <br>
   <li>functionArgs → dataType IDENTIFIER | dataType IDENTIFIER , functionArgs</li>
   <br>
   <li>functionParams → term | term , functionParams</li>
   <br>
   <li>functionDef → dataType IDENTIFIER ( functionArgs ) codeBlock | dataType IDENTIFIER '(' ')' codeBlock</li>
   <br>
   <li>functionCall → IDENTIFIER ( functionParams ) | IDENTIFIER ( )</li>
   <br>
   <li>enumDef → ENUM IDENTIFIER { enumBody }</li>
   <br>
   <li>enumBody → IDENTIFIER | IDENTIFIER = exp | enumBody , IDENTIFIER | enumBody , IDENTIFIER = exp</li>
   <br>
   <li>enumDeclaration → IDENTIFIER IDENTIFIER | IDENTIFIER IDENTIFIER = exp</li>
</ul>
