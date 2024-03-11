%{
    #include "2005089.h"
    #include <iostream>
    #include <fstream>
    #include <sstream>
    #include <cstdlib>
    #include <string>
    #include <vector>
    // #include "2005089_ScopeTable.h"
    // #include "2005089_SymbolTable.h"
    // #include "2005089_SymbolInfo.h"


    // run this command to compile the code
    //     clear 
    // yacc -d -y 2005089.y
    // g++ -w -c -o y.o y.tab.c 
    // flex 2005089.l
    // g++ -w -c -o l.o lex.yy.c 
    // g++ y.o l.o -lfl -o a
    // ./a 2005089.c
   

    using namespace std;
    extern int lineCount;
    extern int errorCount;
    int scopeCount = 0;
    int funcNo = 0;

    const int bucketSize = 11;

    

    ofstream logOut;
    ofstream errorOut;
    ofstream parseOut;

    SymbolTable* st = new SymbolTable();
    extern FILE* yyin;

    string name,type,fname,ftype;
    vector<SymbolInfo*> v;

    struct variable 
    {
        
        string name;
        int varSize; // >=0-> array; -1 -> variable; -2 -> function declaration, -3->function definition
    } tempVariable;

    
    vector <variable> variableList;

    struct parameter 
    {
        
        string paramType;
        string paramName; //empty during declaration
    } tempParameter;

    
    vector <parameter> parameterList; // for function declaration and definition
    vector <string> argumentList; // for function calling 

    
    int yylex(void);
    int yyparse(void);
   
    void yyerror(const char *s) {
    errorCount++;
    errorOut << "Line# " << lineCount << ": " << s << endl;
    }

    string stringToUpper(string str)
    {
        for(int i  = 0 ; i<str.length() ; i++)
            str[i] = toupper(str[i]);
        return str;
    }

    void printLog( string str) { logOut << str << endl; }



    void insertFunction(string name, string dtype, int size)
    {
        SymbolInfo* tmp = new SymbolInfo(name,dtype);
        tmp->setDataType(dtype);
        tmp->setArraySize(size);

        
      

        for(int i =  0 ; i < parameterList.size() ; i++)
            tmp->addParameterToFunction(parameterList[i].paramName,stringToUpper(parameterList[i].paramType));
        bool meow = st->insert2(tmp,logOut);
        cout << "LINE 85-> " << meow << endl;
        cout << "FUNC NO " << ++funcNo << endl; 
    }

    void insertVariable(string dtype, string name, int size)
    {
        string formattedType = stringToUpper(dtype);
        SymbolInfo *tmp;
        tmp = new SymbolInfo(name,formattedType);
        tmp->setDataType(formattedType);
        tmp->setArraySize(size);
        bool t = st->insert2(tmp,logOut);
        cout << "Line 94 -> " << t << endl;
        cout << tmp->getName() << endl;
        cout << tmp->getType() << endl;

        if(size > 0)
            cout << "Array " << name << " of type : " << formattedType << endl;
        

    }

    void pushToParameterList(string name, string type)
    {
        tempParameter.paramName = name;
        tempParameter.paramType = type;
        parameterList.push_back(tempParameter);
    }

    void check(SymbolInfo* tmp)
    {
         if(tmp->getType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
    }
    }
%}

%union { 
    SymbolInfo* symbol; }

%type <symbol> start program unit func_declaration func_definition var_declaration type_specifier id parameter_list compound_statement 
%type <symbol> unary_expression factor declaration_list statements rel_expression simple_expression term logic_expression expression_statement expression variable 
%type <symbol> argument_list arguments statement
%token <symbol> ADDOP MULOP INCOP RELOP ASSIGNOP LOGICOP BITOP NOT 
%token <symbol> LCURL RCURL LPAREN RPAREN LSQUARE RSQUARE COMMA SEMICOLON
%token <symbol> DO FOR WHILE ELSE IF PRINTLN RETURN VOID CHAR 
%token <symbol> INT FLOAT DOUBLE 
%token <symbol> CONST_INT CONST_FLOAT ID
%token <symbol> DECOP 

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE 



%%

start: program {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "START");
    tmp->setStringTree("start : program ");
    tmp->setSpace(0);
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    tmp->printParseTree(0,parseOut);
    
    $$ = tmp;
    printLog("start : program ");
    // cout << lineCount << endl;
    // cout << "data type of start " << $$->getDataType() << endl;
    // cout << "data type of program " << $1->getDataType() << endl;
};

program : program unit {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName(), "PROGRAM");
    tmp->setStringTree("program : program unit ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($2->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("program : program unit");
    // cout << "LINE : " << lineCount << endl;
    // cout << "data type of left program" << $$->getDataType() << endl;
    // cout << "data type of program " << $1->getDataType() << endl;
    // cout << "data type of unit " << $2->getDataType() << endl;

} | unit {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "PROGRAM");
    tmp->setStringTree("program : unit ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("program : unit");
    // cout << "------LINE : ------ " << lineCount << endl;
    // cout << "data type of unit " << $1->getDataType() << endl;
    // cout << "data type of left program" << $$->getDataType() << endl;

};

unit : var_declaration {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "UNIT");
    tmp->setStringTree("unit : var_declaration ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("unit : var_declaration  ");
} | func_declaration {
    cout << "unit : var_declaration" << endl;
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "UNIT");
    tmp->setStringTree("unit : func_declaration ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("unit : func_declaration ");
} | func_definition {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "UNIT");
    tmp->setStringTree("unit : func_definition ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("unit : func_definition  ");
};


func_declaration: type_specifier id emb1 LPAREN parameter_list RPAREN emb2 SEMICOLON {
    cout << "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << endl;
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $4->getName()+ $5->getName()
    + $6->getName() + $8->getName() , "FUNC_DECLARATION");
    tmp->setStringTree("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($8->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($4);
    tmp->addChild($5);
    tmp->addChild($6);
    tmp->addChild($8);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON ");
    parameterList.clear();

} | type_specifier id emb1 LPAREN RPAREN emb2 SEMICOLON {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $4->getName()+ $5->getName()
    + $7->getName() , "FUNC_DECLARATION");
    tmp->setStringTree("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($7->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($4);
    tmp->addChild($5);
    tmp->addChild($7);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON ");
    parameterList.clear();
};



emb1 : {
    fname = name;
    cout << "fname " << fname << endl;
    ftype = type;
    cout << "ftype " << ftype << endl;
}

emb2 : {
    SymbolInfo* tmp = st->lookUp(fname,logOut);

  if(tmp == NULL)
    {
         cout << "inserting function 233" << endl;
         insertFunction(fname, ftype, -2);
         
    }
    else
     {
       if(tmp->getArraySize() == -2 || tmp->getArraySize() == -3)
       {
        errorOut << "Line# " << lineCount << ": Redeclaration of function '" << fname << "'" << endl;
        errorCount++;
       }
       else 
       {
         errorOut << "Line# " << lineCount << ": Redeclared as different kind of symbol '" << fname << "'" << endl;
         errorCount++;
       }
     }

}

func_definition: type_specifier id emb1 LPAREN parameter_list RPAREN emb3 compound_statement {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $4->getName()+ " " + $5->getName()
    +" " +  $6->getName() + " " + $8->getName() , "FUNC_DEFINITION");
    tmp->setStringTree("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($8->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($4);
    tmp->addChild($5);
    tmp->addChild($6);
    tmp->addChild($8);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement ");
   
} | type_specifier id emb1 LPAREN RPAREN emb3 compound_statement {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $4->getName()+ " " + $5->getName() + " "
   + $7->getName() +"\n" , "FUNC_DEFINITION");
    tmp->setStringTree("func_definition : type_specifier ID LPAREN RPAREN compound_statement ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($7->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($4);
    tmp->addChild($5);
    tmp->addChild($7);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("func_definition : type_specifier ID  LPAREN RPAREN compound_statement ");
   
};




parameter_list  : parameter_list COMMA type_specifier ID {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $4->getName(), "PARAMETER_LIST");
    tmp->setStringTree("parameter_list : parameter_list COMMA type_specifier ID ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($4->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->addChild($4);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("parameter_list : parameter_list COMMA type_specifier ID ");

    for(int i = 0 ; i<parameterList.size() ; i++)
    {
        if(parameterList[i].paramName == $4->getName())
        {
            errorOut << "Line# " << lineCount << ": Redefinition of parameter '" << $4->getName() << "'" << endl;
            errorCount++;

            //*** WATCH OUT ***//
        }
     }
    pushToParameterList($4->getName(),$3->getName());
} | parameter_list COMMA type_specifier {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "PARAMETER_LIST");
    tmp->setStringTree("parameter_list : parameter_list COMMA type_specifier ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->setIsLeaf(false);

    $$ = tmp;

    printLog("parameter_list : parameter_list COMMA type_specifier ");

    pushToParameterList("",$3->getName());
} | type_specifier ID {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName(), "PARAMETER_LIST");
    tmp->setStringTree("parameter_list : type_specifier ID ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($2->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("parameter_list : type_specifier ID ");
    pushToParameterList($2->getName(),$1->getName());
} | type_specifier {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "PARAMETER_LIST");
    tmp->setStringTree("parameter_list : type_specifier ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("parameter_list : type_specifier ");
    pushToParameterList("",$1->getName());
};

compound_statement: LCURL emb4 statements RCURL {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $3->getName() + " " + $4->getName(), "COMPOUND_STATEMENT");
    tmp->setStringTree("compound_statement : LCURL statements RCURL ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($4->getELine());
    tmp->addChild($1);
    tmp->addChild($3);
    tmp->addChild($4);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("compound_statement : LCURL statements RCURL ");
    
    st->printAll(logOut);
    st->exitScope(logOut);


} | LCURL emb4 RCURL {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $3->getName(), "COMPOUND_STATEMENT");
    tmp->setStringTree("compound_statement : LCURL RCURL ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($3);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("compound_statement : LCURL RCURL ");

    st->printAll(logOut);
    st->exitScope(logOut);
};

emb3 : {
    SymbolInfo* tmp = st->lookUp(fname,logOut);
    

    
    if(tmp == NULL)
    {
         cout << "inserting function 289" << endl;
         insertFunction(fname, ftype, -3);
        //  st->printAll(logOut);
         
    }
       
    else if(tmp->getArraySize() == -2)
    {
        if(parameterList.size() == 1 && tmp->getNumberOfParameters() == 0 && parameterList[0].paramType == "VOID")
          {
            cout << "MEOW310" << endl;
            tmp->setArraySize(-3);
        }
        else if(parameterList.size() == 0 && tmp->getNumberOfParameters() == 1 && tmp->getParam(0).getParameterType() == "VOID")
          {
            cout << "MEOW316" << endl;
            tmp->setArraySize(-3);
        }
        else if(tmp->getType() != ftype)
        {
            cout << "MEOW322" << endl;
            errorOut << "Line# " << lineCount << ": Conflicting types for '" << fname << "'" << endl;
            errorCount++;
        }
        else 
        {
            int flag = 0;
            cout << fname << " LINE 333 and Linecount" << lineCount  << " " << parameterList.size() << " " << tmp->getNumberOfParameters()  << endl;
            if(parameterList.size() != tmp->getNumberOfParameters())
            {
                errorOut << "Line# " << lineCount << ": Conflicting types for '"<< fname << "'" << endl;
                errorCount++;
            }
            else
            {
                for(flag = 0; flag<parameterList.size() ; flag++)
            {
                if(tmp->getParam(flag).getParameterType() != parameterList[flag].paramType) break;
                if(flag == parameterList.size())
                 tmp->setArraySize(-3);
                else
                {
                    errorOut << "Line# " << lineCount << ": Error of function123 ----- " << fname << endl;
                    errorCount++;
                }
             }

            }
            
            
        }
     }   
    else 
    {
        cout << "ALREADY IN THE SCOPETABLE " << endl;
      
        errorOut << "Line# " << lineCount <<  ": '" << fname << "' redeclared as different kind of symbol" << endl;
        errorCount++;
    } 
}

emb4: {
    st->enterScope(++scopeCount,bucketSize,logOut);
    if(parameterList.size() == 1 && parameterList[0].paramType == "VOID")
    {
        
    }
    else
    {
        for(int i = 0 ; i<parameterList.size() ; i++)
            insertVariable(parameterList[i].paramType,parameterList[i].paramName,-1);
    }
    parameterList.clear();
}

var_declaration : type_specifier declaration_list SEMICOLON {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "VAR_DECLARATION");
    tmp->setStringTree("var_declaration : type_specifier declaration_list SEMICOLON ");

      string str = "FLOAT";

      cout << "LINE 471" << $1->getName() << endl;
    if(stringToUpper($1->getName()) == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Variable or field '" << $2->getName() << "' declared void" << endl;
        errorCount++;

        // for(int i =  0 ; i<variableList.size() ; i++)
        //     insertVariable(str,variableList[i].name,variableList[i].varSize);
    }
    else 
    {
        str = $1->getName();
        cout << "LINE 490" << str << endl;
        for(int i =  0 ; i<variableList.size() ; i++)
            insertVariable(str,variableList[i].name,variableList[i].varSize);
    }

    variableList.clear();


    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("var_declaration : type_specifier declaration_list SEMICOLON  ");

  
};

type_specifier: INT {
    type = "INT";
    SymbolInfo *tmp = new SymbolInfo($1->getName(), $1->getType());
    tmp->setStringTree("type_specifier : INT ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false); //////// CHECK /////////
    $$ = tmp;
    printLog("type_specifier	: INT ");
} | VOID {
    type = "VOID";
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "VOID");
    tmp->setStringTree("type_specifier : VOID ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false); //////// CHECK /////////
    $$ = tmp;
    printLog("type_specifier    : VOID ");
}
| FLOAT {
    type = "FLOAT";
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "FLOAT");
    tmp->setStringTree("type_specifier : FLOAT ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false); //////// CHECK /////////
    $$ = tmp;
    printLog("type_specifier	: FLOAT  ");
};


id : ID {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), $1->getType());
    name = $1->getName();
    tmp->setStringTree("ID: "+ name);
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(true);
    $$ = tmp;
    tmp ->setDataType($1->getDataType());
 
    ///// check printLog(" ID" "+name = $1->getName())  //
}

declaration_list : declaration_list COMMA ID {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "DECLARATION_LIST");
    tmp->setStringTree("declaration_list : declaration_list COMMA ID ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("declaration_list : declaration_list COMMA ID  ");
    cout << " NOOO 1 " << endl;

     tempVariable.name = $3->getName();
    tempVariable.varSize = -1;
    variableList.push_back(tempVariable);
    

    

    SymbolInfo *tmp2 = st->lookUp($3->getName(),logOut);

    cout << "LINE 563 " << st->getScopeID($3->getName(),logOut) << " " << st->getCurrentScopeID() << endl;

    if(tmp2 != NULL) 
    {
        if(st->getScopeID($3->getName(),logOut) == st->getCurrentScopeID() )
        {
            errorOut << "Line# " << lineCount << ": Conflicting types for '" << $3->getName() << "'" << endl;
            errorCount++;
        }
        
    }

    for(int i = 0 ; i<variableList.size() - 1 ; i++)
        {
            if(variableList[i].name == $3->getName())
            {
                errorOut << "Line# " << lineCount << ": Redefinition of parameter '" << $3->getName() << "'" << endl;
                errorCount++;
            }
        }

   




} | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $4->getName() + " " + $5->getName() + " " + $6->getName(), "DECLARATION_LIST");
    tmp->setStringTree("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($6->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->addChild($4);
    tmp->addChild($5);
    tmp->addChild($6);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE ");

   
    cout << " NOOO 2" << endl;

         tempVariable.name = $3->getName();
    tempVariable.varSize = stoi($5->getName());
    variableList.push_back(tempVariable);

    SymbolInfo *tmp2 = st->lookUp($3->getName(),logOut);

     if(tmp2 != NULL) 
    {
        if(st->getScopeID((string)$3->getName(),logOut) == st->getCurrentScopeID() )
        {
            errorOut << "Line# " << lineCount << ": Conflicting types for'" << $3->getName() <<"'" << endl;
            errorCount++;
        }
        
    }

     for(int i = 0 ; i<variableList.size() -1 ; i++)
        {
            if(variableList[i].name == $3->getName())
            {
                errorOut << "Line# " << lineCount << ": Redefinition of parameter '" << $3->getName() << "'" << endl;
                errorCount++;
            }
        }

    

} | ID {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "DECLARATION_LIST");
    tmp->setStringTree("declaration_list : ID ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("declaration_list : ID ");

    cout << " NOOO 3" << endl;

    
    tempVariable.name = $1->getName();
    tempVariable.varSize = -1;
    variableList.push_back(tempVariable);
   

    SymbolInfo *tmp2 = st->lookUp($1->getName(),logOut);

     if(tmp2 != NULL) 
    {
        if(st->getScopeID($1->getName(),logOut) == st->getCurrentScopeID() )
        {
            errorOut << "Line# " << lineCount << ": Conflicting types for'" << $1->getName() << "'" << endl;
            errorCount++;
        }
        
    }

        for(int i = 0 ; i<variableList.size() - 1 ; i++)
            {
                if(variableList[i].name == $1->getName())
                {
                    errorOut << "Line# " << lineCount << ": Redefinition of parameter '" << $1->getName() << "'" << endl;
                    errorCount++;
                }
            }


} | ID LSQUARE CONST_INT RSQUARE 
{
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $4->getName(), "DECLARATION_LIST");
    tmp->setStringTree("declaration_list : ID LSQUARE CONST_INT RSQUARE ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($4->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->addChild($4);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("declaration_list : ID LSQUARE CONST_INT RSQUARE ");

    cout << " NOOO 4" << endl;

    tempVariable.name = $1->getName();
    tempVariable.varSize = stoi($3->getName());
    variableList.push_back(tempVariable);
  

    SymbolInfo *tmp2 = st->lookUp($1->getName(),logOut);

     if(tmp2 != NULL) 
    {
        if(st->getScopeID($3->getName(),logOut) == st->getCurrentScopeID() )
        {
            errorOut << "Line# " << lineCount << ": Conflicting types for'" << $1->getName() << "'" << endl;
            errorCount++;
        }
        
    }

        for(int i = 0 ; i<variableList.size() -1 ; i++)
            {
                if(variableList[i].name == $1->getName())
                {
                    errorOut << "Line# " << lineCount << ": Redeclaration of variable " << $1->getName() << endl;
                    errorCount++;
                }
            }

    
}

statements : statements statement {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName(), "STATEMENT");
    tmp->setStringTree("statements : statements statement ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($2->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("statements : statements statement ");
} | statement {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "STATEMENTS");
    tmp->setStringTree("statements : statement ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("statements : statement ");
};

statement : var_declaration {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "STATEMENT");
    tmp->setStringTree("statement : var_declaration ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("statement : var_declaration ");
} | expression_statement {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "STATEMENT");
    tmp->setStringTree("statement : expression_statement ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("statement : expression_statement ");
} | compound_statement {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "STATEMENT");
    tmp->setStringTree("statement : compound_statement ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("statement : compound_statement ");
} | RETURN expression SEMICOLON {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "RETURN");
    tmp->setStringTree("statement : RETURN expression SEMICOLON ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("statement : RETURN expression SEMICOLON ");

    if($2->getType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
    }

} | PRINTLN LPAREN ID RPAREN SEMICOLON {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + " " + $5->getName() /// CHECK
    , "PRINT");
    tmp->setStringTree("statement : PRINTLN LPAREN ID RPAREN SEMICOLON ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($5->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    // tmp->addChild($4);
    tmp->addChild($5);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("statement : PRINTLN LPAREN ID RPAREN SEMICOLON ");

   } | FOR LPAREN expression_statement emb5 emb6 expression_statement emb5 emb6 expression emb5 emb6 RPAREN statement {
        SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + 
        $3->getName() + " " + $6->getName() + " " + $9->getName() + " " + $12->getName() + " " + $13->getName(), "FOR_LOOP");
        tmp->setStringTree("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement ");
        tmp->setSLine($1->getSLine());
        tmp->setELine($13->getELine());
        tmp->addChild($1);
        tmp->addChild($2);
        tmp->addChild($3);
        tmp->addChild($6);
        tmp->addChild($9);
        tmp->addChild($12);
        tmp->addChild($13);
        tmp->setIsLeaf(false);
        $$ = tmp;
        printLog("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement ");
    } | IF LPAREN expression emb5 RPAREN emb6 statement %prec LOWER_THAN_ELSE
    {
        SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $5->getName() + " " + $7->getName(), "IF");
        tmp->setStringTree("statement : IF LPAREN expression RPAREN statement %prec THEN ");
        tmp->setSLine($1->getSLine());
        tmp->setELine($7->getELine());
        tmp->addChild($1);
        tmp->addChild($2);
        tmp->addChild($3);
        tmp->addChild($5);
        tmp->addChild($7);
        tmp->setIsLeaf(false);
        $$ = tmp;
        printLog("statement : IF LPAREN expression RPAREN statement %prec THEN ");


    } | IF LPAREN expression emb5 RPAREN emb6 statement ELSE statement 
    {
        SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $5->getName() + " " + $7->getName() + " " + $8->getName() + " " + $9->getName(), "IF_ELSE");
        tmp->setStringTree("statement : IF LPAREN expression RPAREN statement ELSE statement ");
        tmp->setSLine($1->getSLine());
        tmp->setELine($9->getELine());
        tmp->addChild($1);
        tmp->addChild($2);
        tmp->addChild($3);
        tmp->addChild($5);
        tmp->addChild($7);
        tmp->addChild($8);
        tmp->addChild($9);
        tmp->setIsLeaf(false);
        $$ = tmp;
        printLog("statement : IF LPAREN expression RPAREN statement ELSE statement ");
        
    } | WHILE LPAREN expression emb5 RPAREN emb6 statement {
        SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $5->getName() + " " + $7->getName(), "WHILE");
        tmp->setStringTree("statement : WHILE LPAREN expression RPAREN statement ");
        tmp->setSLine($1->getSLine());
        tmp->setELine($7->getELine());
        tmp->addChild($1);
        tmp->addChild($2);
        tmp->addChild($3);
        tmp->addChild($5);
        tmp->addChild($7);
        tmp->setIsLeaf(false);
        $$ = tmp;
        printLog("statement : WHILE LPAREN expression RPAREN statement ");
    };

    

emb5:
{
        ftype = type;
};

emb6: 
{
    cout << "LINE 891" << ftype << endl;
        if(ftype == "VOID")
        {
            errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
            errorCount++;
        }
};
    
expression_statement: SEMICOLON {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), $1->getType());
    tmp->setStringTree("expression_statement : SEMICOLON ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    type = $1->getDataType();
    tmp->setDataType(type);
    $$ = tmp;
    printLog("expression_statement : SEMICOLON ");
} | expression SEMICOLON {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName(), "EXPRESSION_STATEMENT");
    tmp->setStringTree("expression_statement : expression SEMICOLON ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($2->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->setIsLeaf(false);
    type = $1->getDataType();
    tmp->setDataType(type);
    $$ = tmp;
    printLog("expression_statement : expression SEMICOLON ");
};

variable : ID {
 
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "ID");
    tmp->setStringTree("variable : ID ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("variable : ID ");
    name = $1->getName();  ///// recheck - 2 ///////
    SymbolInfo* tmp2 = st->lookUp($1->getName(),logOut);
    if(tmp2 == NULL)
    {
        errorOut << "Line# " << lineCount << ": Undeclared variable '" << $1->getName() << "'" << endl;
        errorCount++;
        
    }
    else
    {
        
        if(tmp2->getDataType()=="VOID"){}
            
        else
            tmp->setDataType(tmp2->getDataType());
         
    }

} | ID LSQUARE expression RSQUARE {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $4->getName(), "ID");
    tmp->setStringTree("variable : ID LSQUARE expression RSQUARE ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($4->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->addChild($4);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("variable : ID LSQUARE expression RSQUARE ");

    cout << "LINE 937" << $3->getDataType() << endl;

    SymbolInfo* tmp2 = st->lookUp($1->getName(),logOut);

    if($3->getDataType() != "INT" && $3->getDataType() != "CONST_INT")
    {
        errorOut << "Line# " << lineCount << ": Array subscript is not an integer" << endl;
        errorCount++;
    }

    if(tmp2 == NULL)
    {
        errorOut << "Line " << lineCount << ": Undeclared variable '" << $1->getName() << "'" << endl;
        errorCount++;
        
    }
    else
    {
        if(tmp2->getArraySize() > 0) 
        {
            if(tmp2->getDataType()=="VOID"){}
                
            else
                tmp->setDataType(tmp2->getDataType());
        }
        else 
        {
            errorOut << "Line# " << lineCount << ": '" << $1->getName() << "' is not an array" << endl;
            errorCount++;
        }   
       
    }
};

expression: logic_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "EXPRESSION");
    tmp->setStringTree("expression : logic_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    type = $1->getDataType();
    cout << "LINE 976 " << type << endl;
    tmp->setDataType(type);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("expression : logic_expression ");
} | variable ASSIGNOP logic_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), $3->getType());
    tmp->setStringTree("expression : variable ASSIGNOP logic_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
   
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("expression : variable ASSIGNOP logic_expression ");

    if($1->getDataType() != $3->getDataType())
    {
        
        if($1->getDataType() == "INT" && $3->getDataType() == "FLOAT")
        {
            string msg = ": Warning: possible loss of data in assignment of "+ $3->getDataType() + " to " + $1->getDataType();
            errorOut << "Line# " << lineCount << msg << endl;
            errorCount++;
        }
        else
        {    
            
        }
       
    }

 
if($3->getDataType() == "VOID" ) 
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
       
    }

    type = $1->getDataType();
    tmp->setDataType(type);
} 

logic_expression: rel_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName(),$1->getType());
    tmp->setStringTree("logic_expression : rel_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    // type = $1->getDataType();   //// NOTICE ////
    tmp->setDataType($1->getDataType());   //// NOTICE ////
    $$ = tmp;
    printLog("logic_expression : rel_expression ");

    cout << "LINE 1037" << $1->getDataType() << endl;
    } | rel_expression LOGICOP rel_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), $1->getType());
 
    tmp->setStringTree("logic_expression : rel_expression LOGICOP rel_expression ");
    tmp->setDataType($1->getDataType());

   

    if($1->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
      
    }

    if($3->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
      
    }


    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->setIsLeaf(false);
   
    tmp->setDataType($1->getDataType());
    $$ = tmp;
    printLog("logic_expression : rel_expression LOGICOP rel_expression ");
    


    };


rel_expression: simple_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "REL_EXPRESSION");
    tmp->setStringTree("rel_expression : simple_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    // type = $1->getDataType();
    tmp->setDataType($1->getDataType());
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("rel_expression : simple_expression ");
} | simple_expression RELOP simple_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "REL_EXPRESSION");
    tmp->setStringTree("rel_expression : simple_expression RELOP simple_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());

    if($1->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
     
    }

    if($3->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
   
    }


    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
 
    tmp->setDataType($1->getDataType());
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("rel_expression : simple_expression RELOP simple_expression ");
};

simple_expression: term {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "SIMPLE_EXPRESSION");
    tmp->setStringTree("simple_expression : term ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setDataType($1->getDataType());
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("simple_expression : term ");
} | simple_expression ADDOP term {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "SIMPLE_EXPRESSION");
    tmp->setStringTree("simple_expression : simple_expression ADDOP term ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());

    if($1->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
  
    }

    if($3->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
      
    }

    if($1->getDataType() == "VOID" || $3->getDataType() == "VOID")
    {
        
    }
    else 
    {
        tmp->setDataType($1->getDataType());
    }

    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("simple_expression : simple_expression ADDOP term ");
};

term : unary_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "TERM");
    tmp->setStringTree("term : unary_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    tmp->setDataType($1->getDataType());
    $$ = tmp;
    printLog("term : unary_expression ");
    cout << "LINE 1192" << $1->getDataType() << endl;
} | term MULOP unary_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "TERM");
    tmp->setStringTree("term : term MULOP unary_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    $$ = tmp;

   if($1->getDataType() == "VOID" || $1->getDataType() == "" )
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
      
    }

    if($3->getDataType() == "VOID" || $3->getDataType() == "")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
      
    }

    cout << "NOOOOOOOOO lineCount " << lineCount << "    1" << $1->getDataType() << "1   1" << $3->getDataType() << endl;
   

    if ($2->getName() == "%" && (($1->getDataType() != "INT") 
     || ($3->getDataType() != "INT"))) {
       if(($1->getDataType() == "INT" && $3->getDataType() == "FLOAT" ) ||($3->getDataType() == "INT" && $1->getDataType() == "FLOAT" ) )
        {
            errorOut << "Line# " << lineCount << ": Operands of modulus must be integers " << endl;
            errorCount++;
        }
        
} else if ($2->getName() == "%" && ($1->getDataType() != "FLOAT" && $3->getDataType() != "FLOAT")) {
     // recover which i didn't have the energy to do // 
} else {
    $$->setDataType($1->getDataType());
}

if ($3->getName() == "0" && ($2->getName() == "%" || $2->getName() == "/")) {
    // divide by zero error
    errorOut << "Line# " << lineCount << ": Warning: division by zero i=0f=1Const=0" << endl;
    errorCount++;
}
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->setIsLeaf(false);
    
    cout << "LINE 1239" << tmp->getDataType() << endl;
    printLog("term : term MULOP unary_expression ");
};

unary_expression : ADDOP unary_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName(), "UNARY_EXPRESSION");
    tmp->setStringTree("unary_expression : ADDOP unary_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($2->getELine());
    if($2->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
   
    }
    else 
    {
        tmp->setDataType($2->getDataType());
    }
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("unary_expression : ADDOP unary_expression ");
} | NOT unary_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName(), "UNARY_EXPRESSION");
    tmp->setStringTree("unary_expression : NOT unary_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($2->getELine());
    if($2->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
      
    }

    
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->setIsLeaf(false);
    $$ = tmp;
    
    printLog("unary_expression : NOT unary_expression ");

    tmp->setDataType("INT");
} | factor {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "UNARY_EXPRESSION");
    tmp->setStringTree("unary_expression : factor ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    tmp->setDataType($1->getDataType());
    $$ = tmp;
    printLog("unary_expression : factor ");
};

factor: variable {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "FACTOR");
    tmp->setStringTree("factor : variable ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setDataType($1->getDataType());
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("factor : variable ");
} | LPAREN expression RPAREN {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "FACTOR");
    tmp->setStringTree("factor : LPAREN expression RPAREN ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3); 
    tmp->setDataType($2->getDataType()); ///recheck-2 //
    tmp->setIsLeaf(false);
    $$ = tmp;

    if($2->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
    
    }
} | CONST_INT {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "CONST_INT");
    tmp->setStringTree("factor : CONST_INT ");
    tmp->setDataType("INT"); /// notice int or const_int?
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    $$ = tmp;
    printLog("factor : CONST_INT ");
} | CONST_FLOAT {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "CONST_FLOAT");
    tmp->setStringTree("factor : CONST_FLOAT ");
    tmp->setDataType("FLOAT");  // notice
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    $$ = tmp;
    printLog("factor : CONST_FLOAT ");
} | variable INCOP {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName(), "FACTOR");
    tmp->setStringTree("factor : variable INCOP ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($2->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->setDataType($1->getDataType());
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("factor : variable INCOP ");
} | variable DECOP {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName(), "FACTOR");
    tmp->setStringTree("factor : variable DECOP ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($2->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->setDataType($1->getDataType());
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("factor : variable DECOP ");

} | ID LPAREN argument_list RPAREN {
        SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $4->getName(), "FACTOR");
        tmp->setStringTree("factor : ID LPAREN argument_list RPAREN ");
        tmp->setSLine($1->getSLine());
        tmp->setELine($4->getELine());
        tmp->addChild($1);
        tmp->addChild($2);
        tmp->addChild($3);
        tmp->addChild($4);

        SymbolInfo* tmp2 = st->lookUp($1->getName(),logOut);

        if(tmp2 == NULL)
        {
            errorOut << "Line# " << lineCount << ": Undeclared function '" << $1->getName() <<"'" << endl;
            errorCount++;
           

            
        }
        else if(tmp2->getArraySize() != -3)
        {
            errorOut << "Line# " << lineCount << "Undefined function '" << $1->getName() << "'" ;
            errorCount++;
            
        }
        else 
        {
            if(tmp2->getNumberOfParameters() == 1 && argumentList.size() == 0 && tmp2->getParam(0).getParameterType() == "VOID")
            {
                tmp->getDataType() = tmp2->getDataType();
            }
           if(tmp2->getNumberOfParameters() > argumentList.size())
           {
            errorOut << "Line# " << lineCount << ": Too few arguments to function '" << $1->getName() << "'" << endl;
            errorCount++;
           }
           else if(tmp2->getNumberOfParameters() < argumentList.size())
           {
            errorOut << "Line# " << lineCount << ": Too many arguments to function '"  << $1->getName() << "'" << endl;
            errorCount++;
           }
           else 
           {
             vector<int> error;
             int flag = 0;

             for(int i  = 0 ; i<argumentList.size() ; i++)
            {
                string str = "";
                if(argumentList[i] == "CONST_INT") str = "INT";
                else if(argumentList[i] == "CONST_FLOAT") str = "FLOAT";
                else str = argumentList[i];
              
                if(stringToUpper(argumentList[i]) != tmp2->getParam(i).getParameterType())
                {
                    error.push_back(i+1);
                    flag ++;
                }
             }

             for(int j = 0 ;j<flag ; j++)
             {
                errorOut << "Line# " << lineCount << ": Type mismatch for argument " << error[j] << " of '" << $1->getName() << "'" << endl;
                errorCount++;
             }
             tmp->setDataType(tmp2->getDataType());
            //  cout << "LINE 1518,lineCount " << lineCount << tmp->getDataType() << " " << tmp2->getDataType() << endl;
               
           }
        }

        argumentList.clear();
        tmp->setIsLeaf(false);
        $$ = tmp;
      
        
        printLog("factor : ID LPAREN argument_list RPAREN ");
}

argument_list : arguments {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "ARGUMENT_LIST");
    tmp->setStringTree("argument_list : arguments ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("argument_list : arguments ");
} | {
   
    SymbolInfo* tmp = new SymbolInfo("", "ARGUMENT_LIST");
    printLog("argument_list : ");
};

arguments : arguments COMMA logic_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "ARGUMENTS");
    tmp->setStringTree("arguments : arguments COMMA logic_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);

    if($3->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression  " << endl;
        errorCount++;
    }
    else 
    {
        $1->setDataType($3->getDataType());
    }

    argumentList.push_back($1->getDataType());
    tmp->setIsLeaf(false);
    
    $$ = tmp;
    printLog("arguments : arguments COMMA logic_expression ");
} | logic_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), $1->getType());
    tmp->setStringTree("arguments : logic_expression ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);

    if($1->getDataType() == "VOID")
    {
        errorOut << "Line# " << lineCount << ": Void cannot be used in expression  " << endl;
        errorCount++;
    } 
    else 
     $$->setDataType($1->getDataType());
    
    argumentList.push_back($1->getDataType());
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("arguments : logic_expression ");
};

%%

int main(int argc, char *argv[])
{
    if(argc<2){
        cout<<"Input file not found"<<endl ;
        return 1 ;
    }


    logOut.open("2005089_logfile.txt") ; 
    errorOut.open("2005089_errorfile.txt") ;
    parseOut.open("2005089_parsefile.txt");
   
    st->enterScope(++scopeCount,bucketSize,logOut) ;
    yyin = NULL ; 
    yyin = fopen(argv[1] ,"r") ; 
    if( yyin == NULL) return 1 ;
    yyparse() ; 
    fclose(yyin) ; 
    //symboltable->print_all(logfile) ;  //not needed 
   
    logOut<<"Total Lines: "<<lineCount<<endl ; 
    logOut<<"Total Errors: "<<errorCount<<endl ;
    logOut.close() ; 
    errorOut.close(); 
    parseOut.close() ; 
    

     return 0 ; 
     
}





