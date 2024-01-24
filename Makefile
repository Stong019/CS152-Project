EXECUTABLE := simpl.out
SIMPL_LANG := simpl.lex
LEX_CFILE := lex.yy.c
FILE_PATH ?= 

ARGS = $(filter-out $@,$(MAKECMDGOALS))

# Catch-all target that does nothing, to prevent errors with extra arguments
%:
	@:

compile:
	flex $(SIMPL_LANG)
	gcc $(LEX_CFILE) -ll -o simpl.out

run:
	@if [ -z "$(ARGS)" ]; then \
		echo "Usage: make run path/to/file"; \
	else \
		./$(EXECUTABLE) < "$(ARGS)"; \
	fi

clean:
	rm $(EXECUTABLE)
	rm $(LEX_CFILE)