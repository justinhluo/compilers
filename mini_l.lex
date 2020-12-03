%{
	#include "y.tab.h"
	int currRow = 1;
	int currPos = 0;

%}

	/* definitions */

DIGIT [0-9]
LETTER [a-zA-Z]
CHAR [0-9a-zA-Z_]
NUMLETTER [0-9a-zA-Z]
WHITESPACE [\t]
NEWLINE [\n]
SPACE [ ]
NOTLETTER [0-9_]
%%

	/* 28 reserved words */

function {return(FUNCTION); currPos += yyleng;}
beginparams {return(BEGIN_PARAMS); currPos += yyleng;} 
endparams {return(END_PARAMS); currPos += yyleng;}
beginlocals {return(BEGIN_LOCALS); currPos += yyleng;}
endlocals {return(END_LOCALS); currPos += yyleng;}
beginbody {return(BEGIN_BODY); currPos += yyleng;}
endbody {return(END_BODY); currPos += yyleng;}
integer {return(INTEGER); currPos += yyleng;}
array {return(ARRAY); currPos += yyleng;}
of {return(OF); currPos += yyleng;}
if {return(IF); currPos += yyleng;}
then {return(THEN); currPos += yyleng;}
endif {return(ENDIF); currPos += yyleng;}
else {return(ELSE); currPos += yyleng;}
while {return(WHILE); currPos += yyleng;}
do {return(DO); currPos += yyleng;}
for {return(FOR); currPos += yyleng;}
beginloop {return(BEGINLOOP); currPos += yyleng;}
endloop {return(ENDLOOP); currPos += yyleng;}
continue {return(CONTINUE); currPos += yyleng;}
read {return(READ); currPos += yyleng;}
write {return(WRITE); currPos += yyleng;}
and {return(AND); currPos += yyleng;}
or {return(OR); currPos += yyleng;}
not {return(NOT); currPos += yyleng;}
true {return(TRUE); currPos += yyleng;}
false {return(FALSE); currPos += yyleng;}
return {return(RETURN); currPos += yyleng;}

	/* 5 arithmetic operators */


"-" {return(SUB); currPos += 1;}
"+" {return(ADD); currPos += 1;}
"*" {return(MULT); currPos += 1;}
"/" {return(DIV); currPos += 1;}
"%" {return(MOD); currPos += 1;}

	/* 6 comparison operators */


"==" {return(EQ); currPos += 2;}
"<>" {return(NEQ); currPos += 2;}
"<" {return(LT); currPos += 1;}
">" {return(GT); currPos += 1;}
"<=" {return(LTE); currPos += 2;}
">=" {return(GTE); currPos += 2;}

	/*Identifiers and Numbers*/

{LETTER}{CHAR}*{NUMLETTER} {yylval.ident = yytext; return(IDENT); currPos += yyleng;}
{LETTER}{NUMLETTER}* {yylval.ident = yytext; return(IDENT); currPos += yyleng;}
{DIGIT}+ {yylval.num = atoi(yytext); return(NUMBER); currPos += yyleng;}

	/* 8 Other special symbols */

";" {return(SEMICOLON); currPos += 1;}
":" {return(COLON); currPos += 1;}
"," {return(COMMA); currPos += 1;}
"(" {return(L_PAREN); currPos += 1;}
")" {return(R_PAREN); currPos += 1;}
"[" {return(L_SQUARE_BRACKET); currPos += 1;}
"]" {return(R_SQUARE_BRACKET); currPos += 1;}
":=" {return(ASSIGN); currPos += 2;}
 
	/* whitepace/newline */
{WHITESPACE}+ {currPos += yyleng;}
{NEWLINE}+ {currRow += yyleng; currPos = 0;}
{SPACE}+ {currPos += yyleng;}

	/* comments */
"##".*{NEWLINE} {currRow++; currPos = 0;}
   
	/* errors */
{LETTER}{CHAR}*"_" {printf("Error on line %d: identifier %s cannot end with an underscore \n", currRow, yytext); exit(1);}
{NOTLETTER}{CHAR}* {printf("Error on line %d: identifier %s must begin with a letter \n", currRow, yytext); exit(1);}
. {printf("Error on line %d: unrecognized symbol %s \n", currRow, yytext); exit(1);}

%%

int main(int argc, char* argv[]) {
  if (argc == 2) {
    yyin = fopen(argv[1], "r");
  }
  else {
    yyin = stdin;
  }
  yyparse();
}

