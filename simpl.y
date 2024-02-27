%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <iostream>
#include <vector>
#include <algorithm>

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

std::string create_temp() {
     static int num = 0;
     std::string value = "_temp" + std::to_string(num);
     num+=1;
     return value;
}
std::string decl_temp_code(std::string &temp) {
	return std::string(". ") + temp + std:: string("\n");
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

%nterm  functions function statement statements expression value parameters if_stmt while_stmt declaration action bracestatement


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
%type <code_node> expression
%type <code_node> value
%type <code_node> if_stmt
%type <code_node> while_stmt 
%type <code_node> declaration
%type <code_node> action
%type <code_node> bracestatement
%type <code_node> add
%type <code_node> sub
%type <code_node> mul
%type <code_node> div
%type <code_node> mod
%type <code_node> assign

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
            node->code = std::string("func main\n");
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

statement: declaration
         | RETURN expression {
                struct CodeNode *node = new CodeNode;
                node->code = $2->code + std::string("ret ") + $2->name + std::string("\n");
                $$ = node;
         }
         | READ IDENT   {
                struct CodeNode *node = new CodeNode;
                node->code = std::string(".< ") + std::string($2) + std::string("\n");
                $$ = node;
         }
         | WRITE expression   {
                struct CodeNode *node = new CodeNode;
                node->code = $2->code + std::string(".> ") + $2->name + std::string("\n");
                $$ = node;
         }
         | BREAK         {
                struct CodeNode *node = new CodeNode;
                node->code = std::string("BREAK\n");
                $$ = node;
         }
         | CONTINUE     {
                struct CodeNode *node = new CodeNode;
                node->code = std::string("CONTINUE\n");
                $$ = node;
         }
	 | assign        {//printf("action -> assign\n");
                struct CodeNode *node = new CodeNode;
                struct CodeNode *assign = $1;
                node->code = assign->code;
                $$ = node;
         }
         ;

bracestatement: if_stmt      {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *if_stmt = $1;
                node->code = if_stmt->code;
                $$ = node;
        }
        | while_stmt         {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *while_stmt = $1;
                node->code = while_stmt->code;
                $$ = node;
        }
        ;

expression: L_PAREN expression R_PAREN {$$ = $2;}
          | action
          | value
          ;

value: IDENT {struct CodeNode *node = new CodeNode;
                node->name = std::string($1);
                $$ = node;
	}
	| NUM {struct CodeNode *node = new CodeNode;
                node->name = std::string($1);
                $$ = node;
        }
        | IDENT L_PAREN parameters R_PAREN {
		std::string temp = create_temp();        	
		CodeNode *node = new CodeNode;
       		node->code = $3->code + decl_temp_code(temp);
        	node->code += std::string("call ") + std::string($1) + std::string(", ") + temp + std::string("\n");
        	node->name = temp;
        	$$ = node;
        }
        | IDENT L_BRAC expression R_BRAC {
                struct CodeNode *node = new CodeNode;
        	std::string temp = create_temp();
                node->code = $3->code + decl_temp_code(temp);
                node->code += std::string("=[] ") + temp + std::string(", ") + std::string($1) + std::string(", ") + $3->name + std::string("\n");
                node->name = temp;
                $$ = node;
	}
        ;


declaration: INT IDENT {
                struct CodeNode *node = new CodeNode;
                node->code = std::string(". ") + std::string($2) + std::string("\n");;
                $$ = node;
        }
        | INT IDENT ASSIGN expression {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *expression = $4;
                node->code = std::string(". ") + std::string($2) + std::string("\n");
                node->code += expression->code + std::string("= ") + std::string($2) + std::string(", ") + expression->name + std::string("\n");
                $$ = node;
        }
        | INT IDENT L_BRAC expression R_BRAC {
                struct CodeNode *node = new CodeNode;
		node->code = $4->code;
                node->code += std::string(".[] ") + std::string($2) + std::string(", ") + $4->name + std::string("\n");
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

parameters: expression COMMA parameters {
                struct CodeNode *node = new CodeNode;
		std::string temp = create_temp();
                node->code = $1->code + $3->code + decl_temp_code(temp);;
		node->code += std::string("= ") + temp + std::string(", ") + $1->name + std::string("\n");
                node->code += std::string("param ") + temp + std::string("\n");
		$$ = node;
        }
        | expression {
		struct CodeNode *node = new CodeNode;
                std::string temp = create_temp();
                node->code = $1->code + decl_temp_code(temp);;
                node->code += std::string("= ") + temp + std::string(", ") + $1->name + std::string("\n");
                node->code += std::string("param ") + temp + std::string("\n");
		$$ = node;
	}
        | declaration COMMA parameters {
                struct CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code;
                $$ = node;
        }
        | declaration
        | %empty {
                struct CodeNode *node = new CodeNode;
                $$ = node;
        }
        ;

if_stmt: IF L_PAREN expression R_PAREN L_CURLY statements R_CURLY                                    {printf("if -> IF L_PAREN expression R_PAREN L_CURLY statements R_CURLY\n");}
        | IF L_PAREN expression R_PAREN L_CURLY statements R_CURLY ELSE L_CURLY statements R_CURLY  {printf("if -> IF L_PAREN expression R_PAREN L_CURLY statements R_CURLY ELSE L_CURLY statements R_CURLY\n");}
        ;

while_stmt: WHILE L_PAREN expression R_PAREN L_CURLY statements R_CURLY {
                struct CodeNode *node = new CodeNode;
                struct CodeNode *expression = $3;
                struct CodeNode *statements = $6;

                node->code += std::string(": beginLoop\n");
                node->code += std::string(". temp\n");
                node->code += std::string("< temp, ") + expression->code + std::string("\n");
                node->code += std::string("?:= loopBody, temp\n");
                node->code += std::string(":= endLoop\n");
                node->code += std::string(": loopbody\n");
                node->code += statements->code;
                node->code += std::string(":= beginLoop\n");
                node->code += std::string(": endLoop\n");
                $$ = node;
        }
        ;

action: add
      | sub
      | mul
      | div
      | mod 
      | less          {printf("action -> less\n");}
      | lesseq        {printf("action -> lesseq\n");}
      | great         {printf("action -> great\n");}
      | greateq       {printf("action -> greateq\n");}
      | equal         {printf("action -> equal\n");} 
      | notequal      {printf("action -> notequal\n");}
      ;


add: expression ADD expression {
        std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("+ ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
}
sub: expression SUB expression                   {//printf("sub -> expression SUB value\n");
	std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("- ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
}
mul: expression MUL expression                 {//printf("mul -> expression MUL value\n");
	std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("* ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
}
div: expression DIV expression                   {//printf("div -> expression DIV value\n");
	std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("/ ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
}
mod: expression MOD expression                   {//printf("mod -> expression MOD value\n");
	std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("% ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
}
assign: IDENT ASSIGN expression             {//printf("assign -> value ASSIGN expression\n");
      	struct CodeNode *node = new CodeNode;
	node->code = $3->code;
        node->code += std::string("= ") + std::string($1) + std::string(", ") + $3->name + std::string("\n");
        $$ = node;
      }
      | IDENT L_BRAC expression R_BRAC ASSIGN expression {
	struct CodeNode *node = new CodeNode;
        node->code = $3->code + $6->code;
        node->code += std::string("[]= ") + std::string($1) + std::string(", ") + $3->name + std::string(", ") + $6->name + std::string("\n");
        $$ = node;
      }




	
less: expression LESS expression                {printf("less -> expression LESS expression\n"); }
lesseq: expression LESS_EQUAL expression        {printf("lesseq -> expression LESS_EQUAL expression\n");}
great: expression GREATER expression            {printf("great -> expression GREATER expression\n");} 
greateq: expression GREATER_EQUAL expression    {printf("greateq -> expression GREATER_EQUAL expression\n");}
equal: expression EQUAL expression              {printf("equal -> expression EQUAL expression\n");}
notequal: expression NOT_EQUAL expression       {printf("notequal -> expression NOT_EQUAL expression\n");};

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
