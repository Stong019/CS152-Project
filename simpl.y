%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

extern int yylex();
extern FILE* yyin;

void yyerror(const char* s);

int paren_count = 0;
%}

%locations
%define api.value.type union
%define parse.error verbose
%define parse.lac full

%left ASSIGN
%left LESS GREATER LESS_EQUAL GREATER_EQUAL EQUAL NOT_EQUAL
%left SUB ADD
%left MULT DIV MOD

%token RETURN BREAK CONTINUE
%token L_BRAC R_BRAC
%token L_PAREN R_PAREN
%token L_CURLY R_CURLY
%token READ WRITE
%token WHILE IF ELSE
%token FUNC INT START 
%token COMMA SEMICOLON

%token <double> NUM
%token <char*> IDENT

%token UNKNOWN_TOKEN 

%nterm <double> expression add sub mult div mod

%start expressions 

%%
expressions: expressions expression {printf("%g\n", $2);}
           | %empty
           ;

expression: add
          | sub
          | mult
          | div
          | mod
          | NUMBER
          ;

add:  L_PAREN ADD  expression expression R_PAREN {$$ = $3 + $4;};
sub:  L_PAREN SUB  expression expression R_PAREN {$$ = $3 - $4;};
mult: L_PAREN MULT expression expression R_PAREN {$$ = $3 * $4;};
div:  L_PAREN DIV  expression expression R_PAREN {$$ = $3 / $4;};
mod:  L_PAREN MOD  expression expression R_PAREN {$$ = fmod($3, $4);};
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
  fprintf(stderr, "Error encountered while parsing token at [%i,%i-%i,%i]: %s\n", yylloc.first_line, yylloc.first_column, yylloc.last_line, yylloc.last_column, s);
  exit(1);
}
