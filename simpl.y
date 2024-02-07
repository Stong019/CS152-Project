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

%nterm <double> functions function statement statements values value parameters if_stmt while declaration action

%start functions

%%
functions: functions function   {printf("functions -> functions function\n");}
        | %empty                {printf("functions -> epsilon\n");}
        ;

function: FUNC IDENT L_PAREN parameters R_PAREN L_CURLY statements R_CURLY
        | START L_CURLY statements R_CURLY
        ;

statements: statements PERIOD statement 
        | %empty
        ;

statement: if-else
        | while
        | values
        | declaration
        | RETURN values
        | READ value
        | WRITE value
        | BREAK
        | CONTINUE
        ;

values: action //values action value
        | value
        ;

value: IDENT
        | IDENT L_PAREN parameters R_PAREN
        | IDENT L_BRAC NUM R_BRAC
        ;

declaration: INT IDENT
        | INT IDENT ASSIGN values
        | INT IDENT L_BRAC NUM R_BRAC
        | INT IDENT L_BRAC R_BRAC ASSIGN L_CURLY parameters R_CURLY
        ;

parameters: parameters COMMA value
        | value
        | %empty
        ;

if-stmt: IF L_PAREN values R_PAREN L_CURLY statements R_CURLY
        | IF L_PAREN values R_PAREN L_CURLY statements R_CURLY ELSE L_CURLY statements R_CURLY
        ;

while: WHILE L_PAREN values R_PAREN L_CURLY statements R_CURLY
        ;

action: add
        | sub
        | mult
        | div
        | mod
        | assign
        | less
        | lesseq
        | great
        | greateq
        | equal
        | notequal
        ;

add: values ADD value {$$ = $1 + $3};
mult: values MULT value {$$ = $1 * $3};
div: values DIV value {$$ = $1 / $3};
mod: values MOD value {$$ = $1 % $3};
assign: value ASSIGN values {$1 = $3}
less: values LESS values {$1 < $3 ? $ : }
lesseq: values LESS_EQUAL values
great: values GREATER values
greateq: values GREATER_EQUAL values
equal: values EQUAL values
notequal: values NOT_EQUAL values

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
