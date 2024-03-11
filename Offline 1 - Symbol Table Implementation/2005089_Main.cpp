#include "2005089_SymbolTable.cpp"
#include <sstream>

using namespace std;

int numberOfWords(string str) {
  int words = 0;
  int lenOfSentence = str.length();

  for (int i = 0; i < lenOfSentence; i++) {
    if (str[i] == ' ')
      words++;
  }

  return words + 1;
}

int main() {
  freopen("input.txt", "r", stdin);
  ofstream out("output.txt");

  int n;
  cin >> n;
  
  string line;
  char c;
  int id = 0;
  int currentScopeTable = 0;
  int cmdflag = 0;

  SymbolTable *table = new SymbolTable();
  table->enterScope(++id, n, out);
  currentScopeTable = id;
  getline(cin, line);
  while (getline(cin, line)) {
    istringstream ins(line);
    int i = 0;
    string token;
    string *tokens = new string[10];
    ins >> c;
    cmdflag++;
    out << "Cmd " << cmdflag << ": " << c;

    switch (c) {
    case 'I':
      while (ins >> token) {
        tokens[i] = token;
        out << " " << token;
        i++;
      }
      out << endl;

      if (i != 2)
        out << "\t"
            << "Wrong number of arugments for the command " << c << endl;
      else {
        table->insert(tokens[0], tokens[1], out);
      }
      break;

    case 'L':
      while (ins >> token) {
        tokens[i] = token;
        out << " " << token;
        i++;
      }
      out << endl;

      if (i != 1)
        out << "\t"
            << "Wrong number of arugments for the command " << c << endl;
      else {
        table->lookUp(tokens[0], out);
      }
      break;

    case 'D':
      while (ins >> token) {
        tokens[i] = token;
        out << " " << token;
        i++;
      }
      out << endl;

      if (i != 1)
        out << "\t"
            << "Wrong number of arugments for the command " << c << endl;
      else {
        table->remove(tokens[0], out);
      }
      break;

    case 'P':
      while (ins >> token) {
        tokens[i] = token;
        out << " " << token;
        i++;
      }
      out << endl;

      if (i != 1)
        out << "\t"
            << "Wrong number of arugments for the command " << c << endl;
      else {
        if (tokens[0] == "A") {
          table->printAll(out);
        } else if (tokens[0] == "C") {
          table->printCurrentScope(out);
        } else {
          out << "\t"
              << "Invalid argument for the command " << c << endl;
        }
      }
      break;

    case 'S':
      while (ins >> token) {
        tokens[i] = token;
        out << " " << token;
        i++;
      }
      out << endl;

      if (i != 0)
        out << "\t"
            << "Wrong number of arugments for the command " << c << endl;
      else {
        table->enterScope(++id, n, out);

        currentScopeTable++;
        // cout << cmdflag << " " << currentScopeTable << endl;
      }
      break;

    case 'E':
      while (ins >> token) {
        tokens[i] = token;
        out << " " << token;
        i++;
      }
      out << endl;

      if (i != 0)
        out << "\t"
            << "Wrong number of arugments for the command " << c << endl;
      else {
        bool tmp = table->exitScope(out, 1);
        if (tmp)
          currentScopeTable--;
        // cout << cmdflag << " " << currentScopeTable << endl;
      }
      break;

    case 'Q':
      while (ins >> token) {
        tokens[i] = token;
        out << " " << token;
        i++;
      }
      out << endl;

      if (i != 0)
        out << "\t"
            << "Wrong number of arugments for the command " << c << endl;
      else {
        // cout << cmdflag << " " << currentScopeTable << endl;
        for (int ij = 0; ij < currentScopeTable; ij++)
          table->exitScope(out, 2);
      }
      break;

    default:
      out << "\t"
          << "Wrong command" << endl;
      break;
    }
  }
}
