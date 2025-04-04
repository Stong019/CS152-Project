EXECUTABLE := simpl
# SIMPL_LANG := simpl.lex
LEX_CFILE := lex.yy.c
# FILE_PATH ?= 

# ARGS = $(filter-out $@,$(MAKECMDGOALS))

# # Catch-all target that does nothing, to prevent errors with extra arguments
# %:
# 	@:

# compile:
# 	bison -t -d -v simpl.y
# 	flex $(SIMPL_LANG)
# 	gcc $(LEX_CFILE) -ll -o simpl

# run:
# 	@if [ -z "$(ARGS)" ]; then \
# 		echo "Usage: make run path/to/file"; \
# 	else \
# 		./$(EXECUTABLE) < "$(ARGS)"; \
# 	fi

all: 
	bison -t -d -v simpl.y
	flex simpl.lex
	g++ lex.yy.c simpl.tab.c -ll -std=c++11 -o simpl

clean:
	-rm -f $(EXECUTABLE) $(LEX_CFILE) simpl.output simpl.tab.c simpl.tab.h
