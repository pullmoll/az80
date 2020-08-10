#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <ctype.h>
#include <limits.h>

typedef uint8_t  byte;
typedef	uint16_t word;

/** @brief type of the union contained in a symbol */
typedef enum {
	TYPE_CONST,
	TYPE_INCLUDE,
	TYPE_EQU,
	TYPE_MACRO,
	TYPE_MNEMONIC
}   symtype_e;

typedef struct equate_s {
    int		    token;
    char*	    string;
}   equate_t;

typedef struct macro_s {
    char*	    text;
}   macro_t;

typedef	struct symbol_s {
    struct symbol_s * next;
    symtype_e	    type;
    int		    pass_no;
    union {
	macro_t	    macro;
	equate_t    equ;
	int64_t	    value;
    } u;
    int		    refs;
    int*	    line_no;
    char*	    name;
}   symbol_t;

#define	MAX_LISTBUFF	4096
extern char* lstbuff;
extern char* plst;
extern char* macbuff;
extern size_t macsmax;
extern size_t macsize;

extern int line_no;
extern int pass_no;

extern bool f_list;
extern bool f_tape;
extern bool f_tape_cg;
extern bool f_tape_vz;
extern bool f_syms;
extern bool f_xref;
extern bool f_first;


extern FILE *inpfile;
extern uint16_t PC;

void add_ref(symbol_t* sym);
void add_symbol(const char* name, int int64_t);
void add_typed(const char* name, symtype_e type);
symbol_t* get_symbol(char * name);
symbol_t* get_typed(char * name, symtype_e type);

void warning(const char* fmt, ...);
void error(const char* fmt, ...);
void yyerror(const char* message);
void yyrestart(FILE* yyin);
int yylex(void);
