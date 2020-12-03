makefile: mini_l.lex mini_l.y 
	  bison -v -d --file-prefix=y mini_l.y
	   flex mini_l.lex
	   g++ -std=c++0x -o my_compiler y.tab.c lex.yy.c -lfl
