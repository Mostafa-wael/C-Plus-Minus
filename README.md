## Project Overview

The designed language is a `C` like programming language.

Sample program:

`print("declaration");`
`const int a = -5;`
`print (a);`
`print (-a);`

`float b = 5.5;`
`print (b);`

`bool c = 1;`
`print(c); // 1`

`string d = "hello";`

`void e = 0;`

`print(d); // hello2`

`{`
`    const int a = 10;`
`    print(a);`
`}`
`exit;`

## Steps
- `yacc -d main.y`: create y.tab.h and y.tab.c
- `lex main.l`: create lex.yy.c
- `gcc -g lex.yy.c y.tab.c -o main`: create main
- `./main`: run main


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
   <li>term → </li>
   <br>
   <li>dataIdentifier → </li>
   <br>
   <li>dataType → </li>
   <br>
   <li>ifCondition → </li>
   <br>
   <li>whileLoop → </li>
   <br>
   <li>forLoop → </li>
   <br>
   <li>repeatUntilLoop → </li>
   <br>
   <li>case → </li>
   <br>
   <li>caseList → </li>
   <br>
   <li>switchCaseLoop → </li>
   <br>
   <li>functionArgs → </li>
   <br>
   <li>functionParams → </li>
   <br>
   <li>functionDef → </li>
   <br>
   <li>functionCall → IDENTIFIER ( functionParams ) | IDENTIFIER ( )</li>
   <br>
   <li>enumDef → ENUM IDENTIFIER { enumBody }</li>
   <br>
   <li>enumBody → IDENTIFIER | IDENTIFIER = exp | enumBody , IDENTIFIER | enumBody , IDENTIFIER = exp</li>
   <br>
   <li>enumDeclaration → IDENTIFIER IDENTIFIER | IDENTIFIER IDENTIFIER = exp</li>
</ul>