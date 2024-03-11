clear 
yacc -d -y 2005089.y
g++ -w -c -o y.o y.tab.c 
flex 2005089.l
g++ -w -c -o l.o lex.yy.c 
g++ y.o l.o -lfl -o a
./a 2005089.c


