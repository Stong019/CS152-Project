%{
    #include <stdio.h>
    #include "simpl.tab.h"
    
    int currLine = 1; int currPos = 1;

    // COMMENT ["](.|\n)*?["]
    // COMMENT ["].*["]
    // WHITESPACE [ \s\t\r\n\f]

    #define YY_USER_ACTION \
        yylloc.first_line = currLine;\
        yylloc.first_column = currPos;\
        currPos += yyleng;\

	char *create_string(char *text, int len) {
 		 char *string_value = new char[len + 1];
  		strcpy(string_value, text);
  		return string_value;
	}

%}

DIGIT [0-9]
ALPHA [a-zA-Z]
COMMENT ["].*["]

%%

"\n"        {++currLine; currPos = 1;}
" "         {++currPos;}
"\t"        {currPos += 4;}

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

{DIGIT}+    {yylval.op_value = create_string(yytext, yyleng); return NUM; }
{ALPHA}+({ALPHA}|{DIGIT})*   {yylval.op_value = create_string(yytext, yyleng); return IDENT; }
{COMMENT}+   {}

{DIGIT}+({ALPHA}|{DIGIT})*  {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext); }
.           {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); }

%%


