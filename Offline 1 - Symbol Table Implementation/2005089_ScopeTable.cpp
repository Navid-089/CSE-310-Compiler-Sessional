#include "2005089_SymbolInfo.cpp"


using namespace std;

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
        out << "\t" << "'" << key << "'"
             << " found at position <" << ind+1
            << ", " << pos+1 << "> of ScopeTable# " << getId() << endl;
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
      out << "\t" << i+1 ;

      while (tmp != NULL) {
        out << " --> " <<  "(" << tmp->getName() << "," << tmp->getType() << ")";

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
        out << "\t" << "'" << sym.getName() << "' already exists in the current ScopeTable# " << getId() << endl;
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

      out << "\t"
          << "Inserted  at position "
          << "<" << ind+1 << ", " << pos+1 << "> of ScopeTable# " << id << endl;
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

      out << "\t"
          << "Inserted  at position "
          << "<" << ind+1 << ", " << pos+1 << "> of ScopeTable# " << id << endl;
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

        out << "\t"
            << "Deleted " << "'" << key << "' from position <" << ind+1 << ", " << pos+1
            << "> of ScopeTable# " << getId() <<  endl;
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