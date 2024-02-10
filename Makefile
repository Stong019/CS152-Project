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

clean:
	rm $(EXECUTABLE)
	rm $(LEX_CFILE)
	rm simpl.output
	rm simpl.tab.c
	rm simpl.tab.h

compile: 
	bison -t -d -v simpl.y
	flex simpl.lex
	g++ lex.yy.c simpl.tab.c -ll -o simpl