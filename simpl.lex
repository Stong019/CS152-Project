%{
    #include <stdio.h>
    
    int currLine = 1; int currPos = 1;

    // COMMENT ["](.|\n)*?["]
    // COMMENT ["].*["]
    // WHITESPACE [ \s\t\r\n\f]

    #define YY_USER_ACTION currPos += yyleng;
    #include "simpl.tab.h"

%}

DIGIT [0-9]
ALPHA [a-zA-Z]
COMMENT ["].*["]

%%

"\n" {++currLine; currPos = 1;}
" " {}

"."         {return PERIOD;}

"fn"        {return FUNC;} // have to add all the other combintaions
"<-"        {return RETURN;}
"#"         {return INT;}
">"         {return READ; }
"<"         {return WRITE; }
"..."       {return WHILE; }
"?"         {return IF; }
"!"         {return ELSE; }
"b"         {return BREAK; }
"c"         {return CONTINUE; }
"("         {return L_PAREN; }
")"         {return R_PAREN; }
"{"        {return L_CURLY; }
"}"        {return R_CURLY; }
"["        {return L_BRAC; }
"]"        {return R_BRAC; }
"_"         {return COMMA; }
":/"        {return SEMICOLON; }
"p"         {return ADD; }
"s"         {return SUB; }
"m"         {return MUL; }
"d"         {return DIV; }
"rem"       {return MOD; }
"e"         {return ASSIGN; }
"lt"        {return LESS; }
"leq"       {return LESS_EQUAL; }
"gt"        {return GREATER; }
"geq"       {return GREATER_EQUAL; }
"is"        {return EQUAL; }
"ne"        {return NOT_EQUAL; }
"START"     {return MAIN; }
{DIGIT}+    {return NUM; }
{ALPHA}+({ALPHA}|{DIGIT})*   {return IDENT; }
{COMMENT}+   {}

{DIGIT}+({ALPHA}|{DIGIT})*  {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos - yyleng, yytext); }
.           {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos - yyleng, yytext); }

%%


