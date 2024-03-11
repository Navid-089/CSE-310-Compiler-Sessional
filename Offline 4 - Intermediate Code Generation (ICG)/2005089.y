%{
    #include "2005089.h"
    #include <bits/stdc++.h>
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

    //for ICG 

    int currentOffset = 0;
    int labelCount = 0;
    
    int localVarCount = 0;
    int codeLineCount = 0;

   
 
    SymbolInfo* root;


    /////////// ICG ///////////

    const int bucketSize = 11;
    ofstream logOut;
    ofstream optOut;
 
    ofstream parseOut;

    ofstream asmCode;
    ofstream bufferOut;



    SymbolTable* st = new SymbolTable();
    extern FILE* yyin;

    string name,type,fname,ftype;
    string assemblyCode = "";
    vector<SymbolInfo*> v;
    vector<vector<string>> optCode;
    string line;

    struct variable 
    {
        
        string name;
        int varSize; // >=0-> array; -1 -> variable; -2 -> function declaration, -3->function definition
    } tempVariable;

    
    vector <variable> variableList;
    vector <variable> globalVariableList;
    vector <variable> allVarList;
    bool globalVariableFlag = true;
    int currentParamOffset = INT_MIN;

    

    struct parameter 
    {
        
        string paramType;
        string paramName; //empty during declaration
    } tempParameter;

    // many of them are weirdly used :c this offline is huge so pardon
    vector <parameter> parameterList; // for function declaration and definition
    vector <string> argumentList; // for function calling 
    vector<pair<string,int>> functionVariableOffsets;
    vector<pair<string,int>> functionParameterOffsets;
    unordered_map<string,vector<int>> functionVariableNumbers;
    unordered_map<string,vector<int>> functionParameterNumbers;
    bool printlnFlag = false;
    vector <int> parameterOffsets;
    
    string nowFunc = "";

    

    
    int yylex(void);
    int yyparse(void);
   
    void yyerror(const char *s) {
    errorCount++;
    //////errorOut << "Line# " << lineCount << ": " << s << endl;
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
     
    }

    void insertVariable(string dtype, string name, int size)
    {
        string formattedType = stringToUpper(dtype);
        SymbolInfo *tmp;
        tmp = new SymbolInfo(name,formattedType);
        tmp->setDataType(formattedType);
        tmp->setArraySize(size);
        bool t = st->insert2(tmp,logOut);
    }

    void pushToParameterList(string name, string type)
    {
        tempParameter.paramName = name;
        tempParameter.paramType = type;
        parameterList.push_back(tempParameter);
    }

      void write(string s) {
        asmCode << s << endl;
        codeLineCount++;
    } 


    string labelCreate() {
  
        return ("L" + to_string(labelCount++));

    }

    bool ifParam(string name) {
        for(int i = 0 ; i<parameterList.size() ; i++) 
            if(parameterList[i].paramName == name) 
                return true;
        return false;
    }

    bool ifVar(string name) {
        for(int i = 0 ; i<allVarList.size() ; i++) 
            if(allVarList[i].name == name) 
                return true;
        return false;
    }

    string labelCreate2() {
        
        return ("L" + to_string(labelCount++));
    }

    int findFinalParamOffset(string name) {
            for(int i = 0; i<functionParameterOffsets.size() ; i++) 
                if(functionParameterOffsets[i].first == name) 
                    return functionParameterOffsets[i].second;
    }

  
    void init() {
        write(".MODEL SMALL");
        write(".STACK 1000H");
        write(".Data");
        write("\tnumber DB \"00000$\"");
    }

    bool ifGlobal(string name) {
        for(int i = 0 ; i<globalVariableList.size() ; i++) 
            if(globalVariableList[i].name == name) 
                return true;
        return false;
    }

    void writeGlobalVars() {
        cout << "LINE 168 ///" << endl;

        for(int i = 0 ; i<globalVariableList.size(); i++) 
            cout << globalVariableList[i].name << " " << globalVariableList[i].varSize << endl;
        for(int i = 0 ; i<globalVariableList.size() ; i++) {
            string s = "";
            int sz = 0 ;
            if(globalVariableList[i].varSize == -1)
             sz = 1;
            else 
             sz = globalVariableList[i].varSize;

             s += "\t" + globalVariableList[i].name + " DW " + to_string(sz) + " DUP (0000H)";
            
             
             write(s);
           }
            globalVariableFlag = true;

           
    }


    void printNewLine() {
        write("\n\nnew_line PROC\n");
        write("\t PUSH AX");
        write("\t PUSH DX");
        write("\t MOV AH,2");
        write("\t MOV DL,0DH");
        write("\t INT 21H");
        write("\t MOV AH,2");
        write("\t MOV DL,0AH");
        write("\t INT 21H");
        write("\t POP DX");
        write("\t POP AX");
        write("\t RET");
        write("\n\nnew_line ENDP");
        write("\n\nprint_output PROC\t;print what is in ax");
        write("\t PUSH AX");
        write("\t PUSH BX");
        write("\t PUSH CX");
        write("\t PUSH DX");
        write("\t PUSH SI");
        write("\t LEA SI, number");
        write("\t MOV BX,10");
        write("\t ADD SI,4");
        write("\t CMP AX,0");
        write("\t JNGE negate");
        write("print:");
        write("\t XOR DX,DX");
        write("\t DIV BX");
        write("\t MOV [SI],DL");
        write("\t ADD [SI],'0'");
        write("\t DEC SI");
        write("\t CMP AX,0");
        write("\t JNE print");
        write("\t INC SI");
        write("\t LEA DX, SI");
        write("\t MOV AH,9");
        write("\t INT 21H");
        write("\t POP SI");
        write("\t POP DX");
        write("\t POP CX");
        write("\t POP BX");
        write("\t POP AX");
        write("\t RET");
        write("negate:");
        write("PUSH AX");
        write("\t MOV AH,2");
        write("\t MOV DL,'-'");
        write("\t INT 21H");
        write("\t POP AX");
        write("\t NEG CX");
        write("\t NEG AX");
        write("\t JMP print");
        write("\n\nprint_output ENDP");
}


    int findOffset(string name) {
        auto tmp = functionVariableNumbers.find(name);
        int sum = 0;
        for(int i = 0 ; i<tmp->second.size() ; i++) 
            sum += tmp->second[i];
        return (2*sum);
    }

    int findTotalParameterOffset(string name) {
        auto tmp = functionParameterNumbers.find(name);
        
        int sum = 0;
        for(int i = 0 ; i<tmp->second.size() ; i++) 
            sum += tmp->second[i];
        return (2*sum);
    }

    int findParamOffset(string name) {
        int sum = 0;
        for(int i=0 ; i<parameterOffsets.size(); i++)
            sum += parameterOffsets[i];
        return sum;
    }

    string convertOperation(string str) {
        if(str == "==") return "JE";
        else if(str == "<") return "JL";
        else if(str == ">") return "JG";
        else if(str == "<=") return "JLE";
        else if(str == ">=") return "JGE";
        else if(str == "!=") return "JNE";
        
    }

    int findLocalOffset(string name) {
        for(int i = 0 ; i<functionVariableOffsets.size() ; i++) 
            if(functionVariableOffsets[i].first == name) 
                return functionVariableOffsets[i].second;

    }

   

    void traverse(SymbolInfo* node) {

        // cout << " ---- " << node->getName() << " " << node->getType() << " " << node->getSLine() << " " << node->getELine() << endl;
        // cout << " ---- " << node->getStringTree() << " " << node->getSLine() << endl;
        // for(int i = 0 ; i<node->getNumberOfChildren() ; i++) 
        //     cout << node->getChild(i)->getStringTree() << endl ;


        // if(node->checkIfLeaf() == false) {
        //     for(int i = 0 ; i<node->getNumberOfChildren() ; i++) 
        //         traverse(node->getChild(i));
        // }
    }

    void codeGenerate(SymbolInfo* node, string st) {
        string str = node->getStringTree();

        cout << " ---- " << node->getStringTree() << " " << node->getSLine() << endl;
        for(int i = 0 ; i<node->getNumberOfChildren() ; i++) 
            cout << node->getChild(i)->getStringTree() << endl ;

        if(str == "start : program ") {
            init();
            writeGlobalVars();
            write(".CODE");
            codeGenerate(node->getChild(0),node->getName());
            if(printlnFlag)
                printNewLine();
            write("END main");
        }

        else if(str == "program : program unit ") {
            codeGenerate(node->getChild(0),node->getName());
            codeGenerate(node->getChild(1),node->getName());
        }

        else if(str == "program : unit ") {
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "unit : var_declaration " || 
                str == "unit : func_declaration " || 
                str == "unit : func_definition ") { 

            cout << "line 423 : " << str << endl;       
            codeGenerate(node->getChild(0),node->getName());
           
           
        }

        else if(str == "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON " ) {
            /// notice 
            codeGenerate(node->getChild(0),node->getName());
            codeGenerate(node->getChild(3),node->getName());
        }

        else if(str == "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON ") {
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "func_definition : type_specifier ID LPAREN RPAREN compound_statement ") {
            if(globalVariableFlag) {
                currentOffset = 0;
                functionVariableOffsets.clear();
            }

            parameterList.clear();

            string name = node->getChild(1)->getName();
            nowFunc = name;
            currentParamOffset = 0;
            functionParameterOffsets.clear();
            
            codeGenerate(node->getChild(0),node->getName());
           
            write("\n" + name+ " PROC");
            if(name == "main") {
                write("\n\tMOV AX, @DATA");
                write("\tMOV DS,AX");
            }
           
            write("\tPUSH BP");
            write("\tMOV BP, SP");
            //  cout << "HENLOOO " << str << endl;
            codeGenerate(node->getChild(4),node->getName());
            
            write( "exit_" + name + ": \n ");
            
            int offset = findOffset(name);
            write("\tADD SP, " + to_string(offset));
            write("\tPOP BP");

            if(name == "main") {
                write("\tMOV AH, 4CH");
                write("\tINT 21H");
            }

            // cout << name << endl;

            write(name + " ENDP");

        }

        else if(str == "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement ") {
              if(globalVariableFlag) {
                currentOffset = 0;
                functionVariableOffsets.clear();
               
            }

            parameterList.clear();

            string name = node->getChild(1)->getName();
            nowFunc = name;
            currentParamOffset = 0;
            functionParameterOffsets.clear();

            

            codeGenerate(node->getChild(0),node->getName());
            
            codeGenerate(node->getChild(3),node->getName());
            
           
            write(name+ " PROC");
            if(name == "main") {
                write("\tMOV AX, @DATA");
                write("\tMOV DS,AX");
            }

            write("\tPUSH BP");
            write("\tMOV BP, SP");
            codeGenerate(node->getChild(5),node->getName());
            
            write( "exit_" + name + ": \n ");
            
            int offset = findOffset(name);
            write("\tADD SP, " + to_string(offset));
            write("\tPOP BP");

            if(name == "main") {
                write("\tMOV AH,4CH");
                write("\tINT 21H");
            }
            else {
                write("\tRET");
            }

            //notice

            // cout << name << endl;

            
            write(name + " ENDP");

        }

        else if(str == "parameter_list : parameter_list COMMA type_specifier ID " || 
               str == "parameter_list : parameter_list COMMA type_specifier ") {
            tempParameter.paramName = node->getChild(3)->getName();
            tempParameter.paramType = node->getChild(2)->getName();
            parameterList.push_back(tempParameter);

            string name = node->getChild(3)->getName();
            // int tmp = -findOffset(nowFunc) + currentOffset;
            // currentOffset += 2;
            // functionVariableOffsets.push_back(make_pair(name,tmp));

          
            int tmp = 4 +  currentParamOffset;
            currentParamOffset += 2;
            functionParameterOffsets.push_back(make_pair(name,tmp));

             cout << "Line 485 : " << name << " " << tmp << endl;


            

            codeGenerate(node->getChild(0),node->getName());
            codeGenerate(node->getChild(2),node->getName());
        }



        else if(str == "parameter_list : type_specifier ID " || 
        str == "parameter_list : type_specifier ") {
            
            tempParameter.paramName = node->getChild(1)->getName();
            tempParameter.paramType = node->getChild(0)->getName();
            parameterList.push_back(tempParameter);

            string name = node->getChild(1)->getName();
             cout << "MEOW" << endl;
             cout << nowFunc << endl;
            // int tmp = -findOffset(nowFunc) + currentOffset;
            // currentOffset += 2;
           
            // functionVariableOffsets.push_back(make_pair(name,tmp));

            
            int tmp = 4 + currentParamOffset;
            currentParamOffset += 2;
            functionParameterOffsets.push_back(make_pair(name,tmp));

            cout << "Line 513 : " << name << " " << tmp << endl;

         
            codeGenerate(node->getChild(0),node->getName());

            // notice
        }

        else if(str == "compound_statement : LCURL statements RCURL ") {
            if(node->label == "") 
            { 
            //   cout << "line 501 " << node->getChild(1)->getName() << endl;
              node->label = labelCreate();
              cout << "line 418, " << node->label << endl;
            }
            node->getChild(1)->label = node->label;
            codeGenerate(node->getChild(1),node->getName());
        }

        else if(str== "compound_statement : LCURL RCURL ") {
            // do nothing
        }

        else if(str == "var_declaration : type_specifier declaration_list SEMICOLON ") {
            codeGenerate(node->getChild(0),node->getName());
            codeGenerate(node->getChild(1),node->getName());

            // cout << "Meow1" << st << endl;
            // cout << nowFunc << endl;
            
            
            auto it = functionVariableNumbers.find(nowFunc);
            
            if(globalVariableFlag == false) {
                // cout << "Line 439 --- " << endl;
            }
            else {
                
            if(it != functionVariableNumbers.end()) {
                cout << "line 523, number of variables: " << it->second.size() << endl;
                
                
                for(int i = 0 ; i<it->second.size() ; i++) 
                    write("\tSUB SP," + to_string(it->second[i]*2));
            }
        }
        }


        else if(str == "statements : statements statement ") {
            string label = labelCreate();
            node->getChild(0)->label = label;
            node->getChild(1)->label = node->label;
            codeGenerate(node->getChild(0),node->getName());
            codeGenerate(node->getChild(1),node->getName());
            write(node->label + ": \n ");
            cout << "Line 461, " << node->label << endl;
        }

        else if(str == "statements : statement ") {
            node->getChild(0)->label = node->label;
            codeGenerate(node->getChild(0),node->getName());
            write(node->label + ": \n ");
        }
         else if(str == "statement : compound_statement ") {
            node->getChild(0)->label = labelCreate();
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "statement : var_declaration " || 
        str == "statement : expression_statement ") {
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement ") {
            codeGenerate(node->getChild(2),node->getName());
            string tmp = labelCreate();
            write(tmp + ": \n ");
            node->getChild(3)->isCondition = true;
            node->getChild(3)->trueLabel = labelCreate();
            node->getChild(3)->falseLabel = node->label;
            node->getChild(6)->label = labelCreate();
            codeGenerate(node->getChild(3),node->getName());
            write(node->getChild(3)->trueLabel + ": \n ");
            codeGenerate(node->getChild(6),node->getName());
            codeGenerate(node->getChild(4),node->getName());
            write("\tJMP " + tmp + "\t;line " + to_string(node->getSLine()));
        }

        else if(str == "statement : IF LPAREN expression RPAREN statement %prec THEN ") {
            node->getChild(2)->isCondition = true;
            node->getChild(2)->falseLabel = node->label;
            node->getChild(2)->trueLabel = labelCreate();
            codeGenerate(node->getChild(2),node->getName());
            write(node->getChild(2)->trueLabel + ": \n ");
            node->getChild(4)->label = node->label;
            codeGenerate(node->getChild(4),node->getName());

            //notice

        }

        else if(str == "statement : IF LPAREN expression RPAREN statement ELSE statement ") {
            node->getChild(2)->isCondition = true;
            node->getChild(2)->trueLabel = labelCreate();
            node->getChild(2)->falseLabel = labelCreate();
            node->getChild(4)->label = node->getChild(2)->falseLabel;
            node->getChild(6)->label = node->label;
            codeGenerate(node->getChild(2),node->getName());
            write(node->getChild(2)->trueLabel + ": \n ");
            codeGenerate(node->getChild(4),node->getName());
            write("\tJMP " + node->label);
            write(node->getChild(2)->falseLabel + ": \n ");
            codeGenerate(node->getChild(6),node->getName());
        }

        else if(str == "statement : WHILE LPAREN expression RPAREN statement ") {
            string tmp = labelCreate();
            write(tmp + ": \n ");
            node->getChild(2)->isCondition = true;
            node->getChild(2)->trueLabel = labelCreate();
            node->getChild(2)->falseLabel = node->label;
            codeGenerate(node->getChild(2),node->getName());
            write(node->getChild(2)->trueLabel + ": \n ");
            node->getChild(4)->label = node->label;
            codeGenerate(node->getChild(4),node->getName());
            write("\tJMP " + tmp + "\t;line " + to_string(node->getSLine()) );
        }

        else if(str == "statement : PRINTLN LPAREN ID RPAREN SEMICOLON ") {
            // cout << "line 624, " << node->getChild(2)->getName() << endl;
            if(ifGlobal(node->getChild(2)->getName())) {
                
                name = node->getChild(2)->getName();
                write("\tMOV AX," + name +"\t;line " + to_string(node->getSLine()));
                write("\tCALL print_output");
                write("\tCALL new_line");
            }
            else {
                int offset = findLocalOffset(node->getChild(2)->getName());
                int paramOffset = findFinalParamOffset(node->getChild(2)->getName());
                cout << "LINE 649, offset: " << offset << endl;
                write("\tPUSH BP \t\t;line " + to_string(node->getSLine()));
                if(ifParam(node->getChild(2)->getName())) 
                    write("\tMOV BX, " + to_string(paramOffset));
                else 
                    write("\tMOV BX, " + to_string(offset));
                
                // write("\t name -> " + node->getChild(2)->getName());
                write("\tADD BP,BX");
                write("\tMOV AX,[BP]");
                write("\tCALL print_output");
                write("\tCALL new_line");
                write("\tPOP BP");
                }

        }

        else if(str == "declaration_list : declaration_list COMMA ID ") {
            if(nowFunc != "") {
            name = node->getChild(2)->getName();
            // cout << "HELLOOO" << name << endl;

    
            
           
            int tmp = -findOffset(nowFunc) + currentOffset;
            currentOffset +=2;
            functionVariableOffsets.push_back(make_pair(name,tmp));
            codeGenerate(node->getChild(0),node->getName());

            }
        }

        else if(str == "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE " ) {
            if(nowFunc != "") {

            name = node->getChild(2)->getName();
            // cout << "LINE 671 " << node->getChild(5)->getName() << endl;
            int sz = std::stoi(node->getChild(4)->getName());
            
            int tmp = -findOffset(nowFunc) + currentOffset;
            currentOffset += 2*sz;
            functionVariableOffsets.push_back(make_pair(name,tmp));
            codeGenerate(node->getChild(0),node->getName());
            }

        }

        else if(str == "declaration_list : ID ") {
            if(nowFunc != "") {
            name = node->getChild(0)->getName();
            
            int tmp = -findOffset(nowFunc) + currentOffset;
            currentOffset += 2;
            functionVariableOffsets.push_back(make_pair(name,tmp));
           

            }
        }

        else if(str == "declaration_list : ID LSQUARE CONST_INT RSQUARE ") {
            if(nowFunc != "") {
            name = node->getChild(0)->getName();
            // cout << "LINE 687 " << node->getChild(2)->getName() << endl;
            int sz = std::stoi(node->getChild(2)->getName());
           
            int tmp = -findOffset(nowFunc) + currentOffset;
            currentOffset += 2*sz;
            functionVariableOffsets.push_back(make_pair(name,tmp));
        }
        }

        else if(str == "statement : RETURN expression SEMICOLON ") {
            codeGenerate(node->getChild(1),node->getName());
            write("\tMOV DX,CX\t;line " + to_string(node->getSLine()));
            write("\tJMP exit_" + nowFunc );
        }

        else if(str == "expression_statement : SEMICOLON ") {
            //do nothing
        }

        else if(str == "expression_statement : expression SEMICOLON ") {
            node->getChild(0)->isCondition = node->isCondition;
            node->getChild(0)->trueLabel = node->trueLabel;
            node->getChild(0)->falseLabel = node->falseLabel;
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "variable : ID ") {
            string name = node->getChild(0)->getName();
            bool check = ifGlobal(name);

            bool check2 = ifParam(name);

            
            
            if(check == false || check2 == true) {
                int offset = findLocalOffset(name);
                
                write("\tPUSH BP\t\t;line" + to_string(node->getSLine()));

                cout << "LINE 761: " <<  node->getSLine() << " " << name << " " << check2 << " " << findFinalParamOffset(name) << endl;
             
                
                if(check2 == true) 
                    write("\tMOV BX, " + to_string(findFinalParamOffset(name)));
                else if(check2 == false) 
                    write("\tMOV BX, " + to_string(offset));
                write("\tADD BP,BX");
            }
        }

        else if(str == "variable : ID LSQUARE expression RSQUARE ") {
            codeGenerate(node->getChild(2),node->getName());
            string name = node->getChild(0)->getName();
            bool check = ifGlobal(name);

            if(check) {
                write("\tLEA SI, " + name + "\t\t;line " + to_string(node->getSLine()));
                write("\tADD SI, CX");
                write("\tADD SI, CX");
                /////notice/////
                write("\tPUSH BP");
                write("\tMOV BX, SI");
            }
            else 
            {
                int offset = findLocalOffset(name);
                write("\tPUSH BP\t\t;line" + to_string(node->getSLine()));
                write("\tMOV BX,CX");
                write("\tADD BX,BX");
                write("\tADD BX, " + to_string(offset));
                write("\tADD BP,BX");
            }
        }

        else if(str == "expression : logic_expression ") {
            
            node->getChild(0)->isCondition = node->isCondition;
            node->getChild(0)->trueLabel = node->trueLabel;
            node->getChild(0)->falseLabel = node->falseLabel;
            // cout << "line 750, " << node->getChild(0)->getName() << endl;
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "expression : variable ASSIGNOP logic_expression ") {
            // cout << node->getSLine() << endl;
            // cout << "LINE 757 " << node->getNumberOfChildren() << endl;
            
            cout << "line 681, sline: " << node->getSLine() << " " << node->getName() << endl;
            codeGenerate(node->getChild(2),node->getName());
            node->getChild(0)->isCondition = false;
            node->getChild(2)->isCondition = false;

            bool check = ifGlobal(node->getChild(0)->getName());

            cout << "line 697, " << check << " " << node->getChild(0)->getName() << " " << node->getChild(0)->getArraySize() << endl; 

            cout << "line 740, " << node->getSLine() << " " << ifParam(node->getChild(0)->getName()) << endl;

            bool check2 = ifParam(node->getChild(0)->getName());


            if(check == true && node->getChild(0)->getArraySize() < 0 && !check2 ) {

                cout << "HERHERHEHREHRHEH" << node->getSLine() << endl;
                
                codeGenerate(node->getChild(0),node->getName());
                write("\tMOV " + node->getChild(0)->getName() + ",CX");
            }

            else 
             
            {
                write("\tPUSH CX");
                codeGenerate(node->getChild(0),node->getName());
                write("\tPOP AX");
                write("\tPOP CX");
                write("\tMOV [BP],CX");
                write("\tMOV BP,AX");

             }

             if(node->isCondition == true) 
               write("\tJMP " + node->trueLabel);
        }

        else if(str == "logic_expression : rel_expression ") {
            node->getChild(0)->isCondition = node->isCondition;
            node->getChild(0)->trueLabel = node->trueLabel;
            node->getChild(0)->falseLabel = node->falseLabel;
            cout << "LINE 727, " << node->getChild(0)->getName() << endl;
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "logic_expression : rel_expression LOGICOP rel_expression ") {
            node->getChild(0)->isCondition = node->isCondition;
            node->getChild(2)->isCondition = node->isCondition;

            if(node->getChild(1)->getName() == "&&") {
                node->getChild(0)->trueLabel = labelCreate2() + "_true:";
                node->getChild(0)->falseLabel = node->falseLabel;
                node->getChild(2)->trueLabel = node->trueLabel;
                node->getChild(2)->falseLabel = node->falseLabel; 
            }
            else if(node->getChild(1)->getName() == "||" ) {
                node->getChild(0)->trueLabel = node->trueLabel;
                node->getChild(0)->falseLabel = labelCreate2() + "_false:";
                node->getChild(2)->trueLabel = node->trueLabel;
                node->getChild(2)->falseLabel = node->falseLabel;
            }
            else { }

            codeGenerate(node->getChild(0),node->getName());

            if(node->isCondition == true) {
                if(node->getChild(1)->getName() == "&&") 
                    write(node->getChild(0)->trueLabel + ": \n ");
                
                else if(node->getChild(1)->getName() == "||") 
                    write(node->getChild(0)->falseLabel + ": \n ");
            }
            else 
             write("\tPUSH CX");

            codeGenerate(node->getChild(2),node->getName());

            if(node->isCondition == false) {
                write("\tPOP AX");

                string tmp1 = labelCreate();
                string tmp2 = labelCreate();
                string tmp3 = labelCreate();
                string tmp4 = labelCreate();
                
                if(node->getChild(1)->getName() == "&&") {
                    

                    write("\tCMP AX, 0");
                    write("\tJE " + tmp1);
                    write("\tJCXZ " + tmp1);
                    write("\t JMP " + tmp2);
                    write(tmp1 + ": \n ");
                    write("\tMOV CX, 0");
                    write("\tJMP " + tmp3);
                    write(tmp2 + ": \n ");
                    write("\tMOV CX, 1");
                    write(tmp3 + ": \n ");
                }
                 else if(node->getChild(1)->getName() == "||") {
                    write("\tCMP AX, 0");
                    write("\tJE " + tmp1);
                    write("\tJMP " + tmp2);
                    write(tmp1 + ": \n ");
                    write("\tJCXZ " + tmp3);
                    write(tmp2 + ": \n ");
                    write("\tMOV CX, 1");
                    write("\tJMP " + tmp4);
                    write(tmp3 + ": \n ");
                    write("\tMOV CX, 0");
                    write(tmp4 + ": \n ");
                }

            }
        }

        else if(str == "rel_expression : simple_expression ") {
            // cout << node->getSLine() << " " "MUHAHAHHAHAHA" << endl;
            node->getChild(0)->isCondition = node->isCondition;
            node->getChild(0)->trueLabel = node->trueLabel;
            node->getChild(0)->falseLabel = node->falseLabel;
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "rel_expression : simple_expression RELOP simple_expression ") {
            codeGenerate(node->getChild(0),node->getName());
            write("\tPUSH CX");
            codeGenerate(node->getChild(2),node->getName());
            
            write("\tPOP AX");
            write("\tCMP AX,CX");
            if(node->trueLabel == "") node->trueLabel = labelCreate2();
            if(node->falseLabel == "") node->falseLabel = labelCreate2();
            string convertedOperation = convertOperation(node->getChild(1)->getName());
            write("\t" + convertedOperation + " " + node->trueLabel);
            write("\tJMP " + node->falseLabel);

            if(node->isCondition == true) {}
            else {
                string tmp = labelCreate2();
                write(node->trueLabel + ": \n ");
                write("\tMOV CX, 1");
                write("\tJMP " + tmp);
                write(node->falseLabel + ": \n ");
                write("\tMOV CX, 0");
                write(tmp + ": \n ");
        }


        }

        else if(str == "simple_expression : term " || str == "term : unary_expression " || str == "unary_expression : factor ") {
            node->getChild(0)->isCondition = node->isCondition;
            node->getChild(0)->trueLabel = node->trueLabel;
            node->getChild(0)->falseLabel = node->falseLabel;
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "simple_expression : simple_expression ADDOP term " ) {
            codeGenerate(node->getChild(0),node->getName());
            write("\tPUSH CX");
            codeGenerate(node->getChild(2),node->getName());
            write("\tPOP AX ");
            if(node->getChild(1)->getName() == "+") 
                write("\tADD CX,AX");
            else if(node->getChild(1)->getName() == "-") 
                {
                    write("\tSUB AX,CX");
                    write("\tMOV CX,AX");
                }
            
            if(node->isCondition) {
                write("\tJCXZ" + node->falseLabel);
                write("\tJMP " + node->trueLabel);
            }
        }

        else if(str == "term : term MULOP unary_expression ") {
            codeGenerate(node->getChild(0),node->getName());
            write("\tPUSH CX");
            codeGenerate(node->getChild(2),node->getName());
            write("\tPOP AX");

            if(node->getChild(1)->getName() == "*") 
             {
                write("\tIMUL CX");
                write("\tMOV CX,AX");

             }

             else if(node->getChild(1)->getName() == "%") 
             {
                write("\tCWD");
                write("\tIDIV CX");
                write("\tMOV CX,DX");
             }
           
            else if(node->getChild(1)->getName() == "/") 
             {
                write("\tCWD");
                write("\tIDIV CX");
                write("\tMOV CX,AX");
             }

             else {}

            if(node->isCondition) {
                write("\tJCXZ " + node->falseLabel);
                write("\tJMP " + node->trueLabel);
            }
        }

        else if(str == "unary_expression : ADDOP unary_expression ") {
            node->getChild(1)->isCondition = node->isCondition;
            node->getChild(1)->trueLabel = node->trueLabel;
            node->getChild(1)->falseLabel = node->falseLabel;
            codeGenerate(node->getChild(1),node->getName());

            if(node->getChild(0)->getName() == "-") 
                write("\tNEG CX");
        }

        else if(str == "unary_expression : NOT unary_expression ") {
            node->getChild(1)->isCondition = node->isCondition;
            node->getChild(1)->trueLabel = node->trueLabel;
            node->getChild(1)->falseLabel = node->falseLabel;
            codeGenerate(node->getChild(1),node->getName());

            if(node->isCondition == false) {
                string tmp1 = labelCreate2();
                string tmp2 = labelCreate2();

                write("\tJCXZ " + tmp1);
                write("\tMOV CX, 0");
                write("\tJMP " + tmp2);
                write(tmp1 + ": \n ");
                write("\tMOV CX, 1");
                write(tmp2 + ": \n ");
            }
            
        }

        else if(str == "unary_expression : factor ") {
            node->getChild(0)->isCondition = node->isCondition;
            node->getChild(0)->trueLabel = node->trueLabel;
            node->getChild(0)->falseLabel = node->falseLabel;
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "factor : variable ") {
            codeGenerate(node->getChild(0),node->getName());
            bool check = ifGlobal(node->getChild(0)->getName());
            bool check2 = ifParam(node->getChild(0)->getName());

            if(check == true && node->getChild(0)->getArraySize() < 0 && check2 == false)  {
                write("\tMOV CX," + node->getChild(0)->getName());
            }
            else {
                write("\tMOV CX,[BP]");
                write("\tPOP BP");
            }

            if(node->isCondition) {
                write("\tJCXZ " + node->falseLabel);
                write("\tJMP " + node->trueLabel);
            }
        }

        else if(str == "factor : ID LPAREN argument_list RPAREN ") {
            codeGenerate(node->getChild(0),node->getName());
            codeGenerate(node->getChild(2),node->getName());

            int totalOffset = findTotalParameterOffset(node->getChild(0)->getName());

            write("\tCALL " + node->getChild(0)->getName());
            write("\tMOV CX,DX");
            write("\tADD SP," + to_string(totalOffset));
            if(node->isCondition) {
                write("\tJCXZ " + node->falseLabel);
                write("\tJMP " + node->trueLabel);
            }
        }

        else if(str == "factor : LPAREN expression RPAREN ") {
            codeGenerate(node->getChild(1),node->getName());
            if(node->isCondition) {
                write("\tJCXZ " + node->falseLabel);
                write("\tJMP " + node->trueLabel);
            }
        }

        else if(str == "factor : CONST_INT " || str == "factor : CONST_FLOAT ") {
            cout << "line 905 " << str << endl;
            codeGenerate(node->getChild(0),node->getName());
            write("\tMOV CX, " + node->getChild(0)->getName() + "\t;line " + to_string(node->getSLine()));
            if(node->isCondition) {
                write("\tJCXZ " + node->falseLabel);
                write("\tJMP " + node->trueLabel);
            }
        }

        else if(str == "factor : variable INCOP ") {
            codeGenerate(node->getChild(0),node->getName());
            bool check = ifGlobal(node->getChild(0)->getName());

            

            if(check == true && node->getChild(0)->getArraySize() < 0) 
                write("\tMOV CX, " + node->getChild(0)->getName() + "\t;line " + to_string(node->getSLine()));
            else {
                write("\tMOV CX,[BP] \t;line " + to_string(node->getSLine()));
            }

            write("\tMOV AX,CX");
            write("\tINC CX");
         

            if(check == true) 
                write("\tMOV " + node->getChild(0)->getName() + ",CX");
            else {
                write("\tMOV [BP],CX");
                write("\tPOP BP");
            }

            write("\tMOV CX,AX");
            if(node->isCondition) {
                write("\tJCXZ " + node->falseLabel);
                write("\tJMP " + node->trueLabel);
            }
        }

        else if(str == "factor : variable DECOP ") {
            codeGenerate(node->getChild(0),node->getName());
            bool check = ifGlobal(node->getChild(0)->getName());

            

            if(check == true && node->getChild(0)->getArraySize() < 0) 
                write("\tMOV CX, " + node->getChild(0)->getName() + "\t;line " + to_string(node->getSLine()));
            else {
                write("\tMOV CX,[BP]");
            }

            write("\tMOV AX,CX");
            write("\tDEC CX");
          

            if(check == true) 
                write("\tMOV " + node->getChild(0)->getName() + ",CX");
            else {
                write("\tMOV [BP],CX");
                write("\tPOP BP");
            }

            write("\tMOV CX,AX");
            if(node->isCondition) {
                write("\tJCXZ " + node->falseLabel);
                write("\tJMP " + node->trueLabel);
            }
        }

        else if(str == "argument_list : arguments ") {
            codeGenerate(node->getChild(0),node->getName());
        }

        else if(str == "arguments : arguments COMMA logic_expression ") {
            codeGenerate(node->getChild(0),node->getName());
            codeGenerate(node->getChild(2),node->getName());
            write("\tPUSH CX");
        }

        else if(str == "arguments : logic_expression " ) {
            codeGenerate(node->getChild(0),node->getName());
            write("\tPUSH CX");
        }

        else {
            // for(int i = 0 ; i<node->getNumberOfChildren() ; i++)
            //     codeGenerate(node->getChild(i),node->getName());
        }
    }

    bool checkLine(char c) {
        if(c == '\n' || c == ' ' || c== '\t' || c == ',' || c == ':' || c == ';' )
             return true;
        return false;
    }

    void optimiseCode() {
        ifstream tmpIn("2005089_code.asm");
        string word = "";
        vector <string> words;
        bool chk = tmpIn.is_open();

        if(chk) {
            while(getline(tmpIn,line)) {
                word = "";
                words.clear();
                int i = 0;
                while(i<line.size() ) {
                    if(checkLine(line[i])) {
                        if(word.size() > 0) 
                            words.push_back(word);
                        word = "";
                    }
                    else 
                         word += line[i];
                    i++;
                }

                if(word.size() > 0)
                    words.push_back(word);
                words.push_back(line + '\n');
                optCode.push_back(words);
              
                }
        }

           for(int i = 0 ; i<optCode.size() ; i++) {
             for(int j = 0; j<optCode[i].size(); j++) 
                 if(optCode[i][j] == "\f") 
                    cout << "NOOOO" << endl;
         }

        int it = INT_MAX;

        

        while(it > optCode.size()) {
            it = optCode.size();
            vector<vector<string>> vect1,vect2,vect3,vect4;

            for(int i = 0 ; i<optCode.size() ; i++) {
                if((optCode[i][0] == "ADD" || optCode[i][0] == "SUB") && optCode[i][2] == "0")
                    continue;
                if(i<optCode.size() - 1 && optCode[i][0] == "PUSH" && optCode[i+1][0] == "POP") {
                    if(optCode[i][1] != optCode[i+1][i]) 
                        vect1.push_back({"MOV",optCode[i+1][1],optCode[i][1],"\tMOV "+optCode[i+1][1]+", "+optCode[i][1]+"\n"});
                   i++;
                   continue;
                }

                vect1.push_back(optCode[i]);
            }

            cout << "Line 1014 " << vect1.size() << endl;

        for(int i = 0 ; i<vect1.size() ; i++) {
             for(int j = 0; j<vect1[i].size(); j++) 
                 if(vect1[i][j] == "\f")
                 cout << "noo" << endl;
         }

       

            

            for(int i = 0 ; i<vect1.size() ; i++) {
                if(i<vect1.size() - 1 && vect1[i][0] == "MOV" && vect1[i+1][0] == "MOV" && vect1[i][2] == vect1[i+1][1] && 
                vect1[i][1] == vect1[i+1][2]) {
                    i++;
                    continue;
                }

                

                vect2.push_back(vect1[i]);
            }

             for(int i = 0 ; i<vect1.size() ; i++) {
             for(int j = 0; j<vect1[i].size(); j++) 
                 if(vect1[i][j] == "\f") 
                    cout << "noo" << endl;
         }

            for(int i = 0 ; i<vect2.size() ; i++) {
                if(i<vect2.size() - 1 && vect2[i][0] == "MOV" && vect2[i+1][0] == "POP" && vect2[i][1] == vect2[i+1][1])
                    continue;
                vect3.push_back(vect2[i]);
            }

            optCode = vect3;
            }

            ofstream optOut("2005089_optimized_code.asm");
            for(int i = 0 ; i < optCode.size() ; i++)
                optOut << optCode[i][optCode[i].size()-1];

        

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
    root = tmp;
    tmp->setStringTree("start : program ");
    tmp->setSpace(0);
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    tmp->printParseTree(0,parseOut);
  
    $$ = tmp;
    printLog("start : program ");
    cout << "TRAVERSING" ;
    // cout << findTotalParameterOffset("bar") << endl;
    traverse($$);
   
    cout << "\n\n\n\nTRAVERSING END" << endl;

    codeGenerate($$,"start");
    optimiseCode();
    // if(printlnFlag == true) 
    //     printNewLine();

    // write("END main");
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
    

} | unit {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "PROGRAM");
    tmp->setStringTree("program : unit ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("program : unit");
  
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
    ftype = type;

     vector<int> v;
     functionVariableNumbers[fname] = v;
     functionParameterNumbers[fname] = v;
     globalVariableFlag = false;

}

emb2 : {
    SymbolInfo* tmp = st->lookUp(fname,logOut);

  if(tmp == NULL)
    {
        
         insertFunction(fname, ftype, -2);
         
    }
    else
     {
       
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
    // cout << tmp->getName() << endl;
   
   
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
    pushToParameterList($4->getName(),$3->getName());

     cout << "LINE 1472, fname : " << fname << endl;
     
    auto it = functionParameterNumbers.find(fname);
    if(it != functionParameterNumbers.end())
    {
             it->second.push_back((1));
     
    }
     cout << it->second.size() << endl;


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

     cout << "LINE 1472, fname : " << fname << endl;
    auto it = functionParameterNumbers.find(fname);
        if(it != functionParameterNumbers.end())
        {
             it->second.push_back((1));
     
        }
    cout << it->second.size() << endl;

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


     cout << "LINE 1472, fname : " << fname << endl;
    auto it = functionParameterNumbers.find(fname);
    if(it != functionParameterNumbers.end())
        {
             it->second.push_back((1));
     
        }
         cout << it->second.size() << endl;
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
    

    cout << "LINE 1472, fname : " << fname << endl;
    auto it = functionParameterNumbers.find(fname);
    if(it != functionParameterNumbers.end())
    {
             it->second.push_back((1));
     
    }
     cout << it->second.size() << endl;
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
           
            // //////errorOut << "Line# " << lineCount << ": Conflicting types for '" << fname << "'" << endl;
            // errorCount++;
        }
        else 
        {
            int flag = 0;
          
            if(parameterList.size() != tmp->getNumberOfParameters())
            {
                // //////errorOut << "Line# " << lineCount << ": Conflicting types for '"<< fname << "'" << endl;
                // errorCount++;
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
                    // //////errorOut << "Line# " << lineCount << ": Error of function123 ----- " << fname << endl;
                    // errorCount++;
                }
             }

            }
            
            
        }
     }   
    else 
    {
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

        str = $1->getName();
        cout << "LINE 490" << str << endl;
        for(int i =  0 ; i<variableList.size() ; i++)
            insertVariable(str,variableList[i].name,variableList[i].varSize);
    

    variableList.clear();


    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("var_declaration : type_specifier declaration_list SEMICOLON  ");

    if(st->getCurrentScopeID() == 1) 
     tmp->isGlobal = true;



  
};

type_specifier: INT {
    type = "INT";
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "TYPE_SPECIFIER");
    tmp->setStringTree("type_specifier : INT ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false); 
    $$ = tmp;
    printLog("type_specifier	: INT ");
} | VOID {
    type = "VOID";
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "TYPE_SPECIFIER");
    tmp->setStringTree("type_specifier : VOID ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false); 
    $$ = tmp;
    printLog("type_specifier    : VOID ");
}
| FLOAT {
    type = "FLOAT";
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "TYPE_SPECIFIER");
    tmp->setStringTree("type_specifier : FLOAT ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false); 
    $$ = tmp;
    printLog("type_specifier	: FLOAT  ");
};


id : ID {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "ID");
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
    
    if(globalVariableFlag == true) 
     globalVariableList.push_back(tempVariable);
    else 
     {
     
        auto it = functionVariableNumbers.find(fname);
        if(it != functionVariableNumbers.end())
        {
             it->second.push_back((1));
     
        }

     }

     if(st->getCurrentScopeID() == 1)
      $3->isGlobal = true;
    
   
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

   
  
    tempVariable.name = $3->getName();
    tempVariable.varSize = stoi($5->getName());
    variableList.push_back(tempVariable);

    if(globalVariableFlag == true) 
     globalVariableList.push_back(tempVariable);
     else {



        auto it = functionVariableNumbers.find(fname);
        if(it != functionVariableNumbers.end())
        {
             it->second.push_back(stoi($5->getName()));
        
        }

     }

     if(st->getCurrentScopeID() == 1)
      $3->isGlobal = true;

   
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

   if(globalVariableFlag == true) 
     globalVariableList.push_back(tempVariable);
     else {

        auto it = functionVariableNumbers.find(fname);
        if(it != functionVariableNumbers.end())
        {
          it->second.push_back(1);
           
        }

     }

        if(st->getCurrentScopeID() == 1)
        $1->isGlobal = true;
   

   
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

   if(globalVariableFlag == true) 
     globalVariableList.push_back(tempVariable);
    else {
 
        auto it = functionVariableNumbers.find(fname);

        if(it != functionVariableNumbers.end())
        {
            it->second.push_back(stoi($3->getName()));
       
        }

     }

     if(st->getCurrentScopeID() == 1)
      $3->isGlobal = true;
  

   
}

statements : statements statement {
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName(), "STATEMENTS");
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
    SymbolInfo *tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "STATEMENT");
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
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
    }

} | PRINTLN LPAREN ID RPAREN SEMICOLON {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + " " + $5->getName() /// CHECK
    , "STATEMENT");
    tmp->setStringTree("statement : PRINTLN LPAREN ID RPAREN SEMICOLON ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($5->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->addChild($4);
    tmp->addChild($5);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("statement : PRINTLN LPAREN ID RPAREN SEMICOLON ");
    printlnFlag = true;

    auto a = st->lookUp($3->getName(),logOut);
    if(a->isGlobal)
     tmp->isGlobal = true;
    else 
     tmp->isGlobal = false;
    

   } | FOR LPAREN expression_statement emb5 emb6 expression_statement emb5 emb6 expression emb5 emb6 RPAREN statement {
        SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + 
        $3->getName() + " " + $6->getName() + " " + $9->getName() + " " + $12->getName() + " " + $13->getName(), "STATEMENT");
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
        SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $5->getName() + " " + $7->getName(), "STATEMENT");
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
        SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $5->getName() + " " + $7->getName() + " " + $8->getName() + " " + $9->getName(), "STATEMENT");
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
        SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $5->getName() + " " + $7->getName(), "STATEMENT");
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
            //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
            errorCount++;
        }
};
    
expression_statement: SEMICOLON {
    SymbolInfo *tmp = new SymbolInfo($1->getName(), "EXPRESSION_STATEMENT");
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
 
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "VARIABLE");
    // cout << "LINE 1606 " << $1->getName() << endl;
    tmp->setStringTree("variable : ID ");
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("variable : ID ");
    name = $1->getName();  ///// recheck - 2 ///////
    SymbolInfo* tmp2 = st->lookUp($1->getName(),logOut);

    tempVariable.name = $1->getName();
    tempVariable.varSize = -1;
    allVarList.push_back(tempVariable);

    SymbolInfo* a = st->lookUp($1->getName(),logOut);
    tmp->isGlobal = a->isGlobal;

   

    if(tmp2 == NULL)
    {
        // //////errorOut << "Line# " << lineCount << ": Undeclared variable '" << $1->getName() << "'" << endl;
        // errorCount++;
        // tmp->setDataType("FLOAT");
    }
    else
    {
        
        if(tmp2->getDataType()=="VOID"){}
            // tmp->setDataType("FLOAT");
        else
            tmp->setDataType(tmp2->getDataType());
         
    }

} | ID LSQUARE expression RSQUARE {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName() + " " + $4->getName(), "VARIABLE");
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


    tempVariable.name = $1->getName();
    tempVariable.varSize = stoi($3->getName());
    allVarList.push_back(tempVariable);

     SymbolInfo* a = st->lookUp($1->getName(),logOut);
    tmp->isGlobal = a->isGlobal;

   

    SymbolInfo* tmp2 = st->lookUp($1->getName(),logOut);

    if($3->getDataType() != "INT" && $3->getDataType() != "CONST_INT")
    {
        // //////errorOut << "Line# " << lineCount << ": Array subscript is not an integer" << endl;
        // errorCount++;
    }

    if(tmp2 == NULL)
    {
        // //////errorOut << "Line " << lineCount << ": Undeclared variable '" << $1->getName() << "'" << endl;
        // errorCount++;
        // tmp->setDataType("FLOAT");
    }
    else
    {
        if(tmp2->getArraySize() > 0) 
        {
            if(tmp2->getDataType()=="VOID"){}
                // tmp->setDataType("FLOAT");
            else
                tmp->setDataType(tmp2->getDataType());
        }
        else 
        {
            // //////errorOut << "Line# " << lineCount << ": '" << $1->getName() << "' is not an array" << endl;
            // errorCount++;
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
    
    tmp->setDataType(type);
    tmp->setIsLeaf(false);
    $$ = tmp;
    printLog("expression : logic_expression ");
    

} | variable ASSIGNOP logic_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "EXPRESSION");
    tmp->setStringTree("expression : variable ASSIGNOP logic_expression ");
    
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
   
    tmp->setIsLeaf(false);
    $$ = tmp;

    // cout << "line 1709" << tmp->getName() << " " << tmp->getNumberOfChildren() << endl;
    printLog("expression : variable ASSIGNOP logic_expression ");

    // cout << "LINE 996 and lineCount " << lineCount  << $1->getDataType() << ", name " << $1->getName() << "--" << $3->getDataType() << endl;
    // cout << "LINE 1054 and lineCount " << lineCount << $3->getName() << endl;
    
    if($1->getDataType() != $3->getDataType())
    {
        
        if($1->getDataType() == "INT" && $3->getDataType() == "FLOAT")
        {
            string msg = ": Warning: possible loss of data in assignment of "+ $3->getDataType() + " to " + $1->getDataType();
            //////errorOut << "Line# " << lineCount << msg << endl;
            errorCount++;
        }
        else
        {    
            
        }
       
    }



    if($3->getDataType() == "VOID" ) 
    {
        // //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        // errorCount++;
       
    }

    type = $1->getDataType();
    tmp->setDataType(type);
    
} 

logic_expression: rel_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName(),"LOGIC_EXPRESSION");
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
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "LOGIC_EXPRESSION");
     //// recheck-2 ////
    tmp->setStringTree("logic_expression : rel_expression LOGICOP rel_expression ");
    tmp->setDataType($1->getDataType());

    cout << "LINE 1047" << $1->getDataType() << " " << $3->getDataType() << endl;

    if($1->getDataType() == "VOID")
    {
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $1->setDataType("FLOAT");
    }

    if($3->getDataType() == "VOID")
    {
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $3->setDataType("FLOAT");
    }


    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    tmp->setIsLeaf(false);
    // type = $1->getDataType();   
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
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $1->setDataType("FLOAT");
    }

    if($3->getDataType() == "VOID")
    {
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $3->setDataType("FLOAT");
    }


    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);
    // type = $1->getDataType();
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
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $1->setDataType("FLOAT");
    }

    if($3->getDataType() == "VOID")
    {
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $3->setDataType("FLOAT");
    }

    if($1->getDataType() == "VOID" || $3->getDataType() == "VOID")
    {
        // tmp->setDataType("FLOAT");
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

    cout << "LINE 1199" << $1->getDataType() << endl;
    cout << "LINE 1199" << $3->getDataType() << endl;

    $$ = tmp;

    cout << "LINE 1217 " << $1->getDataType() << " " << $3->getDataType() << endl;

    if($1->getDataType() == "VOID" || $1->getDataType() == "" )
    {
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $1->setDataType("FLOAT");
    }

    if($3->getDataType() == "VOID" || $3->getDataType() == "")
    {
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $3->setDataType("FLOAT");
    }

    cout << "NOOOOOOOOO lineCount " << lineCount << "    1" << $1->getDataType() << "1   1" << $3->getDataType() << endl;
   

    if ($2->getName() == "%" && (($1->getDataType() != "INT") 
     || ($3->getDataType() != "INT"))) {
        // //////errorOut << $1->getDataType() << " " << $3->getDataType() << endl;

        
        if(($1->getDataType() == "INT" && $3->getDataType() == "FLOAT" ) ||($3->getDataType() == "INT" && $1->getDataType() == "FLOAT" ) )
        {
            //////errorOut << "Line# " << lineCount << ": Operands of modulus must be integers " << endl;
            errorCount++;
        }
      
   
    //  $$->setDataType("INT"); // recover
} else if ($2->getName() == "%" && ($1->getDataType() != "FLOAT" && $3->getDataType() != "FLOAT")) {
    // $$->setDataType("FLOAT");
} else {
    $$->setDataType($1->getDataType());
}

if ($3->getName() == "0" && ($2->getName() == "%" || $2->getName() == "/")) {
    // divide by zero error
    //////errorOut << "Line# " << lineCount << ": Warning: division by zero i=0f=1Const=0" << endl;
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
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $2->setDataType("FLOAT");
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
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $2->setDataType("FLOAT");
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
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        errorCount++;
        // $2->setDataType("FLOAT"); /// recheck - 2 $$ or $2 ///
    }
} | CONST_INT {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "FACTOR");
    // cout << "MEOWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW" << endl;
    tmp->setStringTree("factor : CONST_INT ");
    tmp->setDataType("INT"); /// notice int or const_int?
    tmp->setSLine($1->getSLine());
    tmp->setELine($1->getELine());
    tmp->addChild($1);
    $$ = tmp;
    printLog("factor : CONST_INT ");
} | CONST_FLOAT {
    SymbolInfo* tmp = new SymbolInfo($1->getName(), "FACTOR");
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

        
        // cout << "LINE 1406, lineCount " << lineCount << " " << $1->getDataType() << endl; 
        // cout << "LINE 1407, lineCount " << lineCount << " " << tmp->getName() << endl;

        // if($1->getDataType() == "" && lineCount == 58)
        // {
        //     //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression " << endl;
        //     errorCount++;
        // }






        
        
        SymbolInfo* tmp2 = st->lookUp($1->getName(),logOut);

        if(tmp2 == NULL)
        {
            //////errorOut << "Line# " << lineCount << ": Undeclared function '" << $1->getName() <<"'" << endl;
            errorCount++;
           

            // tmp->setDataType("FLOAT");
        }
        else if(tmp2->getArraySize() != -3)
        {
            //////errorOut << "Line# " << lineCount << "Undefined function '" << $1->getName() << "'" ;
            errorCount++;
            // tmp->setDataType("FLOAT");
        }
        else 
        {
            if(tmp2->getNumberOfParameters() == 1 && argumentList.size() == 0 && tmp2->getParam(0).getParameterType() == "VOID")
            {
                tmp->getDataType() = tmp2->getDataType();
            }
           if(tmp2->getNumberOfParameters() > argumentList.size())
           {
            cout << "LINE 1370 " << tmp2->getNumberOfParameters() << endl;
            for(int i = 0 ; i<tmp2->getNumberOfParameters(); i++)
            {
                cout << "LINE 1373 " << tmp2->getParam(i).getParameterName() << " " << tmp2->getParam(i).getParameterType() << endl;
            }

            cout << "LINE 1376 " << argumentList.size() << endl;

            for(int i = 0 ; i<argumentList.size(); i++)
            {
                cout << "LINE 1379 " << argumentList[i] << endl;
            }

            //////errorOut << "Line# " << lineCount << ": Too few arguments to function '" << $1->getName() << "'" << endl;
            errorCount++;
           }
           else if(tmp2->getNumberOfParameters() < argumentList.size())
           {
            cout << "LINE 1388" << tmp2->getNumberOfParameters() << " " << argumentList.size() << endl;
            cout << "LINE 1389 " << tmp2->getNumberOfParameters() << endl;
            for(int i = 0 ; i<tmp2->getNumberOfParameters(); i++)
            {
                cout << "LINE 1389 " << tmp2->getParam(i).getParameterName() << " " << tmp2->getParam(i).getParameterType() << endl;
            }

            cout << "LINE 1395 " << argumentList.size() << endl;

            for(int i = 0 ; i<argumentList.size(); i++)
            {
                cout << "LINE 1395 " << argumentList[i] << endl;
            }
            //////errorOut << "Line# " << lineCount << ": Too many arguments to function '"  << $1->getName() << "'" << endl;
            errorCount++;
           }
           else 
           {
            cout << "HEREEEEEEEEEEEEEEEEEEEEEE" << endl;
              for(int i = 0 ; i<tmp2->getNumberOfParameters(); i++)
            {
                cout << "LINE 1432 " << tmp2->getParam(i).getParameterName() << " " << tmp2->getParam(i).getParameterType() << endl;
            }

           

            for(int i = 0 ; i<argumentList.size(); i++)
            {
                cout << "LINE 1493 " << argumentList[i] << endl;
            }
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
                //////errorOut << "Line# " << lineCount << ": Type mismatch for argument " << error[j] << " of '" << $1->getName() << "'" << endl;
                errorCount++;
             }
             tmp->setDataType(tmp2->getDataType());
            //  cout << "LINE 1518,lineCount " << lineCount << tmp->getDataType() << " " << tmp2->getDataType() << endl;
               
           }
        }

        argumentList.clear();
        tmp->setIsLeaf(false);
        $$ = tmp;
        // cout << "LINE 1549, lineCount " << lineCount << $$->getDataType()  << endl;
        
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
    cout << "SIUUU" << endl;
    SymbolInfo* tmp = new SymbolInfo("", "ARGUMENT_LIST");
    printLog("argument_list : ");
};

arguments : arguments COMMA logic_expression {
    SymbolInfo* tmp = new SymbolInfo($1->getName() + " " + $2->getName() + " " + $3->getName(), "ARGUMENTS");
    tmp->setStringTree("arguments : arguments COMMA logic_expression ");
    cout << "LINE 1583" << $1->getName() << " " << $3->getName() << endl;
    tmp->setSLine($1->getSLine());
    tmp->setELine($3->getELine());
    tmp->addChild($1);
    tmp->addChild($2);
    tmp->addChild($3);

    if($3->getDataType() == "VOID")
    {
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression  " << endl;
        errorCount++;
        // $3->setDataType("FLOAT");
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
        //////errorOut << "Line# " << lineCount << ": Void cannot be used in expression  " << endl;
        errorCount++;
        // $1->setDataType("FLOAT");
    } else 
    {
        $$->setDataType($1->getDataType());
    }

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


    /* logOut.open("2005089_logfile.txt") ;  */
    
    /* parseOut.open("2005089_parsefile.txt"); */
    asmCode.open("2005089_code.asm");
    /* bufferOut.open("2005089_bufferfile.txt"); */
   
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
   
    parseOut.close() ; 
    

     return 0 ; 
     
}





