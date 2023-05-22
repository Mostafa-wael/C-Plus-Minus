# TODOs

## Phase 2

- [ ] Design a suitable and extensible format for the symbol table.
- [ ] Implement a proper syntax error handler.
- [ ] Design suitable action rules to produce the output quadruples.
- [ ] Build a simple semantic analyzer to check for the following:
  - [ ] Variable declaration conflicts. i.e. multiple declarations of the same variable.
  - [ ] Improper usage of variables regarding their type.
  - [ ] Variables used before being initialized and unused variables.
  - [ ] The addition of type conversion quadruples to match operators’ semantic requirements, i.e. converting integer to real, …
  - [ ] Warning in case of if statement whose condition is always false.

## Bonus

- [ ] Level 1 (input/output fields):
  - [ ] Should have input and output fields with the “Compile” button.
  - [ ] User inputs the code in the input field (better be a code editor field e.g. supports line numbering) and sees the output quadruples in the output field.
  - [ ] Should also print the error/warning if any.
  - [ ] Should show the final symbol table.
- [ ] Level 2 (Highlight the line with an error):
  - [ ] Should highlight the line with error (if any) in the “user input” field after compilation.
- [ ] Level 3 (Print the Symbol table step-by-step):
  - [ ] Should execute the input step-by-step.
  - [ ] Should have a button to step to the next line
  - [ ] Should show the symbol table as part of the UI
  - [ ] Should update the symbol table every step if changed

## Work Distribution

- [ ] Design & implement AST. [Yousif Atef] -> 5/5
- [ ] Design a suitable and extensible format for the symbol table [MW, Zoz] -> 5/5
- [ ] Design suitable action rules to produce the output quadruples [Gendy] -> 5/5

-------
Continue other types
Checks (decleration, intialization, use, consts)
Scopes
Arithematic op
default nums?!!

proper output of errors
add lines to the errors
handle enums errors
Fix the if else weird error
rename out of scope error from variable to function
check type parameters in function call (need new datastructure)
handle function, enum, swith, for,
conversions
if always True or False
line of each error

## Quad

- If-then-else statement, while loops, repeat-until loops, for loops, switch statement.   (nested)
- functions, enums
- show quad line number

## Errors

- check todos in code
- enums (and the inside of enums to symbol table).
- The addition of type conversion quadruples to match operators’semantic requirements, i.e. converting integer to real, ...
- Warning in case of if statement whose condition is always false.
- strings
- function parameters
- fix types inside symbol table

## GUI

- Test cases.
- line by line

Done:
[x] functions without parameters -> change functionCall to Node_type & $$ = val($1)
