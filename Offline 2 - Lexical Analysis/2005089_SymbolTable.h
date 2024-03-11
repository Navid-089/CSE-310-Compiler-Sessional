#include "2005089_ScopeTable.h"

using namespace std;

class SymbolTable {
  ScopeTable *currentScope;

public:
  SymbolTable() { currentScope = NULL; }
  ~SymbolTable() {
    /* Destructor to delete all the ScopeTables present in the SymbolTable*/

    ScopeTable *tmp = currentScope;
    while (tmp != NULL) {
      currentScope = currentScope->getParentScope();
      delete tmp;
      tmp = currentScope;
    }
  }

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
    string str = to_string(id);
    if (id == 1)
      currentScope = new ScopeTable(str, size, currentScope);
    else
      currentScope = new ScopeTable(size, currentScope);
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
      out << "\t"
          << "'" << name << "' not found in any of the ScopeTables" << endl;

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