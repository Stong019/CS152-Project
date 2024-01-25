%{

    #include <stdio.h>
    
    int currLine = 1; int currPos = 1;

    // COMMENT ["](.|\n)*?["]
    // COMMENT ["].*["]
    // WHITESPACE [ \s\t\r\n\f]

%}

DIGIT [0-9]
ALPHA [a-zA-Z]
COMMENT ["].*["]

%%

"\n" ++currLine; currPos = 1;
" " ++currPos;

"fn"        {printf("FUNC\n"); currPos += yyleng;} // have to add all the other combintaions
"<-"        {printf("RETURN\n"); currPos += yyleng;}
"#"         {printf("INT\n"); currPos += yyleng;}
">"         {printf("READ\n"); currPos += yyleng;}
"<"         {printf("WRITE\n"); currPos += yyleng;}
"..."       {printf("WHILE\n"); currPos += yyleng;}
"?"         {printf("IF\n"); currPos += yyleng;}
"!"         {printf("ELSE\n"); currPos += yyleng;}
"b"         {printf("BREAK\n"); currPos += yyleng;}
"c"         {printf("CONTINUE\n"); currPos += yyleng;}
"l"         {printf("LEFT PAREN\n"); currPos += yyleng;}
"r"         {printf("RIGHT PAREN\n"); currPos += yyleng;}
"l~"        {printf("LEFT CURLY\n"); currPos += yyleng;}
"r~"        {printf("RIGHT CURLY\n"); currPos += yyleng;}
"l-"        {printf("LEFT BRACKET\n"); currPos += yyleng;}
"r-"        {printf("RIGHT BRACKET\n"); currPos += yyleng;}
"_"         {printf("COMMA\n"); currPos += yyleng;}
":/"        {printf("SEMICOLON\n"); currPos += yyleng;}
"p"         {printf("PLUS\n"); currPos += yyleng;}
"s"         {printf("SUBTRACT\n"); currPos += yyleng;}
"m"         {printf("MULTIPLY\n"); currPos += yyleng;}
"d"         {printf("DIVIDE\n"); currPos += yyleng;}
"rem"       {printf("MODULUS\n"); currPos += yyleng;}
"e"         {printf("ASSIGN\n"); currPos += yyleng;}
"lt"        {printf("LESS THAN\n"); currPos += yyleng;}
"leq"       {printf("LESS EQUAL\n"); currPos += yyleng;}
"gt"        {printf("GREATER THAN\n"); currPos += yyleng;}
"geq"       {printf("GREATER EQUAL\n"); currPos += yyleng;}
"is"        {printf("EQUALITY\n"); currPos += yyleng;}
"ne"        {printf("NOT EQUAL\n"); currPos += yyleng;}
"START"     {printf("MAIN\n"); currPos += yyleng;}
"/\\"     {printf("ARRAY\n"); currPos += yyleng;}         
{DIGIT}+    {printf("NUMBER: %s\n", yytext); currPos += yyleng;}
{ALPHA}+({ALPHA}|{DIGIT})*   {printf("IDENTIFIER: %s\n", yytext); currPos += yyleng;}
{COMMENT}+   {printf("COMMENT\n"); currPos += yyleng;}

{DIGIT}+({ALPHA}|{DIGIT})*  {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext); currPos += yyleng;}
.           {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); currPos += yyleng;}

%%

int main(int argc, char** argv) {
    if(argc > 1){
            if(yyin == NULL) {yyin = stdin;}
    }
    else { yyin = stdin;}

    yylex();
    return 0;

}

