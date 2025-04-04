%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <iostream>
#include <vector>
#include <algorithm>
#include <sstream>

enum Type { Integer, Array };

bool noErrors = true;

std::vector<std::string> reservedKeywords = {
        "fn", "b", "c", "p", "s", "m", "d", "rem", "e", 
        "lt", "leq", "gt", "geq", "is", "ne", "START"
};

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

// returns variable type
Type get_type(std::string &value) {
  Function *f = get_function();
  Type type;
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      type = s->type;
    }
  }
  return type;
}

//similar to the find() func above that finds varibles in symbol table but for function
bool find_function(const std::string& functionName) {
    for (std::vector<Function>::const_iterator it = symbol_table.begin(); it != symbol_table.end(); ++it) {
        if (it->name == functionName) {
            return true; // Function found
        }
    }
    return false; // Function not found
}


//iterates through the keywords Vector
bool check_keywords(const std::string& name){
    return std::find(reservedKeywords.begin(), reservedKeywords.end(), name) != reservedKeywords.end();
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

static int parameter_num = 0;

void reset_parameter_num() {
	parameter_num = 0;
}

std::string get_new_parameter_num() {
	parameter_num++;
	return std::string("$") + std::to_string(parameter_num - 1);
}



static int condition_count = 0;
static int loop_count = -1;
std::string condition_label() {
     std::string value = "_condition" + std::to_string(condition_count);
     condition_count+=1;
     return value;
}
std::string loop_label() {
     std::string value = "_loop" + std::to_string(loop_count);
     return value;
}

extern int yylex();
extern FILE* yyin;


void yyerror(const char* s);

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
%token SEMICOLON PERIOD

%left COMMA

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
%type <code_node> function_header
%type <code_node> less
%type <code_node> lesseq
%type <code_node> great
%type <code_node> greateq
%type <code_node> equal
%type <code_node> notequal

%%

program: functions {
  struct CodeNode *functions = $1;
  std::string mainFunc = "main";
  if(!find_function(mainFunc)){
	yyerror("Main function not defined.");		
  }
  if(noErrors){
 	printf("%s\n", functions->code.c_str());
  }
}

functions: functions function   {
            struct CodeNode *node = new CodeNode;
            node->code = $1->code + $2->code;
            $$ = node;
        }
        |  %empty {
	    struct CodeNode *node = new CodeNode;
	    $$ = node;
	}
        ;

function: function_header L_PAREN parameters R_PAREN L_CURLY statements R_CURLY{
	    struct CodeNode *node = new CodeNode;

	    reset_parameter_num();		

            node->code = std::string("func ") + $1->name + std::string("\n");
            node->code += $3->code + $6->code;
            node->code += std::string("endfunc\n\n");
            $$ = node;
        }
        | function_header L_CURLY statements R_CURLY {
            struct CodeNode *node = new CodeNode;
            node->code = std::string("func main\n");
            node->code += $3->code;
            node->code += std::string("endfunc\n\n");
            $$ = node;
        }
        ;

function_header: FUNC IDENT {
		struct CodeNode *node = new CodeNode;
		node->name = std::string($2);
		std::string function_name = $2;
  		if(check_keywords(function_name)) {
      			yyerror("reserved keyword and cannot be used as a function name.");
  		}
		add_function_to_symbol_table(function_name);
		$$ = node;
	       }
	       | MAIN {
		std::string function_name = "main";
                add_function_to_symbol_table(function_name);
	       }

statements: statements statement PERIOD {
                struct CodeNode *node = new CodeNode;
                node->code = $1->code + $2->code;
                $$ = node;
        }
        | statements bracestatement {
                struct CodeNode *node = new CodeNode;
                node->code = $1->code + $2->code;
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
		node->name = std::string($2);
                if (!find(node->name)) {
                        yyerror("Undeclared variable.");
                }
                else if (get_type(node->name) == Array) {
                        yyerror("Not specifying array index.");
                }
		
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
		std::string label = loop_label();

		if(loop_count < 0){
      		  yyerror("Break statement not within a loop.");
     		}	

                node->code = std::string(":= end") + label + std::string("\n");
                $$ = node;
         }
         | CONTINUE     {
         	struct CodeNode *node = new CodeNode;
                std::string label = loop_label();

                if(loop_count < 0){
                  yyerror("Continue statement not within a loop.");
                }

                node->code = std::string(":= begin") + label + std::string("\n");
                $$ = node;
	 }
	 | assign
         ;

bracestatement: if_stmt
              | begin_loop while_stmt end_loop {$$ = $2;}
	      ;

begin_loop: %empty {loop_count++;};

end_loop: %empty {loop_count--;};

expression: L_PAREN expression R_PAREN {$$ = $2;}
          | action
          | value
          ;

value: IDENT {
		struct CodeNode *node = new CodeNode;
                node->name = std::string($1);
		if (!find(node->name)) {
                        yyerror("Undeclared variable.");
                }	
		else if (get_type(node->name) == Array) {
			yyerror("Not specifying array index.");
		}			

                $$ = node;
	}
	| NUM {
		struct CodeNode *node = new CodeNode;
                node->name = std::string($1);
                $$ = node;
        }
        | IDENT L_PAREN parameters R_PAREN {
		std::string functionName = $1;
		if(!find_function(functionName)){
			yyerror("Undefined function.");
		}

		std::string temp = create_temp();        	
		CodeNode *node = new CodeNode;
       		node->code = $3->code + decl_temp_code(temp);
        	node->code += std::string("call ") + std::string($1) + std::string(", ") + temp + std::string("\n");
        	node->name = temp;
        	$$ = node;
        }
        | IDENT L_BRAC expression R_BRAC {
                struct CodeNode *node = new CodeNode;
		std::string variable_name = $1;
		if (!find(variable_name)) {
                        yyerror("Undeclared variable.");
                }
		else if (get_type(variable_name) == Integer) {
                        yyerror("Accessing index on non-array variable.");
                }


        	std::string temp = create_temp();
                node->code = $3->code + decl_temp_code(temp);
                node->code += std::string("=[] ") + temp + std::string(", ") + std::string($1) + std::string(", ") + $3->name + std::string("\n");
                node->name = temp;
                $$ = node;
	}
        ;


declaration: INT IDENT {
		std::string variable_name = $2;

               	if (find(variable_name)) {
			yyerror("Duplicate variable.");
		}
                if(check_keywords(variable_name)) {
                        yyerror("Cannot use reserved keyword as variable name.");
                }
		add_variable_to_symbol_table(variable_name, Integer);

                struct CodeNode *node = new CodeNode;
		node->name = std::string($2);
                node->code = std::string(". ") + std::string($2) + std::string("\n");;
                $$ = node;
        }
        | INT IDENT ASSIGN expression {
		std::string variable_name = $2;
		if (find(variable_name)) {
                        yyerror("Duplicate variable.");
                }
                if(check_keywords(variable_name)) {
                        yyerror("Cannot use reserved keyword as variable name.");
                } 
	        add_variable_to_symbol_table(variable_name, Integer);

                struct CodeNode *node = new CodeNode;
                node->code = std::string(". ") + std::string($2) + std::string("\n");
                node->code += $4->code + std::string("= ") + std::string($2) + std::string(", ") + $4->name + std::string("\n");
                $$ = node;
        }
        | INT IDENT L_BRAC expression R_BRAC {
        	std::string variable_name = $2;

        	std::string sz = $4->name;        
		if(find(variable_name)){
	                yyerror("Duplicate variable.");
		}
		if(check_keywords(variable_name)) {
                        yyerror("Cannot use reserved keyword as variable name.");
                }
		int arrSz;
		std::stringstream ss(sz);
		if(!(ss >> arrSz) || arrSz <= 0){
			yyerror("Invalid array size.");
		}
		add_variable_to_symbol_table(variable_name, Array);
		
	        struct CodeNode *node = new CodeNode;
		node->name = std::string($2);
		node->code = $4->code;
                node->code += std::string(".[] ") + std::string($2) + std::string(", ") + $4->name + std::string("\n");
                $$ = node;
        }
        | INT IDENT L_BRAC R_BRAC ASSIGN L_CURLY parameters R_CURLY {// *** NOT IMPLEMENTED ***
                struct CodeNode *node = new CodeNode;
                struct CodeNode *paramaters = $7;
                node->code = std::string("INT ") + std::string($2) + std::string("ASSIGN ");
                node->code = paramaters->code;
                $$ = node;
        }
        ;

parameters: parameters COMMA expression {
                struct CodeNode *node = new CodeNode;
		std::string temp = create_temp();
                node->code = $3->code + $1->code + decl_temp_code(temp);
		node->code += std::string("= ") + temp + std::string(", ") + $3->name + std::string("\n");
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
        | parameters COMMA declaration {
                struct CodeNode *node = new CodeNode;
                node->code = $1->code + $3->code;
		node->code += std::string("= ") + $3->name + std::string(", ") + get_new_parameter_num() + std::string("\n");
		$$ = node;
        }
        | declaration {
		struct CodeNode *node = new CodeNode;
                node->code = $1->code;
                node->code += std::string("= ") + $1->name + std::string(", ") + get_new_parameter_num() + std::string("\n");
                $$ = node;
	}
        | %empty {
            struct CodeNode *node = new CodeNode;
            $$ = node;
	}
        ;







if_stmt: IF L_PAREN expression R_PAREN L_CURLY statements R_CURLY                                    {//printf("if -> IF L_PAREN expression R_PAREN L_CURLY statements R_CURLY\n");
                struct CodeNode *node = new CodeNode;
                std::string label = condition_label();

                node->code = $3->code;
                node->code += std::string("?:= if") + label + std::string(", ") + $3->name + std::string("\n");
                node->code += std::string(":= end") + label + std::string("\n");
                node->code += std::string(": if") + label + std::string("\n");
                node->code += $6->code;
                node->code += std::string(": end") + label + std::string("\n");
                $$ = node;
	}	
        | IF L_PAREN expression R_PAREN L_CURLY statements R_CURLY ELSE L_CURLY statements R_CURLY  {//printf("if -> IF L_PAREN expression R_PAREN L_CURLY statements R_CURLY ELSE L_CURLY statements R_CURLY\n");
                struct CodeNode *node = new CodeNode;
                std::string label = condition_label();

                node->code = $3->code;
                node->code += std::string("?:= if") + label + std::string(", ") + $3->name + std::string("\n");
                node->code += std::string(":= else") + label + std::string("\n");
                node->code += std::string(": if") + label + std::string("\n");
                node->code += $6->code;
		node->code += std::string(":= end") + label + std::string("\n");
                node->code += std::string(": else") + label + std::string("\n");
		node->code += $10->code;
                node->code += std::string(": end") + label + std::string("\n");
                $$ = node;
	}
        ;

while_stmt: WHILE L_PAREN expression R_PAREN L_CURLY statements R_CURLY {
                struct CodeNode *node = new CodeNode;
		std::string label = loop_label();

                node->code += std::string(": begin") + label + std::string("\n");
                node->code += $3->code;
                node->code += std::string("?:= body") + label + std::string(", ") + $3->name + std::string("\n");
                node->code += std::string(":= end") + label + std::string("\n");
                node->code += std::string(": body") + label + std::string("\n");
                node->code += $6->code;
                node->code += std::string(":= begin") + label + std::string("\n");
                node->code += std::string(": end") + label + std::string("\n");
                $$ = node;
        }
        ;

action: add
      | sub
      | mul
      | div
      | mod 
      | less         
      | lesseq       
      | great       
      | greateq      
      | equal         
      | notequal   
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




	
less: expression LESS expression                {//printf("less -> expression LESS expression\n"); 
        std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("< ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
}
lesseq: expression LESS_EQUAL expression        {//printf("lesseq -> expression LESS_EQUAL expression\n");
        std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("<= ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
}
great: expression GREATER expression            {//printf("great -> expression GREATER expression\n");
        std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("> ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
} 
greateq: expression GREATER_EQUAL expression    {//printf("greateq -> expression GREATER_EQUAL expression\n");
        std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string(">= ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
}
equal: expression EQUAL expression              {//printf("equal -> expression EQUAL expression\n");
        std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("== ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
}
notequal: expression NOT_EQUAL expression       {//printf("notequal -> expression NOT_EQUAL expression\n");
        std::string temp = create_temp();
        CodeNode *node = new CodeNode;
        node->code = $1->code + $3->code + decl_temp_code(temp);
        node->code += std::string("!= ") + temp + std::string(", ") + $1->name + std::string(", ") + $3->name + std::string("\n");
        node->name = temp;
        $$ = node;
};

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

  yyparse();
  if(noErrors){
	print_symbol_table();
  }
}

void yyerror(const char* s) {
  fprintf(stderr, "Error encountered while parsing token at [%i,%i]: %s\n", yylloc.first_line, yylloc.first_column, s);
  noErrors = false;	  
  //exit(1);
}
