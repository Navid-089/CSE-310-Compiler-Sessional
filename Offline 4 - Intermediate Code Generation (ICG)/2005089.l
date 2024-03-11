%option noyywrap



WS [ \t\v\r\f]+ 
NEWLINE [\n]
CR [(\r)?]
ID_LETTER [A-Z_a-z]
ID_ALPHANEUMERIC [0-9A-Z_a-z]
DIGIT [0-9]

%{
#include "2005089.h"
#include <iostream>
#include "y.tab.h"



// #include "2005089_ScopeTable.h"
// #include "2005089_SymbolTable.h"
// #include "2005089_SymbolInfo.h"
using namespace std;




int lineCount = 1;
int errorCount = 0;

extern ofstream logOut;
extern ofstream errorOut;

void yyerror(const char* s);

void setValues(string pyytext, string type) 
{    
    SymbolInfo* sym = new SymbolInfo(pyytext, type);
    yylval.symbol = sym;
    yylval.symbol->setSLine(lineCount);
    yylval.symbol->setELine(lineCount);
    yylval.symbol->setIsLeaf(true);
    logOut << "Line# " << lineCount << ": Token <" << type << "> Lexeme " << pyytext << " found" << endl;
}

void printError(string str, string yytext)
{
	logOut << "Error at line# " << lineCount << ": " << str << " " << yytext << endl;
	errorCount++;
}


%}




%%

"int" {
    setValues(yytext, "INT");
    return INT;
}

"float" {
    setValues(yytext, "FLOAT");
    return FLOAT;
}

"double" {
    setValues(yytext, "DOUBLE");
    return DOUBLE;
}

"char" {
    setValues(yytext, "CHAR");
    return CHAR;
}

"void" {
    setValues(yytext, "VOID");
    return VOID;
}

"return" {
    setValues(yytext, "RETURN");
    return RETURN;
}

"println" {
    setValues(yytext, "PRINTLN");
    return PRINTLN;
}

"if" {
    setValues(yytext, "IF");
    return IF;
}

"else" {
    setValues(yytext, "ELSE");
    return ELSE;
}

"while" {
    setValues(yytext, "WHILE");
    return WHILE;
}

"for" {
    setValues(yytext, "FOR");
    return FOR;
}

"do" {
    setValues(yytext, "DO");
    return DO;
}

";" {
    setValues(yytext, "SEMICOLON");
    return SEMICOLON;
}

"," {
    setValues(yytext, "COMMA");
    return COMMA;
}

"]" {
    setValues(yytext, "RSQUARE");
    return RSQUARE;
}

"[" {
    setValues(yytext, "LSQUARE");
    return LSQUARE;
}

")" {
    setValues(yytext, "RPAREN");
    return RPAREN;
}

"(" {
    setValues(yytext, "LPAREN");
    return LPAREN;
}

"}" {
    setValues(yytext, "RCURL");
    return RCURL;
}

"{" {
    setValues(yytext, "LCURL");
    return LCURL;
}

"!" {
    setValues(yytext, "NOT");
    return NOT;
}

"&"|"|"|"^"|"<<"|">>" {
    setValues(yytext, "BITOP");
    return BITOP;
}

"&&"|"||" {
    setValues(yytext, "LOGICOP");
    return LOGICOP;
}

"=" {
    setValues(yytext, "ASSIGNOP");
    return ASSIGNOP;
}

"=="|"<"|"<="|">"|">="|"!=" {
    setValues(yytext, "RELOP");
    return RELOP;
}

"++" {
    setValues(yytext, "INCOP");
    return INCOP;
}

"--" {
    setValues(yytext, "DECOP");
    return DECOP;
}



"*"|"/"|"%" {
    setValues(yytext, "MULOP");
    return MULOP;
}

"+"|"-" {
    setValues(yytext, "ADDOP");
    return ADDOP;
}

{DIGIT}+ {
    setValues(yytext, "CONST_INT");
    return CONST_INT;
}

({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)? {
    setValues(yytext, "CONST_FLOAT");
    return CONST_FLOAT;
}

{ID_LETTER}{ID_ALPHANEUMERIC}* {
    setValues(yytext, "ID");
    return ID;
}

{WS}+ {}

({CR}?{NEWLINE}) {
    lineCount++;
}

({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*([Ee]\.?{DIGIT}+)?  {
    printError("TOO_MANY_DECIMAL_POINTS",yytext);
}

({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*([Ee][+-]?({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*)* {
	printError("ILLFORMED_NUMBER",yytext);
}

[0-9]+[A-Z_a-z][0-9A-Z_a-z]* {
	printError("INVALID_ID_SUFFIX_NUM_PREFIX",yytext);
}

. {
    printError("UNRECOGNISABLE_CHARACTER",yytext);
}

%%