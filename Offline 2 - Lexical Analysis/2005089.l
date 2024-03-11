%option noyywrap

%x afterStar
%x inComment


WS [ \t\v\r\f]+ 
NEWLINE [\n]
CR [(\r)?]
ID_LETTER [A-Z_a-z]
ID_ALPHANEUMERIC [0-9A-Z_a-z]
DIGIT [0-9]
RCURL("}")



%{
#include<iostream>
#include<string>
#include<cstdlib>
#include<cstring>
#include<fstream>

using namespace std;

#include "2005089_SymbolTable.h"

SymbolTable st;

int lineCount = 1;
int errorCount = 0;
int warningCount = 0;
int TabNeeded = 0;
int ScopeCount = 1;
bool isIndented = false;
string comment = "";

FILE* input;
ofstream logOutput;
ofstream token;

void insertToken(string str, string type)
{
   if(st.insert(str,type, logOutput) == true) 
		st.printAll(logOutput);
}

void finish() 
{
    st.printAll(logOutput);
    st.exitScope(logOutput);

    logOutput << "Total lines: " << lineCount << endl;
    logOutput << "Total errors: " << errorCount << endl;
	logOutput << "Total warnings: " << warningCount << endl;
}


void IncreaseLineNumber(string str)
{
  for(int i = 0; i < str.length(); i++)
  {
	if(str[i] == '\n')
	  lineCount++;
  }
}  

void checkIndentation(string str)
{
	int tCount = 0;
	int sCount = 0;

	for(int i = 0; i < str.length(); i++)
	{
		if(str[i] == '\t')
			tCount++;
		else if(str[i] == ' ')
			sCount++;
		else
			break;
	}

	if(sCount != 0 )
	  {
		logOutput <<"Line# "<<lineCount<<": Warning, tab requrired but got space."<<endl;
		warningCount++;
	  }

	  if(tCount != TabNeeded)
	  {
		logOutput<<"Line# "<<lineCount<<": warning, "<<TabNeeded<<" of tabs needed but got "<<tCount<<" tabs."<<endl;
        warningCount++;
	  }
		

}

void printToken(string str, string yytext)
{
	token << "<" << str << ", " << yytext << ">" << endl;
}

void printIndent() 
{
	if(!isIndented)
	{
		if(TabNeeded != 0)
		{
			logOutput <<"Line# "<<lineCount<<": warning, "<<TabNeeded<<" of tabs needed but got 0 tabs."<<endl;
			warningCount++;
		}
		isIndented = true;
	}
}

void printLog(string str, string yytext)
{
	printIndent();
	logOutput << "Line# " << lineCount << ": Token <" << str << "> Lexeme " << yytext << " found" << endl;
}

void printError(string str, string yytext, int lc,bool flag)
{
	printIndent();
	if(flag)
	{
		logOutput << "Error at line# " << lc << ": " << str << " " << yytext << endl;
		errorCount++;
	}
	else 
	{
		logOutput << "Error at line# " << lc << ": " << str << " " << yytext ;
		errorCount++;
	}
}

bool checkIfSingleLined(string str)
{
	for(int i = 0; i < str.length(); i++)
	{
		if(str[i] == '\n')
			return false;
	}

	return true;
}



char lexToChar(char* str)
{
    if(str[1] != '\\')
     return str[1];
	 
	switch(str[2])
    {
        case 'n': return '\n';
        case 't': return '\t';
        case 'v': return '\v';
        case 'b': return '\b';
        case 'r': return '\r';
        case 'f': return '\f';
        case 'a': return '\a';
        case 'e': return '\e';
        case '\\': return '\\';
        case '?': return '\?';
        case '\'': return '\'';
        case '\"': return '\"';
        case '0': return '\0';
    }
	
}


int countNewLine(string str)
{
	int n =  0;
	for(int i = 0 ; i<str.length() ; i++)
	{
		if(str[i] == '\n')
			n++;
	}

	return n;
}




string ptrToString(const char* ptr) {
  int length = strlen(ptr);
  string str = "";
  
  for(int i=0; i<length; i++) {
    if(ptr[i] != '\\') {
		
      str.append(1u, ptr[i]); 
	  
    } else {
      if(ptr[i+1] == 'n') {
        str.append(1u, '\n');
      } else if(ptr[i+1] == 't') {
        str.append(1u, '\t');
      } else if(ptr[i+1] == 'v') {
        str.append(1u, '\v');
      } else if(ptr[i+1] == 'f') {
        str.append(1u, '\f');
      } else if(ptr[i+1] == 'r') {
        str.append(1u, '\r');
      } else if(ptr[i+1] == 'a') {
        str.append(1u, '\a');
      } else if(ptr[i+1] == 'b') {
        str.append(1u, '\b');
      } else if(ptr[i+1] == '0') {
        str.append(1u, '\0');
      } else if(ptr[i+1] == '\'') {
        str.append(1u, '\'');
      } else if(ptr[i+1] == '\\') {
        if(ptr[i+2] == '\n') {
		 if(ptr[i+3] == 'n') {
            str.append(1u, '\n');
          } else if(ptr[i+3] == 't') {
            str.append(1u, '\t');
          } else if(ptr[i+3] == 'v') {
            str.append(1u, '\v');
          } else if(ptr[i+3] == 'f') {
            str.append(1u, '\f');
          } else if(ptr[i+3] == 'r') {
            str.append(1u, '\r');
          } else if(ptr[i+3] == 'a') {
            str.append(1u, '\a');
          } else if(ptr[i+3] == 'b') {
            str.append(1u, '\b');
          } else if(ptr[i+3] == '0') {
            str.append(1u, '\0');
          } else if(ptr[i+3] == '\\') {
            str.append(1u, '\\');
          } else if(ptr[i+3] == '\"') {
            str.append(1u, '\"');
          } else if(ptr[i+3] == '\'') {
            str.append(1u, '\'');
          } else if(ptr[i+3] == '?') {
            str.append(1u, '\?');
          } else if(ptr[i+3] == 'e') {
            str.append(1u, '\e');
          } else {
            str.append(1u, ptr[i+3]);
          }
       
          i+=3;
          lineCount++;
          continue;
        } else {
          str.append(1u, '\\');
        }
      } else if(ptr[i+1] == '\"') {
        str.append(1u, '\"');
      }  else if(ptr[i+1] == '?') {
        str.append(1u, '\?');
      } else if(ptr[i+1] == 'e') {
        str.append(1u, '\e');
      } else if(ptr[i+1] == '\n') {
			lineCount++;
      } else if(ptr[i+1] == '\r')
	  {
		if(ptr[i+2] == '\n')
		{
			str.append(1u, '\t');
			i = i+2;
		}
	  } else {
        str.append(1u, ptr[i+1]);  
      }
       i++;
    }
  }
  
  return str;
}







%}

%%

"if" {
		printLog("IF", yytext);
		printToken("IF", yytext);
     }
"for" {
		printLog("FOR", yytext);
		printToken("FOR", yytext);
     }
"do" {
		printLog("DO", yytext);
		printToken("DO", yytext);
     }
"int" {
     	printLog("INT", yytext);
		printToken("INT", yytext);
	 }
"float" {
    	printLog("FLOAT", yytext);
		printToken("FLOAT", yytext);
        }
"void" {
        printLog("VOID", yytext);
		printToken("VOID", yytext);
        }
"switch" {
		printLog("SWITCH", yytext);
		printToken("SWITCH", yytext);
        }
"default" {
            
		printLog("DEFAULT", yytext);
		printToken("DEFAULT", yytext);
        }
"else" {
            
		printLog("ELSE", yytext);
		printToken("ELSE", yytext);
}	
        
"while" {
            
        printLog("WHILE", yytext);
		printToken("WHILE", yytext);
			
 }
"break" {
        printLog("BREAK",yytext);
		printToken("BREAK", yytext);
}
"char" {
        printLog("CHAR", yytext);
		printToken("CHAR", yytext);
    }
"double" {
            
        printLog("DOUBLE", yytext);
		printToken("DOUBLE", yytext);
    }
"return" {
			
			printLog("RETURN", yytext);
			printToken("RETURN", yytext);
			}
			
"case" {
			printLog("CASE", yytext);
			printToken("CASE", yytext);
			}
"continue" {
			printLog("CONTINUE", yytext);
			printToken("CONTINUE", yytext);
			}

{DIGIT}+ {
	        printLog("CONST_INT", yytext);
			printToken("CONST_INT", yytext);
		 }

({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)? {
		    printLog("CONST_FLOAT", yytext);
			printToken("CONST_FLOAT", yytext);
		}
		

";" {
			printLog("SEMICOLON", yytext);
			printToken("SEMICOLON", yytext);
			}	
"," {
			printLog("COMMA", yytext);
			printToken("COMMA", yytext);
			}
"]" {
			printLog("RSQUARE", yytext);
			printToken("RSQUARE", yytext);
			}
"[" {
			printLog("LSQUARE", yytext);
			printToken("LSQUARE", yytext);
			}
"}" {
			TabNeeded--;
			printLog("RCURL", yytext);
			printToken("RCURL", yytext);
			st.exitScope(logOutput);
			
			}
"{" {
			TabNeeded++;
			printLog("LCURL", yytext);	
			printToken("LCURL", yytext);			
			st.enterScope(++ScopeCount,10,logOutput);
			
			}
")" {
			printLog("RPAREN", yytext);
			printToken("RPAREN", yytext);
			}
"(" {
			printLog("LPAREN", yytext);
			printToken("LPAREN", yytext);
			}
"!" {
			printLog("NOT", "not");
			printToken("NOT", "not");
			}
"&"|"|"|"^"|"<<"|">>" {
			printLog("BITOP", yytext);
			printToken("BITOP", yytext);
			}

"&&"|"||" {
			printLog("LOGICOP",yytext);
			printToken("LOGICOP", yytext);
		  }
"=" {
			printLog("ASSIGNOP",yytext);
			printToken("ASSIGNOP", yytext);

			}
"=="|"<"|"<="|">"|">="|"!=" {
			printLog("RELOP",yytext);
			printToken("RELOP", yytext);
			}
"++"|"--" {
			printLog("INCOP",yytext);
			printToken("INCOP", yytext);
			}
"*"|"/"|"%" {
			printLog("MULOP",yytext);
			printToken("MULOP", yytext);
		 }	

"+"|"-" {
			printLog("ADDOP",yytext);
			printToken("ADDOP", yytext);
		 }


'([ !-~]{-}[\\'])'|'\\[ntvfrab0\\"'?e]'	{
			printIndent();
			logOutput << "Line# " << lineCount << ": Token <CONST_CHAR> Lexeme " << lexToChar(yytext) << " found" << endl;
			token << "<CONST_CHAR, " << lexToChar(yytext) << ">" << endl;
			}





{ID_LETTER}{ID_ALPHANEUMERIC}* {
			printLog("ID", yytext);
			printToken("ID", yytext);
			insertToken(yytext, "ID");
			}

^[ \t]* {
	isIndented = true;
	checkIndentation(yytext);
	
}

^[ \t]*{RCURL} {
			TabNeeded--;
			isIndented = true;
			checkIndentation(yytext);
			printLog("RCURL", "}");
			printToken("RCURL", "}");
			st.exitScope(logOutput);
			
			}


\"((([\t !-~]{-}[\\"])*(\\[ntvfrab0\\"'?e])*)*((\\){CR}{NEWLINE}))*(([\t !-~]{-}[\\"])*(\\[ntvfrab0\\"'?e])*)*\" {
	 string lexeme = ptrToString(yytext);
	int tmp = countNewLine(yytext);
	

	if (checkIfSingleLined(yytext) == false) {
        printLog("MULTI LINE STRING", yytext);
		printToken("MULTI LINE STRING", lexeme.substr(1, lexeme.length() - 2));
    } else {
        printLog("SINGLE LINE STRING", yytext);
		printToken("SINGLE LINE STRING", lexeme.substr(1, lexeme.length() - 2));
    }
	lineCount = lineCount + tmp;
}




\/\/(([\t !-~]{-}[\\])*(\\({CR}){NEWLINE}))*([\t !-~]*([\t !-~]{-}[\\]))* {
		printLog("SINGLE LINE COMMENT", yytext);
		IncreaseLineNumber(yytext);
}

\/\* {
		BEGIN inComment;
	}

<inComment>\* {
		comment.append(yytext);
		BEGIN afterStar;
}

<inComment>([\t\n !-~]{-}[\*])* {
		comment.append(yytext);
}

<afterStar>\/ {
	 string updatedComment = "/*" + comment + "/";
	 printLog("MULTI LINE COMMENT", updatedComment);
	 IncreaseLineNumber(comment);
	 comment = "";
	 BEGIN INITIAL;
}


<afterStar>\* {
		comment.append(yytext);
}

<afterStar>([\t\n !-~]{-}[\*]) {
		comment.append(yytext);
		BEGIN inComment;
}



{WS}+ {}
{NEWLINE}	{
	lineCount++;
	isIndented = false;}

({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*([Ee]\.?{DIGIT}+)? {
	printError("TOO_MANY_DECIMAL_POINTS", yytext, lineCount,true);
	}

({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*([Ee][+-]?({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*)* {
	printError("ILLFORMED_NUMBER",yytext, lineCount,true);
}

.  {
	printError("UNRECOGNIZED_CHAR",yytext,lineCount,true);
}

'' {
	printError("EMPTY_CONST_CHAR",yytext,lineCount,true);
}

[0-9]+[A-Z_a-z][0-9A-Z_a-z]* {
	printError("INVALID_ID_SUFFIX_NUM_PREFIX",yytext,lineCount,true);
}



'\\([\t !-~]{-}[ntvfrab0\\"'e?])'   {
		printError("UNKNOWN_ESCAPE_SEQUENCE",yytext,lineCount,true);
}

'\t'|'(([\t !-~]{-}['])|(\\'))(([\t !-~]{-}['])|(\\'))+' {
		printError("MULTICHAR_CONST_CHAR",yytext,lineCount,true);
}

'((\\')|([\t !-~]{-}[';]))*[;] {
		string formattedyytext = ptrToString(yytext);
		printError("UNFINISHED_CONST_CHAR",formattedyytext.substr(0,formattedyytext.length() - 1),lineCount,true);
		printLog("SEMICOLON", ";");
		printToken("SEMICOLON", ";");
		}



'((\\')|([\t !-~]{-}[';]))*({CR}{NEWLINE}) {
		printError("UNFINISHED_CONST_CHAR",yytext,lineCount,false);
		IncreaseLineNumber(yytext);    
}

\"((([\t !-~]{-}[\\"])*(\\[ntvfrab0\\"'?e])*)*((\\){CR}{NEWLINE}))*(([\t !-~]{-}[\\"])*(\\[ntvfrab0\\"'?e])*)*({CR}{NEWLINE}) {
	int linesInString = countNewLine(yytext);
	printError("UNFINISHED_STRING", yytext, lineCount + linesInString - 1, false);
	IncreaseLineNumber(yytext);
}
 



<afterStar><<EOF>> {
	int tmp = countNewLine(yytext);
	printError("UNFINISHED_COMMENT", "/*" + comment, lineCount + tmp, true);
	comment = "";
	IncreaseLineNumber(comment);
	lineCount++;
	BEGIN INITIAL;
	
	return 0;
}

<inComment><<EOF>> {
	int tmp = countNewLine(comment);
	printError("UNFINISHED_COMMENT", "/*" + comment, lineCount + tmp, true);
	comment = "";
	IncreaseLineNumber(comment);
	lineCount++;
	BEGIN INITIAL;
	finish();    
	return 0;
}

<INITIAL><<EOF>> {
	finish();
	return 0;
}


%%

int main(int argc, char* argv[])
{
	if(argc!=2) {
		cout << "input file not found" << endl;
		return 0;
	}

	input = fopen(argv[1], "r");
	logOutput.open("2005089_log.txt");
	token.open("2005089_token.txt");

	if(!input) {
		cout << "input file not found" << endl;
		return 0;
	}

	st.enterScope(1,10,logOutput);

	yyin = input;
	yylex();

	fclose(input);
	logOutput.close();
	token.close();

	return 0;
}
