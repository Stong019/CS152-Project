%{
    int currLine = 1; int currPos = 1;
%}

DIGIT [0-9]
ALPHA [a-zA-Z]
COMMENT ["].*["]

%%

"fn" {printf("FUNC\n"); currPos += yyleng;} // have to add all the other combintaions
"<-" {printf("RETURN\n");}
"#" {printf("INT\n");}
">" {printf("READ\n");}
"<" {printf("WRITE\n");}
"..." {printf("WHILE\n");}
"?" {printf("IF\n");}
"!" {printf("ELSE\n");}
"b" {printf("BREAK\n");}
"c" {printf("CONTINUE\n");}
"l" {printf("LEFT PAREN\n");}
"r" {printf("RIGHT PAREN\n");}
"l~" {printf("LEFT CURLY\n");}
"r~" {printf("RIGHT CURLY\n");}
"-" {printf("COMMA\n");}
":/" {printf("SEMICOLON\n");}
"p" {printf("PLUS\n");}
"s" {printf("SUBTRACT\n");}
"m" {printf("MULTIPLY\n");}
"d" {printf("DIVIDE\n");}
"rem" {printf("MODULUS\n");}
"e" {printf("ASSIGN\n");}
"lt" {printf("LESS THAN\n");}
"leq" {printf("LESS EQUAL\n");}
"gt" {printf("GREATER THAN\n");}
"geq" {printf("GREATER EQUAL\n");}
"is" {printf("EQUALITY\n");}
"ne" {printf("NOT EQUAL\n");}
"START" {printf("MAIN\n");}
"/\\".*\n {printf("ARRAY\n");}                   // Needs to be changed
{ALPHA}+ {printf("IDENTIFIER: %s\n", yytext);}
{COMMENT} {printf("COMMENT\n");}

%%

int main(int argc, char** argv) {
    if(argc > 1){
            if(yyin == NULL) {yyin = stdin;}
    }
    else { yyin = stdin;}

    yylex();
    return 0;
}