
#include <stdio.h> // for `fprintf`, `stderr`
#include <stdlib.h>
#include <execinfo.h> // for backtrace

#include "util.h"

#define MAX_BACKTRACE_STACK_SIZE 32

void util_backtrace_print(void)
{
    void *stack[MAX_BACKTRACE_STACK_SIZE];
    char **symbols;
    int stack_size;

    stack_size = backtrace(stack, NUMBEROF(stack));
    symbols = backtrace_symbols(stack, stack_size);

    if(symbols == NULL) return; // TODO: maybe I can remove this

    fprintf(stderr, "Dumping backtrace:\n");
    for(int i = 0; i < stack_size; i++) {
        fprintf(stderr, "\t%s\n", symbols[i]);
    }
    free(symbols);
}

