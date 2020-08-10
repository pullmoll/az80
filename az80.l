%{
#include "az80.h"
#include "az80.tab.h"

#define	MAX_NAMELEN	128
#define	MAX_NESTING	16
typedef struct macro_stack_s {
	int	    state;
	symbol_t*   symbol;
	char*	    args;
	YY_BUFFER_STATE buffer;
}	macro_stack_t;


static const char *valid_b = "01";
static const char *valid_o = "01234567";
static const char *valid_d = "0123456789";
static const char *valid_x = "0123456789ABCDEF";

int64_t aton(char *src, int base, const char *valid, char end);

static char *substitute_equ(const char *string);
static char *expand_macro(symbol_t *mac, char *args);

static macro_stack_t macro_stack[MAX_NESTING];
static int macro_stkptr = 0;

static void dolist(void)
{
	if (!f_list)
		return;
	plst += snprintf(plst, MAX_LISTBUFF - (plst - lstbuff), "%s", yytext);
}

static void macbody(const char* src)
{
	int len = strlen(src);
	size_t pos = macsize;
	macsize = macsize + len + 1;
	if (macsize >= macsmax) {
		macsmax = macsmax ? macsmax * 2 : 256;
		macbuff = realloc(macbuff, macsmax);
		if (!macbuff) {
			fprintf(stderr, "Out of memory in macro body allocation\n");
			exit(1);
		}
	}
	snprintf(macbuff + pos, macsize - pos, "%s", src);
}

%}
	/* delimiters */
delim	[\t ,;()]

	/* binary digits */
bin	[0-1]

	/* octal digits */
oct	[0-7]

	/* decimal digits */
dec	[0-9]

	/* alpha characters and underscore */
alpha	[A-Za-z_]

	/* hexadecimal digits */
hex	[0-9A-Fa-f]

	/* alpha or numerical characters and underscore */
alnum	[0-9A-Za-z_]

%s	cc
%s	macl
%s	macd
%s	mace

%%

[Mm][Aa][Cc][Rr][Oo]	{   /* start macro definition */
			    dolist();
			    BEGIN(macl);
			    return t_MACRO;
			}
<macl>[\n]		{   /* body of macro definition */
			    dolist();
			    if (f_list) {
				plst = lstbuff;
			    }
			    BEGIN(macd);
			    line_no++;
			    return EOL;
			}
<macd>[Ee][Nn][Dd][Mm]	{   /* end of macro definition */
			    /* push back "endm" to state INITIAL */
			    yyless(0);
			    BEGIN(INITIAL);
			    /* return the lines up to here as a string */
			    yylval.s = macbuff;
			    macbuff = NULL;
			    return t_ENDM;
			}
<macd>[\n]		{   /* body of macro definition */
			    dolist();
			    if (f_list) {
				plst = lstbuff;
			    }
			    macbody(lstbuff);;
			    line_no++;
			    return EOL;
			}
<macl>{alpha}{alnum}*	{	/* alpha followed by alpha numerical */
				dolist();
				yylval.s = strdup(yytext);
				return t_SYM;
			}
<*>[Ll][Oo][Cc][Aa][Ll] {
			    dolist();
			    return t_LOCAL;
			}

<cc>[Nn][Zz]		{ dolist(); return t_cNZ; }
<cc>[Zz]		{ dolist(); return t_cZ; }
<cc>[Nn][Cc]		{ dolist(); return t_cNC; }
<cc>[Cc]		{ dolist(); return t_cC; }
<cc>[Pp][Oo]		{ dolist(); return t_cPO; }
<cc>[Pp][Ee]		{ dolist(); return t_cPE; }
<cc>[Pp]		{ dolist(); return t_cP; }
<cc>[Mm]		{ dolist(); return t_cM; }

[Bb][Cc]		{ dolist(); return t_BC; }
[Dd][Ee]		{ dolist(); return t_DE; }
[Hh][Ll]		{ dolist(); return t_HL; }
[Ss][Pp]		{ dolist(); return t_SP; }
[Aa][Ff]		{ dolist(); return t_AF; }

[Ii][Xx]		{ dolist(); return t_IX; }
[Ii][Yy]		{ dolist(); return t_IY; }

[Bb]			{ dolist(); return t_B; }
[Cc]			{ dolist(); return t_C; }
[Dd]			{ dolist(); return t_D; }
[Ee]			{ dolist(); return t_E; }
[Hh]			{ dolist(); return t_H; }
[Ll]			{ dolist(); return t_L; }
"("[Hh][Ll]")"		{ dolist(); return t_M; }
[Aa]			{ dolist(); return t_A; }
[Ff]			{ dolist(); return t_F; }
[Ii]			{ dolist(); return t_I; }
[Rr]			{ dolist(); return t_R; }
[Ii][Xx][Hh]		{ dolist(); return t_HX; }
[Ii][Xx][Ll]		{ dolist(); return t_LX; }
[Ii][Yy][Hh]		{ dolist(); return t_HY; }
[Ii][Yy][Ll]		{ dolist(); return t_LY; }
[Hh][Xx]		{ dolist(); return t_HX; }
[Ll][Xx]		{ dolist(); return t_LX; }
[Hh][Yy]		{ dolist(); return t_HY; }
[Ll][Yy]		{ dolist(); return t_LY; }

"("[Cc]")"		{ dolist(); return t_PORTC; }

[Aa][Dd][Cc]		{ dolist(); return t_ADC; }
[Aa][Dd][Dd]		{ dolist(); return t_ADD; }
[Aa][Nn][Dd]		{ dolist(); return t_AND; }
[Bb][Ii][Tt]		{ dolist(); return t_BIT; }
[Cc][Aa][Ll][Ll]	{ dolist(); BEGIN(cc); return t_CALL; }
[Cc][Cc][Ff]		{ dolist(); return t_CCF; }
[Cc][Pp]		{ dolist(); return t_CP; }
[Cc][Pp][Dd]		{ dolist(); return t_CPD; }
[Cc][Pp][Dd][Rr]	{ dolist(); return t_CPDR; }
[Cc][Pp][Ii]		{ dolist(); return t_CPI; }
[Cc][Pp][Ii][Rr]	{ dolist(); return t_CPIR; }
[Cc][Pp][Ll]		{ dolist(); return t_CPL; }
[Dd][Aa][Aa]		{ dolist(); return t_DAA; }
[Dd][Ee][Cc]		{ dolist(); return t_DEC; }
[Dd][Ii]		{ dolist(); return t_DI; }
[Dd][Jj][Nn][Zz]	{ dolist(); return t_DJNZ; }
[Ee][Ii]		{ dolist(); return t_EI; }
[Ee][Xx]		{ dolist(); return t_EX; }
[Ee][Xx][Xx]		{ dolist(); return t_EXX; }
[Hh][Aa][Ll][Tt]	{ dolist(); return t_HALT; }
[Ii][Mm]		{ dolist(); return t_IM; }
[Ii][Nn]		{ dolist(); return t_IN; }
[Ii][Nn][Cc]		{ dolist(); return t_INC; }
[Ii][Nn][Dd]		{ dolist(); return t_IND; }
[Ii][Nn][Dd][Rr]	{ dolist(); return t_INDR; }
[Ii][Nn][Ii]		{ dolist(); return t_INI; }
[Ii][Nn][Ii][Rr]	{ dolist(); return t_INIR; }
[Jj][Pp]		{ dolist(); BEGIN(cc); return t_JP; }
[Jj][Rr]		{ dolist(); BEGIN(cc); return t_JR; }
[Ll][Dd]		{ dolist(); return t_LD; }
[Ll][Dd][Dd]		{ dolist(); return t_LDD; }
[Ll][Dd][Dd][Rr]	{ dolist(); return t_LDDR; }
[Ll][Dd][Ii]		{ dolist(); return t_LDI; }
[Ll][Dd][Ii][Rr]	{ dolist(); return t_LDIR; }
[Nn][Ee][Gg]		{ dolist(); return t_NEG; }
[Nn][Oo][Pp]		{ dolist(); return t_NOP; }
[Oo][Rr]		{ dolist(); return t_OR; }
[Oo][Tt][Dd][Rr]	{ dolist(); return t_OTDR; }
[Oo][Tt][Ii][Rr]	{ dolist(); return t_OTIR; }
[Oo][Uu][Tt]		{ dolist(); return t_OUT; }
[Oo][Uu][Tt][Dd]	{ dolist(); return t_OUTD; }
[Oo][Uu][Tt][Ii]	{ dolist(); return t_OUTI; }
[Pp][Oo][Pp]		{ dolist(); return t_POP; }
[Pp][Uu][Ss][Hh]	{ dolist(); return t_PUSH; }
[Rr][Ee][Ss]		{ dolist(); return t_RES; }
[Rr][Ee][Tt]		{ dolist(); BEGIN(cc); return t_RET; }
[Rr][Ee][Tt][Ii]	{ dolist(); return t_RETI; }
[Rr][Ee][Tt][Nn]	{ dolist(); return t_RETN; }
[Rr][Ll]		{ dolist(); return t_RL; }
[Rr][Ll][Aa]		{ dolist(); return t_RLA; }
[Rr][Ll][Cc]		{ dolist(); return t_RLC; }
[Rr][Ll][Cc][Aa]	{ dolist(); return t_RLCA; }
[Rr][Ll][Dd]		{ dolist(); return t_RLD; }
[Rr][Rr]		{ dolist(); return t_RR; }
[Rr][Rr][Aa]		{ dolist(); return t_RRA; }
[Rr][Rr][Cc]		{ dolist(); return t_RRC; }
[Rr][Rr][Cc][Aa]	{ dolist(); return t_RRCA; }
[Rr][Rr][Dd]		{ dolist(); return t_RRD; }
[Rr][Ss][Tt]		{ dolist(); return t_RST; }
[Ss][Bb][Cc]		{ dolist(); return t_SBC; }
[Ss][Cc][Ff]		{ dolist(); return t_SCF; }
[Ss][Ee][Tt]		{ dolist(); return t_SET; }
[Ss][Ll][Aa]		{ dolist(); return t_SLA; }
[Ss][Rr][Aa]		{ dolist(); return t_SRA; }
[Ss][Ll][Ll]		{ dolist(); return t_SLL; }
[Ss][Rr][Ll]		{ dolist(); return t_SRL; }
[Ss][Uu][Bb]		{ dolist(); return t_SUB; }
[Xx][Oo][Rr]		{ dolist(); return t_XOR; }

"."[Tt][Ii][Tt][Ll][Ee]	{ dolist(); return t_TITLE; }
[Dd][Bb]		{ dolist(); return t_DB; }
[Dd][Ww]		{ dolist(); return t_DW; }
[Dd][Dd]		{ dolist(); return t_DD; }
[Dd][Ss]		{ dolist(); return t_DS; }
[Dd][Ee][Ff][Bb]	{ dolist(); return t_DEFB; }
[Dd][Ee][Ff][Ww]	{ dolist(); return t_DEFW; }
[Dd][Ee][Ff][Dd]	{ dolist(); return t_DEFD; }
[Dd][Ee][Ff][Ll]	{ dolist(); return t_DEFL; }
[Dd][Ee][Ff][Mm]	{ dolist(); return t_DEFM; }
[Dd][Ee][Ff][Ss]	{ dolist(); return t_DEFS; }
[Ee][Nn][Dd]		{ dolist(); return t_END; }
[Ee][Qq][Uu]		{ dolist(); return t_EQU; }
[Aa][Ll][Ii][Gg][Nn]	{ dolist(); return t_ALIGN; }
[Ee][Vv][Ee][Nn]	{ dolist(); return t_EVEN; }
[Oo][Rr][Gg]		{ dolist(); return t_ORG; }

{bin}+[Bb]		{
				dolist();
				yylval.i = aton(yytext,2,valid_b,'B');
				return t_IMM;
			}

{oct}+[Oo]		{
				dolist();
				yylval.i = aton(yytext,8,valid_o,'O');
				return t_IMM;
			}

{dec}+[Dd]?		{
				dolist();
				yylval.i = aton(yytext,10,valid_d,'D');
				return t_IMM;
			}

{hex}+[Hh]		{
				dolist();
				yylval.i = aton(yytext,16,valid_x,'H');
				return t_IMM;
			}

"0"[Bb]{bin}+		{
				dolist();
				yylval.i = aton(yytext+2,2,valid_b,0);
				return t_IMM;
			}

"0"[Xx]{hex}+		{
				dolist();
				yylval.i = aton(yytext+2,16,valid_x,0);
				return t_IMM;
			}

"$"			{ dolist(); yylval.i = PC; return t_IMM; }
","			{ dolist(); return COMMA; }
":"                     { dolist(); return COLON; }
"("			{ dolist(); return LPAREN; }
")"			{ dolist(); return RPAREN; }
"'"			{ dolist(); return QUOTE; }
"+"			{ dolist(); return PLUS; }
"-"			{ dolist(); return MINUS; }
"*"			{ dolist(); return MUL; }
"/"			{ dolist(); return DIV; }
"%"			{ dolist(); return MOD; }
"<<"			{ dolist(); return SHL; }
">>"			{ dolist(); return SHR; }
"&"                     { dolist(); return AND; }
"|"                     { dolist(); return OR; }
"^"                     { dolist(); return XOR; }
"~"                     { dolist(); return NOT; }

\"[^\"\n]+\"            {	/* anything enclosed in double quotes, w/o CR */
				dolist();
				yylval.s = strdup(yytext + 1);
				yylval.s[strlen(yylval.s)-1] = '\0';
				return t_STR;
			}

\'[^\'\n]+\'		{	/* anything enclosed in single quotes, w/o CR */
				dolist();
				if (yyleng < 4) {
				    yylval.i = yytext[1];
				    if (yyleng > 3)
					yylval.i += 256 * yytext[2];
				    return t_IMM;
				} else {
				    yylval.s = strdup(yytext + 1);
				    yylval.s[strlen(yylval.s)-1] = '\0';
				    return t_STR;
				}
			}

{alpha}{alnum}*		{	/* alpha followed by alpha numerical */
				dolist();
				yylval.s = strdup(yytext);
				return t_SYM;
			}

[\t ]			{	/* white space */
				dolist();
			}

";"[^\n]*\n		|	/* comment until CR */
[\n]			{	/* CR */
				dolist();
				if (f_list) {
					plst = lstbuff;
				}
				BEGIN(INITIAL);
				line_no++;
				return EOL;
			}

%%

int64_t aton(char *src, int base, const char *valid, char end)
{
	int64_t result = 0;
	bool minus = false;
	char * pos;

	while (*src && !strchr(valid, toupper(*src)) && (toupper(*src) != end)) {
		switch (*src) {
		case '+':
			break;
		case '-':
			minus = !minus;
			break;
		}
		src++;
	}
	while (*src && ((pos = strchr(valid, toupper(*src))) != NULL)) {
		result *= base;
		if (pos) {
			result += (int64_t)(pos - valid);
		}
		src++;
	}
	if (minus) {
		result = -result;
	}
	return result;
}

static char *substitute_equ(const char *string)
{
	char name[MAX_NAMELEN];
	symbol_t *s;
	equate_t *e;
	const char *src;
	char *subst;
	char *brk;
	char eos;
	size_t size = strlen(string) + 1;
	size_t len;
	int escaped;
	int i;

#if	SUBST_DEBUG
	printf("substitute %s\n", string);
#endif
	eos = *string;
	subst = calloc(size, sizeof(char));
	for (i = 0, escaped = 0, src = string + 1; *src; src++) {
		if (!escaped && *src == eos)
			break;
		if (!escaped && *src == '\\')
			escaped = 1;
		if (escaped || *src != '$') {
			subst[i++] = *src;
			escaped = 0;
			continue;
		}
		/* double $ is literal $ */
		if (i > 0 && subst[i-1] == '$') {
			subst[i++] = *src;
			escaped = 0;
			continue;
		}
		escaped = 0;
		brk = strpbrk(src + 1, "\t \"'(),;");
		len = brk ? (size_t)(brk - src - 1) : strlen(src + 1);
		if (len >= MAX_NAMELEN) {
			error("name too long; increase MAX_NAMELEN (%s:%d)",
				__FILE__, __LINE__);
		}
		strncpy(name, src + 1, len);
		name[len] = '\0';
		s = get_typed(name, TYPE_EQU);
		if (!s) {
			subst[i++] = *src;
			continue;
		}
		e = &s->u.equ;
		if (!e->string || e->token != t_STR) {
			subst[i++] = *src;
			continue;
		}
		add_ref(s);
		if (strlen(e->string) > len) {
			/* need to realloc subst */
			size += strlen(e->string) - len;
			subst = realloc(subst, size);
		}
		strcpy(subst + i, e->string);
		i += strlen(e->string);
		src += len;
	}
	subst[i] = '\0';
#if	SUBST_DEBUG
	printf("result %s\n", subst);
#endif
	return subst;
}

static char *expand_macro(symbol_t *msym, char *args)
{
	char **argv;
	int argc;
	int argmax;
	int n;
	char *src;
	char *expanded;
	char *dst;
	size_t expsize;
	size_t expoffs;

	if (!args)
		args = "";

#if	EXPAND_DEBUG
	printf("expand '%s' with args '%s'\n", msym->name, args);
#endif

	/* split comma separated args into argv[] */
	argmax = 8;
	argv = (char **)calloc(argmax, sizeof(char *));
	src = args;
	argc = 0;
	while (*src) {
		while (*src == '\t' || *src == ' ')
			src++;

		if (argc >= argmax) {
			argmax *= 2;
			argv = realloc(argv, argmax * sizeof(char *));
			if (!argv) {
				error("out of memory while expanding macro %s\n",
					msym->name);
				exit(1);
			}
		}
		argv[argc] = malloc(strlen(src) + 1);
		if (!argv[argc]) {
			error("out of memory while expanding macro %s\n",
				msym->name);
			exit(1);
		}
		dst = argv[argc];
		while (*src && *src != ',')
			*dst++ = *src++;
		*dst = '\0';
		if (*src == ',')
			src++;
		argc++;
	}

#if	EXPAND_DEBUG
	printf("argc %d\n", argc);
	for (n = 0; n < argc; n++)
		printf("  argv[%d] = '%s'\n", n, argv[n]);
#endif

	/* start with 2 times the macro body length */
	src = msym->u.macro.text;
	expsize = 2 * strlen(src);
	expoffs = 0;
	dst = expanded = malloc(expsize);

#if	EXPAND_DEBUG
	printf("*** body\n%s\n", src);
#endif

	while (*src) {
		if (src[0] == '%') {
			src++;
			n = strtoul(src, &src, 0);
			if (n >= argc)
				continue;	/* no argv[] available */
			if (expoffs + strlen(argv[n]) + 1 >= expsize) {
				expsize *= 2;
				expanded = realloc(expanded, expsize);
				if (!expanded) {
					error("out of memory while expanding macro %s\n",
						msym->name);
					exit(1);
				}
			}
			strcpy(&expanded[expoffs], argv[n]);
			expoffs += strlen(argv[n]);
		} else {
			if (expoffs + 2 >= expsize) {
				expsize *= 2;
				expanded = realloc(expanded, expsize);
				if (!expanded) {
					error("out of memory while expanding macro %s\n",
						msym->name);
					exit(1);
				}
			}
			expanded[expoffs++] = *src++;
		}
	}
	expanded[expoffs] = '\0';

	/* get rid of argv[] */
	while (--argc >= 0)
		free(argv[argc]);
	free(argv);

#if	EXPAND_DEBUG
	printf("*** expanded\n%s\n", expanded);
#endif

	return expanded;
}

void yyerror(const char * msg)
{
	fprintf(stderr, "line %d: ", line_no);
	fprintf(stderr, "%s", msg);
	fprintf(stderr, " at \"%s\"\n", yytext);
}

int yywrap(void)
{
	if (pass_no < 2) {
		rewind(inpfile);
		PC = 0;
		line_no = 1;
		pass_no++;
		printf("Pass #%d\n", pass_no);
		return 0;
	}
	return 1;
}

