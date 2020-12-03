%{
using namespace std;
#include <vector>
#include <string>
#include <boost/algorithm/string.hpp>
#include <iostream>
#include <stdio.h>
#include <fstream>
#include <stdlib.h>
#include <algorithm>
#include <queue>
int yylex();
int yyerror(const char* msg);
vector <int> array_size;
vector <string> statements;
vector <string> variables;
vector <string> expressions;
//queue <string> expressions;
vector<string> params;
ofstream file;
vector <string> printparams;
string temp, temp2, temp3, temp4, temp5, label1, label2, label3;
vector <string> functions;
int varcount = -1;
string edit(string to_edit);
int labelcount = -3;
int is_right_arr = -999;
extern int currPos, currRow;
string funcname;
string tmp;
int paramval = 0;
bool in_loop = false;
bool is_params = false;
vector <string> keywords = {"function",	"FUNCTION",
"beginparams", "BEGIN_PARAMS","endparams","END_PARAMS","beginlocals","BEGIN_LOCALS","endlocals","END_LOCALS"
,"beginbody", "BEGIN_BODY","endbody" ,"END_BODY","integer", "INTEGER","array","ARRAY","of", "OF","if","IF"
"then", "THEN","endif","ENDIF","else",	"ELSE","while","WHILE","do","DO","for","FOR","beginloop","BEGINLOOP"
,"endloop", "ENDLOOP", "continue","CONTINUE","read"	, "READ","write", "WRITE","and", "AND","or", "OR","not"	,"NOT"
,"true","TRUE","false", "FALSE","return", "RETURN","SUB", "ADD", "MULT", "DIV", "MOD", "EQ", "NEQ" , "LTE", "GTE" , "LT", "GT",
"IDENT", "NUMBER", "SEMICOLON", "COLON", "COMMA", "L_PAREN", "R_PAREN", "L_SQUARE_BRACKET" , "R_SQUARE_BRACKET", "ASSIGN"
};

%}
%union {
int num;
char* ident;
}
%error-verbose
%start start
%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY
%token END_BODY INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO FOR BEGINLOOP
%token ENDLOOP CONTINUE READ WRITE TRUE FALSE RETURN
%token SEMICOLON COLON COMMA R_SQUARE_BRACKET L_SQUARE_BRACKET L_PAREN R_PAREN 
%left SUB ADD MULT DIV MOD EQ NEQ LT GT LTE GTE AND OR
%left L_PAREN R_PAREN L_SQUARE_BRACKET R_SQAURE_BRACKET 
%right NOT ASSIGN
%token <ident> IDENT 
%token <num> NUMBER
%%

start: program{
//file.open("output.mil");
};
program: %empty {if(find(functions.begin(), functions.end(), "main") == functions.end()){
			cout << "error: no main function found" << endl;
			exit(1); 
file.close();
}

}| function program {};
	
func_name: FUNCTION IDENT {
if(!file.is_open())
	{file.open("output.mil");}
functions.push_back($2);
string ident =$2;
funcname = "func " + ident;

//file << "func " << $2 <<endl;
};

beginparams: BEGIN_PARAMS {
	is_params = true;
};

endparams: END_PARAMS {
	is_params = false;
};


function: func_name SEMICOLON beginparams decloop endparams BEGIN_LOCALS decloop END_LOCALS BEGIN_BODY stateloop END_BODY
{
file<< funcname << endl;

for (int i =0; i<variables.size(); ++i){
	
	if(array_size[i] == -1){
		file<<". " << variables[i] <<endl;
	}else {
		file<< ".[] " << variables[i]<<", " <<array_size[i] <<endl;
		}
	}

if(printparams.size() != 0){
	for(int i =0; i< printparams.size(); ++i) {
		file<<"= " << printparams[i] << ", $" << paramval <<endl;
		paramval++;
	}
}

for(int i = 0; i < statements.size(); ++i) {
	file << statements[i] <<endl;
	}
variables.clear();
params.clear();
printparams.clear();
paramval=0;
array_size.clear();
statements.clear();
expressions.clear();
file<< "endfunc" <<endl <<endl;
};

decloop: declaration SEMICOLON decloop {} | %empty {};

stateloop: statement SEMICOLON stateloop {} | statement SEMICOLON {};

declaration: ident COLON decarray INTEGER {};

ident: decident COMMA ident {array_size.push_back(-1);} | decident {};

decident: IDENT {

	string varcheck = $1;
	if (find(keywords.begin(), keywords.end(), varcheck) != keywords.end()) {
		cout << "error on line " << currRow << ": variable \""<< varcheck << "\"" << " is the name of a reserved keyword" << endl;
    	exit(1);
	}
	for(int i = 0; i < variables.size(); ++i) {
		if (variables[i] == varcheck) {
			cout << "error on line " << currRow << ": variable \""<< varcheck << "\"" << " is already defined" << endl;
    		exit(1);
		}
	}
	variables.push_back(varcheck);

	if(is_params){
		printparams.push_back(varcheck);
		}
};

decarray: ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF {
if($3 <= 0){
cout << "error on line " << currRow << ": declared array size must be greater than 0" << endl;
exit(1);
}

array_size.push_back($3);} 

	| %empty {array_size.push_back(-1);};

statement: statevar{} | stateif {}  | statewhile{}  | statedo{}  | statefor{}  | stateread{}  | statewrite{}  | statecontinue{}  | statereturn {}; 

statevar: 
	varident ASSIGN expression { 
	int index = -1;
	for(int i=0; i<variables.size(); ++i) {
		if(temp4 == variables.at(i)){
			index = i;
			break;
		}
	}
	if(index == -1) {
		cout << "error on line " << currRow << ": used variable \""<< temp4 << "\"" << " not defined" << endl;
    		exit(1);
	}
	else if(array_size[index] != -1){
		 cout << "error on line " << currRow << ": used variable \"" << temp4 << "\"" <<" has conflicting data type" << endl;
    		 exit(1);
	}
	
	if (is_right_arr == -1){	
		statements.push_back("= " +temp4+ ", " + expressions.back());
       		expressions.pop_back();
	}else{
		statements.push_back("=[] " +temp4+", " + expressions.back());
		expressions.pop_back();
	}
}
	| varident L_SQUARE_BRACKET expression R_SQUARE_BRACKET ASSIGN expression {
            int index = -1;
		for(int i=0; i<variables.size(); ++i) {
		if(temp4 == variables.at(i)){
			index = i;
			break;
		}
	}
	if(index == -1) {
		cout << "error on line " << currRow << ": used variable \""<< temp4 << "\"" << " not defined" << endl;
		exit(1);
	}
	else if(array_size[index] == -1){
		cout << "error on line " << currRow << ": used variable \""<< temp4 << "\"" << " has conflicting data type" << endl;
	    	 exit(1);
	}
	else {
	    string sec = expressions.back();
            expressions.pop_back();
            string first = expressions.back();
            expressions.pop_back();
	    statements.push_back("[]= " + temp4 +", " + first + ", " + sec);
//	   statements.push_back("= " + temp + ", " + expressions.back());
// 	   expressions.pop_back();
	}

};

varident: IDENT {temp4 =($1); temp4=edit(temp4);};

stateif: if stateloop ENDIF {
	statements.push_back(": " + label2);
} |

	stateelse stateloop ENDIF {
	statements.push_back(": " + label3);
};

if: IF boolexp THEN {
	labelcount = labelcount + 3;
	int tempcount1 = labelcount;
	int tempcount2 = labelcount + 1;
	int tempcount3 = labelcount + 2;
	label1 = "label_" + to_string(tempcount1);
	label2 = "label_" + to_string(tempcount2);
	label3 = "label_" + to_string(tempcount3);
	statements.push_back("?:= " + label1 + ", " + expressions.back()); //if exp 
	statements.push_back(":= " + label2);
	statements.push_back(": " + label1);
	expressions.pop_back();
};

stateelse: if stateloop ELSE {
	statements.push_back(":= " + label3);
	statements.push_back(": " + label2);
};

statewhile: while_true stateloop ENDLOOP {
	statements.push_back(":= " + label1);
	statements.push_back(": " + label3);
};

while_true: while boolexp BEGINLOOP{
	statements.push_back("?:= " + label2 + ", " + expressions.back());
	statements.push_back(":= " + label3);
	statements.push_back(": " + label2);
	expressions.pop_back();
};
while: WHILE{
	labelcount = labelcount + 3;
        int tempcount1 = labelcount;
        int tempcount2 = labelcount + 1;
        int tempcount3 = labelcount + 2;
        label1 = "label_" + to_string(tempcount1);
        label2 = "label_" + to_string(tempcount2);
        label3 = "label_" + to_string(tempcount3);
        statements.push_back(": " + label1);
	in_loop = true;
};


statedo: do_while WHILE boolexp {
	statements.push_back("?:= " + label1 + ", " + expressions.back());
	expressions.pop_back();
	in_loop = true;
};

do_while: do stateloop ENDLOOP{
	statements.push_back(": " + label3);
};

do: DO BEGINLOOP{
	labelcount = labelcount + 3;
        int tempcount1 = labelcount;
        int tempcount2 = labelcount + 1;
        //int tempcount3 = labelcount + 2;
        label1 = "label_" + to_string(tempcount1);
        label3 = "label_" + to_string(tempcount2);
	statements.push_back(": " + label1);
	//in_loop = true;
};

statefor: for forboolexp for2 for3 
	  {};

for: FOR var ASSIGN NUMBER SEMICOLON{
	labelcount = labelcount + 3;
        int tempcount1 = labelcount;
        int tempcount2 = labelcount + 1;
        int tempcount3 = labelcount + 2;
        label1 = "label_" + to_string(tempcount1);
        label2 = "label_" + to_string(tempcount2);
        label3 = "label_" + to_string(tempcount3);
        in_loop = true;
	statements.push_back("= " + tmp + ", " + to_string($4));	
	statements.push_back(": " + label1);
};

forboolexp: boolexp SEMICOLON{
	statements.push_back("?:= " + label2 + ", " + expressions.back()); //if exp
        statements.push_back(":= " + label3);
	expressions.pop_back();
};

for2: var ASSIGN expression{
	statements.push_back("= " + tmp + ", " + expressions.back());
	expressions.pop_back();
};

for3: BEGINLOOP stateloop ENDLOOP {
	statements.push_back(":= " + label1);
	statements.push_back(": " + label3);
};

stateread: READ rvarloop {};

rvarloop: rvar COMMA rvarloop {} | rvar {};

rvar: IDENT {
	string tmp_ = $1;
	tmp_.pop_back();
	tmp_ = edit(tmp_);
	statements.push_back(".< " + tmp_);


}| IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET{

	string tmp_ =$1;
        tmp_.pop_back();
        tmp_ = edit(tmp_);
        statements.push_back(".<" + tmp_ + ", " + expressions.back());
        expressions.pop_back();
};

statewrite: WRITE wvarloop {};

wvarloop: wvar COMMA wvarloop {} | wvar{};

wvar: IDENT {

	string tmp_ = $1;
	tmp_.pop_back();
        tmp_ = edit(tmp_);
        statements.push_back(".> " + tmp_);

} | IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET{

	string tmp_ =$1;
	tmp_.pop_back();
	tmp_ = edit(tmp_);
	statements.push_back(".>" + tmp_ + ", " + expressions.back());
	expressions.pop_back();


};

statecontinue: CONTINUE {
if(!in_loop) {
 cout << "error on line " << currRow << ": cannot use continue outside of loop";
 exit(1);
}
statements.push_back(":= " + label3);
in_loop = false;
	
};

statereturn: RETURN expression {
string newvar = expressions.back();
statements.push_back("ret " + newvar);
expressions.pop_back();

};

boolexp: relandexp {} | relandexp OR boolexp {
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("|| " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);
};

relandexp: relexp {} | relexp AND relandexp {
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("&& " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);
};

relexp: NOT rel_exp {
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        //string exp2 = expressions.back();
        //expressions.pop_back();
        statements.push_back("! " + newvar + ", " + exp1);
        expressions.push_back(newvar);


} | rel_exp {};

rel_exp: relexp2 {} | TRUE {
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
	statements.push_back("= " + newvar+ ", 1");
	expressions.push_back(newvar);
}
| FALSE {
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        statements.push_back("= " + newvar+ ", 1");
        expressions.push_back(newvar);
} | relexp3 {};

relexp2: eq {}| neq{} | lt{} | gt{} | lte {} | gte{};

relexp3: L_PAREN boolexp R_PAREN {};

expression: multexp {} | multexp ADD expression {

	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("+ " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);
} | multexp SUB expression {
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("- " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);
};

eq: expression EQ expression{
 varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("== " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);}; 
neq: expression NEQ expression{
 varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("!= " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);}; 
lt: expression LT expression {
 varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("< " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);}; 
gt: expression GT expression {
 varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("> " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);}; 
lte: expression LTE expression{
 varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("<= " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);}; 
gte: expression GTE expression {
 varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back(">= " + newvar + ", " + exp2+ ", " + exp1);
        expressions.push_back(newvar);};

multexp: term {} 
| term MULT multexp {varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("* " + newvar + ", " + exp2+ ", " + exp1);
	expressions.push_back(newvar);
} 
| term DIV multexp {
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        string exp2 = expressions.back();
        expressions.pop_back();
        statements.push_back("/ " + newvar + ", " + exp2+ ", " + exp1);
	expressions.push_back(newvar);
} 
| term MOD multexp { 
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
	string exp1 = expressions.back();
	expressions.pop_back();
	string exp2 = expressions.back();
	expressions.pop_back();
        statements.push_back("% " + newvar + ", " + exp2+ ", " + exp1);
	expressions.push_back(newvar);
};

term: term1 {} | term2 {};

term1: SUB term3 {
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
        array_size.push_back(-1);
        string exp1 = expressions.back();
        expressions.pop_back();
        //string exp2 = expressions.back();
        // expressions.pop_back();
        statements.push_back("- " + newvar + ", " + "0" + ", " + exp1);
        expressions.push_back(newvar);

} | term3 {};

term3: var {} 
| NUMBER {
	is_right_arr = -1;	
	varcount++;
	string newvar = "temp_" + to_string(varcount);
	variables.push_back(newvar);
	expressions.push_back(newvar);
	array_size.push_back(-1);
	statements.push_back("= " + newvar + ", " + to_string($1));	
	} 
| term4 {};

term4: L_PAREN expression R_PAREN {};

term2: term2ident L_PAREN exploop R_PAREN {//ident must be a function call
	if(find(functions.begin(), functions.end(), temp5) == functions.end()) {
		cout << "error on line " << currRow << ": used variable \""<< temp5 << "\"" << " not declared as a function" << endl;
		exit(1);
	}
	for(int i = params.size()-1; i<=params.size(); --i){
		statements.push_back("param " + params[i]);
	}
	varcount++;
        string newvar = "temp_" + to_string(varcount);
        variables.push_back(newvar);
	array_size.push_back(-1);
	statements.push_back("call " + temp5 + ", " + newvar);
        expressions.push_back(newvar);

};

term2ident: IDENT {temp5 = $1; temp5.pop_back();
temp5= edit(temp5);
 //temp5.erase(remove(temp5.begin(), temp5.end(), ' '), temp5.end());
};

exploop: expression COMMA exploop {params.push_back(expressions.back());
expressions.pop_back();}
| expression {params.push_back(expressions.back()); expressions.pop_back();} | %empty {};

var: IDENT {

//check if ident has been declared and is of right type
tmp = $1;
tmp.pop_back();
//boost::trim_right(tmp);
tmp = edit(tmp);
//tmp.erase(remove(tmp.begin(), tmp.end(), ' '), tmp.end());
is_right_arr= -1;
int index = -1;
        for(int i=0; i<variables.size(); ++i) {
                if(tmp == variables.at(i)){
                        index = i;
                        break;
                }
        }
        if(index == -1) {
                cout << "error on line " << currRow << ": used variable \""<< tmp << "\"" << " not defined" << endl;
                exit(1);
        }
        else if(array_size[index] != -1){
                 cout << "error on line " << currRow << ": used variable \"" << tmp << "\"" <<" has conflicting data type" << endl;
                 exit(1);
        }
expressions.push_back(tmp);} 
| varident2 L_SQUARE_BRACKET expression R_SQUARE_BRACKET {
string add = expressions.back();
expressions.pop_back();
is_right_arr = 1;
//string tmp =$1;
//tmp.pop_back();
int index = -1;
        for(int i=0; i<variables.size(); ++i) {
                if(temp3 == variables.at(i)){
                        index = i;
                        break;
                }
        }
        if(index == -1) {
                cout << "error on line " << currRow << ": used variable \""<< temp3 << "\"" << " not defined" << endl;
                exit(1);
        }
        else if(array_size[index] == -1){
                 cout << "error on line " << currRow << ": used variable \"" << temp3 << "\"" <<" has conflicting data type" << endl;
                 exit(1);
        }
//statements.pop_back();

expressions.push_back(temp3 + ", " + add);};

varident2: IDENT {temp3 = $1; temp3.pop_back();
temp3 = edit(temp3);
//boost::trim_right(temp3);
//		temp3.erase(remove(temp3.begin(), temp3.end(), ' '), temp3.end());
};

%%

string edit(string to_edit){
	int index;
	string s = to_edit;
	boost::trim_right(s);
	
	for(int i= 0 ; i< s.size(); ++i){
		if(s[i] == ' '){
			s.pop_back();
			//break;
		}
	}
	boost::trim_right(s);
	if(s.back() == '|' || s.back() == '&' || s.back() == '=' || s.back() == '>' || s.back() == '<'
	||s.back()=='!' ||s.back() == '+'||s.back() =='-'||s.back()=='%'||s.back() =='/'||s.back()=='*'){
	s.pop_back();
	}
	boost::trim_right(s);
	//s.erase(remove(s.begin(), s.end(), ' '), s.end());
	for(int i= 0 ; i< s.size(); ++i){
                if(s[i] == ' '){
                        s.pop_back();
                        //break;
                }
        }
	boost::trim_right(s);
	for(int i=0; i<s.size(); ++i){
	if(s[i] == ' '){
		index = i;
		break;
		}
	}
	while(s[index] == ' '){
		s.pop_back();
	}
	return s;
}


int yyerror(const char* msg) {
  extern int currRow;

  printf("!!! %s on line %d\n", msg, currRow);
  exit(1);
}


