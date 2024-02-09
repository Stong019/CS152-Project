%{
    #include <stdio.h>
    
    int currLine = 1; int currPos = 1;

    // COMMENT ["](.|\n)*?["]
    // COMMENT ["].*["]
    // WHITESPACE [ \s\t\r\n\f]

    #define YY_USER_ACTION currPos += yyleng;
    #include "parser.tab.h"

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
"("         {return LEFT PAREN; }
")"         {return RIGHT PAREN; }
"{"        {return LEFT CURLY; }
"}"        {return RIGHT CURLY; }
"["        {return LEFT BRACKET; }
"]"        {return RIGHT BRACKET; }
"_"         {return COMMA; }
":/"        {return SEMICOLON; }
"p"         {return PLUS; }
"s"         {return SUBTRACT; }
"m"         {return MULTIPLY; }
"d"         {return DIVIDE; }
"rem"       {return MODULUS; }
"e"         {return ASSIGN; }
"lt"        {return LESS THAN; }
"leq"       {return LESS EQUAL; }
"gt"        {return GREATER THAN; }
"geq"       {return GREATER EQUAL; }
"is"        {return EQUALITY; }
"ne"        {return NOT EQUAL; }
"START"     {return MAIN; }
{DIGIT}+    {return NUMBER; }
{ALPHA}+({ALPHA}|{DIGIT})*   {return IDENTIFIER; }
{COMMENT}+   {}

{DIGIT}+({ALPHA}|{DIGIT})*  {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos - yyleng, yytext); }
.           {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos - yyleng, yytext); }

%%

int main(int argc, char** argv) {
    if(argc > 1){
            if(yyin == NULL) {yyin = stdin;}
    }
    else { yyin = stdin;}

    yylex();
    return 0;

}

