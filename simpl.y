%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <iostream>
#include <vector>

enum Type { Integer, Array };

struct CodeNode {
  std::string code;
  std::string name;
};

struct Symbol {
  std::string name;
  Type type;
};

struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};

std::vector <Function> symbol_table;

// remember that Bison is a bottom up parser: that it parses leaf nodes first before
// parsing the parent nodes. So control flow begins at the leaf grammar nodes
// and propagates up to the parents.
Function *get_function() {
  int last = symbol_table.size()-1;
  if (last < 0) {
    printf("***Error. Attempt to call get_function with an empty symbol table\n");
    printf("Create a 'Function' object using 'add_function_to_symbol_table' before\n");
    printf("calling 'find' or 'add_variable_to_symbol_table'");
    exit(1);
  }
  return &symbol_table[last];
}

// find a particular variable using the symbol table.
// grab the most recent function, and linear search to
// find the symbol you are looking for.
// you may want to extend "find" to handle different types of "Integer" vs "Array"
bool find(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      return true;
    }
  }
  return false;
}

// when you see a function declaration inside the grammar, add
// the function name to the symbol table
void add_function_to_symbol_table(std::string &value) {
  Function f; 
  f.name = value; 
  symbol_table.push_back(f);
}

// when you see a symbol declaration inside the grammar, add
// the symbol name as well as some type information to the symbol table
void add_variable_to_symbol_table(std::string &value, Type t) {
  Symbol s;
  s.name = value;
  s.type = t;
  Function *f = get_function();
  f->declarations.push_back(s);
}

// a function to print out the symbol table to the screen
// largely for debugging purposes.
void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
    printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
    }
  }
  printf("--------------------\n");
}

extern int yylex();
extern FILE* yyin;


void yyerror(const char* s);

int paren_count = 0;
%}

%locations

%left ASSIGN
%left LESS GREATER LESS_EQUAL GREATER_EQUAL EQUAL NOT_EQUAL
%left SUB ADD
%left MUL DIV MOD

%token RETURN BREAK CONTINUE
%token L_BRAC R_BRAC
%token L_PAREN R_PAREN
%token L_CURLY R_CURLY
%token READ WRITE
%token WHILE IF ELSE
%token FUNC INT MAIN 
%token COMMA SEMICOLON PERIOD

%token <op_value> NUM
%token <op_value> IDENT

%token UNKNOWN_TOKEN 

%nterm  functions function statement statements values value parameters if while declaration action bracestatement

%nterm functions

%start program

%union {
  char *op_value;
  struct CodeNode *code_node;
}

%define parse.error verbose

%type <code_node> parameters
%type <code_node> functions
%type <code_node> function
%type <code_node> statements
%type <code_node> statement 

%%

program: functions {
  struct CodeNode *functions = $1;
  printf("%s\n", functions->code.c_str());
}

functions: functions function   {
            struct CodeNode *functions = $1;
            struct CodeNode *function = $2;
            struct CodeNode *node = new CodeNode;
            node->code = functions->code + function->code;
            $$ = node;
        }
        |  %empty {
            struct CodeNode *node = new CodeNode;
            $$ = node;
        }
        ;

function: FUNC IDENT L_PAREN parameters R_PAREN L_CURLY statements R_CURLY{
            struct CodeNode *node = new CodeNode;
            struct CodeNode *parameters = $4;
            struct CodeNode *statements = $7;
            node->code = std::string("func ") + std::string($2) + std::string("\n");
            node->code += parameters->code;
            node->code += statements->code;
            node->code += std::string("endfunc\n\n");
            $$ = node;
        }
        | MAIN L_CURLY statements R_CURLY {
            struct CodeNode *node = new CodeNode;
            struct CodeNode *statements = $3;
            node->code = std::string("func MAIN\n");
            node->code += statements->code;
            node->code += std::string("endfunc\n\n");
            $$ = node;
        }
        ;

statements: statement PERIOD statements {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *statement = $1;
                struct CodeNode *statements= $3;
                node->code = statement->code + statements->code;
                $$ = node;
        }
        | bracestatement statements {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *bracestatement = $1;
                struct CodeNode *statements = $2;
                node->code = bracestatement->code + statements->code;
                $$ = node; 
        }
        | %empty {
            struct CodeNode *node = new CodeNode;
            $$ = node;
        }
        ;

statement: values       {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *values = $1;
                node->code = values->code;
                $$ = node;
        }
        | declaration   {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *declaration = $1;
                node->code = declaration->code;
                $$ = node;
        }
        | RETURN values {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *values = $2;
                node->code = std::string("ret ") + values->code;
                $$ = node;
        }
        | READ value    {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *value = $2;
                node->code = std::string(".< ") + value->code;
                $$ = node;
        }
        | WRITE value   {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *value = $2;
                node->code = std::string(".> ") + value->code;
                $$ = node;
        }
        | BREAK         {
                struct CodeNode *node = new CodeNode;
                node->code = std::string("BREAK\n");
                $$ = node;
        }
        | CONTINUE      {
                struct CodeNode *node = new CodeNode;
                node->code = std::string("CONTINUE\n");
                $$ = node;
        }
        ;

bracestatement: if      {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *if = $1;
                node->code = if->code;
                $$ = node;
        }
        | while         {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *while = $1;
                node->code = while->code;
                $$ = node;
        }
        ;

values: L_PAREN values R_PAREN    {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *values = $2;
                node->code = values->code;
                $$ = node;
        }
        |  action                 {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *action = $1;
                node->code = action->code;
                $$ = node;
        }
        | value                   {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *value = $1;
                node->code = value->code;
                $$ = node;
        }
        ;

value: IDENT
        | IDENT L_PAREN parameters R_PAREN {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *parameters = $3;
                node->code = std::string($1) + paramaters->code;
                $$ = node;
        }
        | IDENT L_BRAC NUM R_BRAC {
                struct CodeNode *node = new CodeNode;
                node->code = std::string($1) + std::string($3);
                $$ = node;
        }
        | NUM {
                struct CodeNode *node = new CodeNode;
                node->code = std::string($1);
                $$ = node;
        }
        ;

declaration: INT IDENT {
                struct CodeNode *node = new CodeNode;
                node->code = std::string("INT ") + std::string($2);
                $$ = node;
        }
        | INT IDENT ASSIGN values {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *values = $4;
                node->code = std::string("INT ") + std::string($2) + std::string("ASSIGN ");
                node->code += values->code;
                $$ = node;
        }
        | INT IDENT L_BRAC NUM R_BRAC {
                struct CodeNode *node = new CodeNode;
                node->code = std::string("INT ") + std::string($2) + std::string($4);
                $$ = node;
        }
        | INT IDENT L_BRAC R_BRAC ASSIGN L_CURLY parameters R_CURLY {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *paramaters = $7;
                node->code = std::string("INT ") + std::string($2) + std::string("ASSIGN ");
                node->code = paramaters->code;
                $$ = node;
        }
        ;

parameters: values COMMA parameters {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *values = $1;
                struct codeNode *paramaters = $3;
                node->code = values->code + std::string("COMMA");
                node->code += paramaters->code;
                $$ = node;
        }
        | values {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *values = $1;
                node->code = values->code;
                $$ = node;
        }
        | declaration COMMA parameters  {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *declaration = $1;
                struct codeNode *paramaters = $3;
                node->code = declaration->code + std::string("COMMA");
                node->code += paramaters->code;
                $$ = node;
        }
        | declaration {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *declaration = $1;
                node->code = declaration->code;
                $$ = node;
        }        
        | %empty {
                struct CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;

if: IF L_PAREN values R_PAREN L_CURLY statements R_CURLY                                    {printf("if -> IF L_PAREN values R_PAREN L_CURLY statements R_CURLY\n");}
        | IF L_PAREN values R_PAREN L_CURLY statements R_CURLY ELSE L_CURLY statements R_CURLY  {printf("if -> IF L_PAREN values R_PAREN L_CURLY statements R_CURLY ELSE L_CURLY statements R_CURLY\n");}
        ;

while: WHILE L_PAREN values R_PAREN L_CURLY statements R_CURLY  {printf("while -> WHILE L_PAREN values R_PAREN L_CURLY statements R_CURLY\n");}
        ;

action: add             {printf("action -> add\n");}
        | sub           {printf("action -> sub\n");}
        | mul          {printf("action -> mult\n");}
        | div           {printf("action -> div\n");}
        | mod           {printf("action -> mod\n");}
        | assign        {printf("action -> assign\n");}
        | less          {printf("action -> less\n");}
        | lesseq        {printf("action -> lesseq\n");}
        | great         {printf("action -> great\n");}
        | greateq       {printf("action -> greateq\n");}
        | equal         {printf("action -> equal\n");} 
        | notequal      {printf("action -> notequal\n");}
        ;


add: values ADD value                   {printf("add -> values ADD value\n");}
sub: values SUB value                   {printf("sub -> values SUB value\n");}
mul: values MUL value                 {printf("mul -> values MUL value\n");}
div: values DIV value                   {printf("div -> values DIV value\n");}
mod: values MOD value                   {printf("mod -> values MOD value\n");}
assign: value ASSIGN values             {printf("assign -> value ASSIGN values\n");}
less: values LESS values                {printf("less -> values LESS values\n");}
lesseq: values LESS_EQUAL values        {printf("lesseq -> values LESS_EQUAL values\n");}
great: values GREATER values            {printf("great -> values GREATER values\n");} 
greateq: values GREATER_EQUAL values    {printf("greateq -> values GREATER_EQUAL values\n");}
equal: values EQUAL values              {printf("equal -> values EQUAL values\n");}
notequal: values NOT_EQUAL values       {printf("notequal -> values NOT_EQUAL values\n");}

%%

int main(int argc, char** argv) {
  yyin = stdin;

  bool interactive = true;
  if (argc >= 2) {
    FILE *file_ptr = fopen(argv[1], "r");
    if (file_ptr == NULL) {
      printf("Could not open file: %s\n", argv[1]);
      exit(1);
    }
    yyin = file_ptr;
    interactive = false;
  }

  return yyparse();

}

void yyerror(const char* s) {
  fprintf(stderr, "Error encountered while parsing token at [%i,%i]: %s\n", yylloc.first_line, yylloc.first_column, s);
  exit(1);
}
