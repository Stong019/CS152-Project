%{
    int currLine = 1; int currPos = 1;
%}

DIGIT[0-9]

%%

"fn" {printf("FUNC\n"); currPos += yyleng;} // have to add all the other combintaions

%%

int main(int argc, char** argv) {
    if(argc > 1){
            if(yyin == NULL) {yyin = stdin;}
    }
    else { yyin = stdin;}

    yylex();
    return 0;
}