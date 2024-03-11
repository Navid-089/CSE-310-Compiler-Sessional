#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>


using namespace std;

class SymbolInfo {
private:
  string name;
  string type;
  SymbolInfo *next;

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
  }

  void setName(string name) { this->name = name; }

  void setType(string type) { this->type = type; }

  void setNext(SymbolInfo *next) { this->next = next; }

  string getName() { return name; }

  string getType() { return type; }

  SymbolInfo *getNext() { return next; }

  friend ostream &operator<<(ostream &out, const SymbolInfo &syminfo) {
    out << "(" << syminfo.name << "," << syminfo.type << ")";
    return out;
  }
};
