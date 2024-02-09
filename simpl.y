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

%token NUM
%token <char*> IDENT

%token UNKNOWN_TOKEN 

%nterm  functions function statement statements values value parameters if_stmt while declaration action

%start functions

%%
functions: functions function   {printf("functions -> functions function\n");}
        | %empty                {printf("functions -> epsilon\n");}
        ;

function: FUNC IDENT L_PAREN parameters R_PAREN L_CURLY statements R_CURLY  {printf("function -> FUNC IDENT L_PAREN parameters R_PAREN L_CURLY statements R_CURLY\n");}
        | START L_CURLY statements R_CURLY                                  {printf("function -> START L_CURLY statements R_CURLY\n");}
        ;

statements: statements PERIOD statement {printf("statements -> statements PERIOD statement\n");}
        | %empty                        {printf("statements -> epsilon\n");}
        ;

statement: ifelse      {printf("statement -> ifelse\n");}
        | while         {printf("statement -> while\n");}
        | values        {printf("statement -> values\n");}
        | declaration   {printf("statement -> declaration\n");}
        | RETURN values {printf("statement -> RETURN values\n");}
        | READ value    {printf("statement -> READ value\n");}
        | WRITE value   {printf("statement -> WRITE value\n");}
        | BREAK         {printf("statement -> BREAK\n");}
        | CONTINUE      {printf("statement -> CONTINUE\n");}
        ;

values: action      {printf("values -> action\n");}
        | value     {printf("values -> value\n");}
        ;

value: IDENT
        | IDENT L_PAREN parameters R_PAREN      {printf("value -> IDENT L_PAREN parameters R_PAREN\n");}
        | IDENT L_BRAC NUM R_BRAC               {printf("value -> IDENT L_BRAC NUM R_BRAC\n");}
        ;

declaration: INT IDENT                                                  {printf("declaration -> INT IDENT\n");}
        | INT IDENT ASSIGN values                                       {printf("declaration -> INT IDENT ASSIGN values\n");}
        | INT IDENT L_BRAC NUM R_BRAC                                   {printf("declaration -> INT IDENT L_BRAC NUM R_BRAC\n");}
        | INT IDENT L_BRAC R_BRAC ASSIGN L_CURLY parameters R_CURLY     {printf("declaration -> INT IDENT L_BRAC R_BRAC ASSIGN L_CURLY parameters R_CURLY\n");}
        ;

parameters: parameters COMMA value  {printf("parameters -> parameters COMMA value\n");}
        | value                     {printf("parameters -> value\n");}
        | %empty                    {printf("parameters -> epsilon\n");}
        ;

ifelse: IF L_PAREN values R_PAREN L_CURLY statements R_CURLY                                    {printf("if-stmt -> IF L_PAREN values R_PAREN L_CURLY statements R_CURLY\n");}
        | IF L_PAREN values R_PAREN L_CURLY statements R_CURLY ELSE L_CURLY statements R_CURLY  {printf("if-stmt -> IF L_PAREN values R_PAREN L_CURLY statements R_CURLY ELSE L_CURLY statements R_CURLY\n");}
        ;

while: WHILE L_PAREN values R_PAREN L_CURLY statements R_CURLY  {printf("while -> WHILE L_PAREN values R_PAREN L_CURLY statements R_CURLY\n");}
        ;

action: add             {printf("action -> add\n");}
        | sub           {printf("action -> sub\n");}
        | mult          {printf("action -> mult\n");}
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
mult: values MULT value                 {printf("mult -> values MULT value\n");}
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
  fprintf(stderr, "Error encountered while parsing token at [%i,%i-%i,%i]: %s\n", yylloc.first_line, yylloc.first_column, yylloc.last_line, yylloc.last_column, s);
  exit(1);
}
