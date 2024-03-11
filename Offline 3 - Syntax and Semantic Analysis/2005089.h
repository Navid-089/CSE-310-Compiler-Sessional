#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

using namespace std;

class SymbolInfo {
private:
  string name;
  string type;
  SymbolInfo *next;

  int sizeOfArray = -1; // >=0-> array; -1 -> variable; -2 -> function declaration, -3->function definition
  string dataType;

  string stringTree;
  int sLine;
  int eLine;
  bool isLeaf;
  int space;
  vector<SymbolInfo*> children;

  class parameterInfo {
  private:
    string parameterName;
    string parameterType;

  public:
    parameterInfo() {
      parameterName = "";
      parameterType = "";
    }

    parameterInfo(string parameterInfo, string parameterType) {
      this->parameterName = parameterInfo;
      this->parameterType = parameterType;
    }

    string getParameterName() { return parameterName; }
    string getParameterType() { return parameterType; }

    void setParameterName(string parameterName) {
      this->parameterName = parameterName;
    }
    void setParameterType(string parameterType) {
      this->parameterType = parameterType;
    }
  };
  

  vector<parameterInfo> functionParameters;

public:
  SymbolInfo() {
    name = "";
    type = "";
    next = NULL;
  }

  SymbolInfo(string name, string type) {
    this->name = name;
    this->type = type;
    next = NULL;
  }

  ~SymbolInfo() {
    // delete next;
    functionParameters.clear();
  }

  void setName(string name) { this->name = name; }

  void setType(string type) { this->type = type; }

  void setNext(SymbolInfo *next) { this->next = next; }

  void setArraySize(int size) { sizeOfArray = size; }

  void setDataType(string dataType) { this->dataType = dataType; }



  void setStringTree(string stringTree) { this->stringTree = stringTree; }

  void setSLine(int sLine) { this->sLine = sLine; }

  void setELine(int eLine) { this->eLine = eLine; }

  void setIsLeaf(bool isLeaf) { this->isLeaf = isLeaf; }

  void setSpace(int space) { this->space = space; }

  string getName() { return name; }

  string getType() { return type; }

  SymbolInfo *getNext() { return next; }

  void addParameterToFunction(string parameterName, string parameterType) {
    parameterInfo newParameter(parameterName, parameterType);
    functionParameters.push_back(newParameter);
  }

  int getNumberOfParameters() { return functionParameters.size(); }

  int getSpace() { return space; }

  parameterInfo getParam(int index) { return functionParameters[index]; }

  parameterInfo getParam(string parameterName) {
    for (int i = 0; i < functionParameters.size(); i++) {
      if (functionParameters[i].getParameterName() == parameterName) {
        return functionParameters[i];
      }
    }
    return parameterInfo();
  }

  int getArraySize() { return sizeOfArray; }

  string getDataType() { return dataType; }

  string getStringTree() { return stringTree; }

 int getNumberOfChildren() { return children.size(); }

  bool isArray() { return sizeOfArray >= 0; }

  bool isFunction() { return type == "FUNC";}

  bool isSameLine() { return sLine == eLine; }

  int getSLine() { return sLine; }
  int getELine() { return eLine; }

  void addChild(SymbolInfo *child) {
    children.push_back(child);
    child->setSpace(getSpace() + getNumberOfChildren());
    space++;
  }

  void printParseTree(int space, ofstream &out) {
    for (int i = 0; i < space; i++)
      out << " ";

    if (isLeaf == true) {
      out << getType() << " : " << getName() << "\t<Line: " << getSLine() << ">"
          << endl;
    } else {
      out << getStringTree() << "\t<Line: " << getSLine() << "-" << getELine()
          << ">" << endl;
      for (int i = 0; i < getNumberOfChildren(); i++)
        children[i]->printParseTree(space + 1, out);
    }
  }

  // friend ostream &operator<<(ostream &out, const SymbolInfo &syminfo) {
  //     out << "(" << syminfo.name << "," << syminfo.type << ")";
  //     return out;
  //   }
};


class ScopeTable {
private:
  string id;
  int size;
  int totalChildren ;

  ScopeTable *parentScope;
  SymbolInfo **bucketList;

public:
  ScopeTable() {}

ScopeTable(int size, ScopeTable *parentScope) {
    
    totalChildren = 0;
    string tmp = parentScope->getId();
    string tmp2 = to_string(parentScope->getTotalChildren() + 1);
    // cout << " HELLO " << endl;
    id = tmp + "." + tmp2;
    parentScope->setTotalChildren(parentScope->getTotalChildren() + 1);
    this->size = size;
    this->parentScope = parentScope;
    bucketList = new SymbolInfo *[size];

    for (int i = 0; i < size; i++) {
      bucketList[i] = NULL;
    }
  }

  ScopeTable(string str, int size, ScopeTable *parentScope) {
    id = str;
    this->size = size;
    this->parentScope = parentScope;
    bucketList = new SymbolInfo *[size];
    totalChildren = 0;

    for (int i = 0; i < size; i++) {
      bucketList[i] = NULL;
    }
  }


  ~ScopeTable() {

   
    for (int i = 0; i < size; i++) {
      SymbolInfo *temp = bucketList[i];
      while (temp != NULL) {
        SymbolInfo *temp2 = temp->getNext();
        delete temp;
        temp = temp2;
      }
    }
    delete[] bucketList;
  }

  string getId() { return id; }
  int getSize() { return size; }
  int getTotalChildren() { return totalChildren; }
  void setTotalChildren(int n) { totalChildren = n;}
 
  ScopeTable *getParentScope() { return parentScope; }


  unsigned long long hashFunction(string key) {
    unsigned long long hash = 0;

    for (int i = 0; i < key.length(); i++)
      hash = key[i] + (hash << 6) + (hash << 16) - hash;

    return hash;
  }

  SymbolInfo *lookUp(string key, ofstream &out) {
    unsigned long long ind = hashFunction(key) % size;
    SymbolInfo *tmp = bucketList[ind];
    int pos = 0;

    while (tmp != NULL) {
      if (tmp->getName() == key) {
        // out << "\t" << "'" << key << "'"
        //      << " found at position <" << ind+1
        //     << ", " << pos+1 << "> of ScopeTable# " << getId() << endl;
        return tmp;
      }

      pos++;
      tmp = tmp->getNext();
    }

    // out << "\t"
    //     << "Not found in ScopeTable# " << getId() << endl;
    return NULL;
  }

  void print(ofstream &out) {
    out << "\t"
        << "ScopeTable# " << id << endl;

    for (int i = 0; i < size; i++) {
      SymbolInfo *tmp = bucketList[i];
      if(tmp == NULL) continue;
      out << "\t" << i+1 ;

      while (tmp != NULL) {
        if(tmp->getArraySize() < -1)
          out << " --> " <<  "<" << tmp->getName() << "," << "FUNCTION,"<< tmp->getDataType() << ">" ;
        else if(tmp->getArraySize() > 0)
          out << " --> " <<  "<" << tmp->getName() << "," << "ARRAY" << ">";
        else
          out << " --> " <<  "<" << tmp->getName() << "," << tmp->getType() << ">";

        tmp = tmp->getNext();
      }

      out << endl;
    }
  }

  bool insertSym(SymbolInfo &sym, ofstream &out) {
    string key = sym.getName();
    unsigned long long ind = hashFunction(key) % size;
    SymbolInfo *tmp = bucketList[ind];
    int pos = 0;

    while (tmp != NULL) {
      if (tmp->getName() == key) {
        // out << "\t" << "" << sym.getName() << " already exists in the current ScopeTable"<< endl;
        return false;
      }
      pos++;
      tmp = tmp->getNext();
    }

    pos = 0;
    tmp = bucketList[ind];

    if (tmp == NULL) {
      bucketList[ind] = &sym;
      sym.setNext(tmp);

      
      return true;
    }

    else {
      while (tmp->getNext() != NULL) {
        tmp = tmp->getNext();
        pos++;
      }
      pos++;

      tmp->setNext(&sym);
      sym.setNext(NULL);

      // out << "\t"
      //     << "Inserted  at position "
      //     << "<" << ind+1 << ", " << pos+1 << "> of ScopeTable# " << id << endl;
      return true;
    }
  }

  bool deleteSym(string key, ofstream &out) {
    unsigned long long ind = hashFunction(key) % size;
    SymbolInfo *tmp = bucketList[ind];
    SymbolInfo *prev = NULL;
    int pos = 0;

    while (tmp != NULL) {
      if (tmp->getName() == key) {
        if (prev == NULL)
          bucketList[ind] = tmp->getNext();
        else
          prev->setNext(tmp->getNext());

        // out << "\t"
        //     << "Deleted " << "'" << key << "' from position <" << ind+1 << ", " << pos+1
        //     << "> of ScopeTable# " << getId() <<  endl;
        delete tmp;
        return true;
      }

      pos++;
      prev = tmp;
      tmp = tmp->getNext();
    }
    out << "\t" << "Not found in the current ScopeTable# " << getId() << endl;
  }
};

class SymbolTable {
  ScopeTable *currentScope;
  int NumberOfScopes;
  

public:
  SymbolTable() { 
    currentScope = NULL; 
  NumberOfScopes = 0;
  }
  ~SymbolTable() {
    /* Destructor to delete all the ScopeTables present in the SymbolTable*/

    ScopeTable *tmp = currentScope;
    while (tmp != NULL) {
      currentScope = currentScope->getParentScope();
      delete tmp;
      tmp = currentScope;
    }
  }

  int getCurrentScopeID() { 
    if(currentScope == NULL) return 0;
    return stoi(currentScope->getId()); }

  ScopeTable *getCurrentScope() { return currentScope; }

  void printCurrentScope(ofstream &out) {
    if (currentScope == NULL) {
      out << "\t"
          << "no ScopeTable in the SymbolTable" << endl;
      return;
    }

    currentScope->print(out);
  }
  
  /* */

  void printAll(ofstream &out) {
    if (currentScope == NULL) {
      out << "\t"
          << "no ScopeTable in the SymbolTable" << endl;
      return;
    }

    ScopeTable *tmp = currentScope;

    while (tmp != NULL) {
      tmp->print(out);
      tmp = tmp->getParentScope();
    }
  }

  void enterScope(int id, int size, ofstream &out) {
    string str = to_string(++NumberOfScopes);
    // if (id == 1)

    //   currentScope = new ScopeTable(str, size, currentScope);
    // else
    //   currentScope = new ScopeTable(size, currentScope);
      currentScope = new ScopeTable(str,size,currentScope);
    // out << "\t"
    //     << "ScopeTable# " << currentScope->getId() << " created" << endl;
  }

  bool insert(string name, string type, ofstream &out) {
    if (currentScope == NULL) {
      out << "\t"
          << "no ScopeTable in the SymbolTable" << endl;
      return false;
    }

    SymbolInfo *tmp = new SymbolInfo(name, type);
    return currentScope->insertSym(*tmp, out);
  }

  bool insert2(SymbolInfo* sym, ofstream &out) {
    if (currentScope == NULL) {
      out << "\t"
          << "no ScopeTable in the SymbolTable" << endl;
      return false;
    }

    return currentScope->insertSym(*sym, out);
  }

  SymbolInfo *lookUp(string name, ofstream &out) {
    if (currentScope == NULL) {
      out << "\t"
          << "no ScopeTable in the SymbolTable" << endl;
      return NULL;
    }

    ScopeTable *tmp = currentScope;
    SymbolInfo *sym = NULL;

    while (tmp != NULL) {
      sym = tmp->lookUp(name, out);
      if (sym != NULL)
        return sym;
      tmp = tmp->getParentScope();
    }

    if (sym == NULL)
      /*out << "\t"
          << "'" << name << "' not found in any of the ScopeTables" << endl;*/

    return sym;
  }

  bool remove(string name, ofstream &out) {
    if (currentScope == NULL) {
      out << "\t"
          << "no ScopeTable in the SymbolTable" << endl;
      return false;
    }

    return currentScope->deleteSym(name, out);
  }

  int getScopeID(const std::string& name, std::ofstream& out)

  {
    if (currentScope == NULL) {
      out << "\t"
          << "no ScopeTable in the SymbolTable" << endl;
      return -1;
    }

    ScopeTable *tmp = currentScope;
    SymbolInfo *sym = NULL;

    while (tmp != NULL) {
      sym = tmp->lookUp(name, out);
      if (sym != NULL)
        return stoi(tmp->getId());
      tmp = tmp->getParentScope();
    }

    if (sym == NULL)
      /*out << "\t"
          << "'" << name << "' not found in any of the ScopeTables" << endl;*/

    return -1;
  }

  bool exitScope(ofstream &out) {

    if (currentScope->getId() == "1") {
      // out << "\t"
      //     << "ScopeTable# 1 cannot be deleted" << endl;
      return false;
    } else {
      ScopeTable *temp = currentScope;
      // out << "\t"
      //     << "ScopeTable# " << currentScope->getId() << " deleted" << endl;
      currentScope = currentScope->getParentScope();
      delete temp;
      return true;
    }
  }
};