%{
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <ctype.h>
#include "az80.tab.h"

extern char lstbuff[256];
extern char *plst;
extern int line_no;
extern int pass_no;
extern FILE *inpfile;
extern uint16_t PC;

static const char *valid_b = "01";
static const char *valid_o = "01234567";
static const char *valid_d = "0123456789";
static const char *valid_x = "0123456789ABCDEF";
int64_t aton(char *src, int base, const char *valid, char end);

static inline void TOKEN(void)
{
	if (!plst)
		return;
	size_t pos = plst - lstbuff;
	plst += snprintf(plst, sizeof(lstbuff) - pos, "%s", yytext);
}

%}

delim	[\t ,;()]
bin	[0-1]
oct	[0-7]
dec	[0-9]
alpha	[A-Za-z_]
hex	[0-9A-Fa-f]
alnum	[0-9A-Za-z_]

%s	cc

%%

<cc>[Nn][Zz]		{ TOKEN; return t_cNZ; }
<cc>[Zz]		{ TOKEN; return t_cZ; }
<cc>[Nn][Cc]		{ TOKEN; return t_cNC; }
<cc>[Cc]		{ TOKEN; return t_cC; }
<cc>[Pp][Oo]		{ TOKEN; return t_cPO; }
<cc>[Pp][Ee]		{ TOKEN; return t_cPE; }
<cc>[Pp]		{ TOKEN; return t_cP; }
<cc>[Mm]		{ TOKEN; return t_cM; }

[Bb][Cc]		{ TOKEN; return t_BC; }
[Dd][Ee]		{ TOKEN; return t_DE; }
[Hh][Ll]		{ TOKEN; return t_HL; }
[Ss][Pp]		{ TOKEN; return t_SP; }
[Aa][Ff]		{ TOKEN; return t_AF; }

[Ii][Xx]		{ TOKEN; return t_IX; }
[Ii][Yy]		{ TOKEN; return t_IY; }

[Bb]			{ TOKEN; return t_B; }
[Cc]			{ TOKEN; return t_C; }
[Dd]			{ TOKEN; return t_D; }
[Ee]			{ TOKEN; return t_E; }
[Hh]			{ TOKEN; return t_H; }
[Ll]			{ TOKEN; return t_L; }
"("[Hh][Ll]")"		{ TOKEN; return t_M; }
[Aa]			{ TOKEN; return t_A; }
[Ff]			{ TOKEN; return t_F; }
[Ii]			{ TOKEN; return t_I; }
[Rr]			{ TOKEN; return t_R; }
[Hh][Xx]		{ TOKEN; return t_HX; }
[Ll][Xx]		{ TOKEN; return t_LX; }
[Hh][Yy]		{ TOKEN; return t_HY; }
[Ll][Yy]		{ TOKEN; return t_LY; }

"("[Cc]")"		{ TOKEN; return t_PORTC; }

[Aa][Dd][Cc]		{ TOKEN; return t_ADC; }
[Aa][Dd][Dd]		{ TOKEN; return t_ADD; }
[Aa][Nn][Dd]		{ TOKEN; return t_AND; }
[Bb][Ii][Tt]		{ TOKEN; return t_BIT; }
[Cc][Aa][Ll][Ll]	{ TOKEN; BEGIN(cc); return t_CALL; }
[Cc][Cc][Ff]		{ TOKEN; return t_CCF; }
[Cc][Pp]		{ TOKEN; return t_CP; }
[Cc][Pp][Dd]		{ TOKEN; return t_CPD; }
[Cc][Pp][Dd][Rr]	{ TOKEN; return t_CPDR; }
[Cc][Pp][Ii]		{ TOKEN; return t_CPI; }
[Cc][Pp][Ii][Rr]	{ TOKEN; return t_CPIR; }
[Cc][Pp][Ll]		{ TOKEN; return t_CPL; }
[Dd][Aa][Aa]		{ TOKEN; return t_DAA; }
[Dd][Ee][Cc]		{ TOKEN; return t_DEC; }
[Dd][Ii]		{ TOKEN; return t_DI; }
[Dd][Jj][Nn][Zz]	{ TOKEN; return t_DJNZ; }
[Ee][Ii]		{ TOKEN; return t_EI; }
[Ee][Xx]		{ TOKEN; return t_EX; }
[Ee][Xx][Xx]		{ TOKEN; return t_EXX; }
[Hh][Aa][Ll][Tt]	{ TOKEN; return t_HALT; }
[Ii][Mm]		{ TOKEN; return t_IM; }
[Ii][Nn]		{ TOKEN; return t_IN; }
[Ii][Nn][Cc]		{ TOKEN; return t_INC; }
[Ii][Nn][Dd]		{ TOKEN; return t_IND; }
[Ii][Nn][Dd][Rr]	{ TOKEN; return t_INDR; }
[Ii][Nn][Ii]		{ TOKEN; return t_INI; }
[Ii][Nn][Ii][Rr]	{ TOKEN; return t_INIR; }
[Jj][Pp]		{ TOKEN; BEGIN(cc); return t_JP; }
[Jj][Rr]		{ TOKEN; BEGIN(cc); return t_JR; }
[Ll][Dd]		{ TOKEN; return t_LD; }
[Ll][Dd][Dd]		{ TOKEN; return t_LDD; }
[Ll][Dd][Dd][Rr]	{ TOKEN; return t_LDDR; }
[Ll][Dd][Ii]		{ TOKEN; return t_LDI; }
[Ll][Dd][Ii][Rr]	{ TOKEN; return t_LDIR; }
[Nn][Ee][Gg]		{ TOKEN; return t_NEG; }
[Nn][Oo][Pp]		{ TOKEN; return t_NOP; }
[Oo][Rr]		{ TOKEN; return t_OR; }
[Oo][Tt][Dd][Rr]	{ TOKEN; return t_OTDR; }
[Oo][Tt][Ii][Rr]	{ TOKEN; return t_OTIR; }
[Oo][Uu][Tt]		{ TOKEN; return t_OUT; }
[Oo][Uu][Tt][Dd]	{ TOKEN; return t_OUTD; }
[Oo][Uu][Tt][Ii]	{ TOKEN; return t_OUTI; }
[Pp][Oo][Pp]		{ TOKEN; return t_POP; }
[Pp][Uu][Ss][Hh]	{ TOKEN; return t_PUSH; }
[Rr][Ee][Ss]		{ TOKEN; return t_RES; }
[Rr][Ee][Tt]		{ TOKEN; BEGIN(cc); return t_RET; }
[Rr][Ee][Tt][Ii]	{ TOKEN; return t_RETI; }
[Rr][Ee][Tt][Nn]	{ TOKEN; return t_RETN; }
[Rr][Ll]		{ TOKEN; return t_RL; }
[Rr][Ll][Aa]		{ TOKEN; return t_RLA; }
[Rr][Ll][Cc]		{ TOKEN; return t_RLC; }
[Rr][Ll][Cc][Aa]	{ TOKEN; return t_RLCA; }
[Rr][Ll][Dd]		{ TOKEN; return t_RLD; }
[Rr][Rr]		{ TOKEN; return t_RR; }
[Rr][Rr][Aa]		{ TOKEN; return t_RRA; }
[Rr][Rr][Cc]		{ TOKEN; return t_RRC; }
[Rr][Rr][Cc][Aa]	{ TOKEN; return t_RRCA; }
[Rr][Rr][Dd]		{ TOKEN; return t_RRD; }
[Rr][Ss][Tt]		{ TOKEN; return t_RST; }
[Ss][Bb][Cc]		{ TOKEN; return t_SBC; }
[Ss][Cc][Ff]		{ TOKEN; return t_SCF; }
[Ss][Ee][Tt]		{ TOKEN; return t_SET; }
[Ss][Ll][Aa]		{ TOKEN; return t_SLA; }
[Ss][Rr][Aa]		{ TOKEN; return t_SRA; }
[Ss][Ll][Ll]		{ TOKEN; return t_SLL; }
[Ss][Rr][Ll]		{ TOKEN; return t_SRL; }
[Ss][Uu][Bb]		{ TOKEN; return t_SUB; }
[Xx][Oo][Rr]		{ TOKEN; return t_XOR; }

[Dd][Bb]		{ TOKEN; return t_DB; }
[Dd][Ww]		{ TOKEN; return t_DW; }
[Dd][Dd]		{ TOKEN; return t_DD; }
[Dd][Ss]		{ TOKEN; return t_DS; }
[Dd][Ee][Ff][Bb]	{ TOKEN; return t_DEFB; }
[Dd][Ee][Ff][Ww]	{ TOKEN; return t_DEFW; }
[Dd][Ee][Ff][Dd]	{ TOKEN; return t_DEFD; }
[Dd][Ee][Ff][Ll]	{ TOKEN; return t_DEFL; }
[Dd][Ee][Ff][Mm]	{ TOKEN; return t_DEFM; }
[Dd][Ee][Ff][Ss]	{ TOKEN; return t_DEFS; }
[Ee][Nn][Dd]		{ TOKEN; return t_END; }
[Ee][Qq][Uu]		{ TOKEN; return t_EQU; }
[Aa][Ll][Ii][Gg][Nn]	{ TOKEN; return t_ALIGN; }
[Ee][Vv][Ee][Nn]	{ TOKEN; return t_EVEN; }
[Oo][Rr][Gg]		{ TOKEN; return t_ORG; }

{bin}+[Bb]		{
				TOKEN;
				yylval.i = aton(yytext,2,valid_b,'B');
				return t_IMM;
			}

{oct}+[Oo]		{
				TOKEN;
				yylval.i = aton(yytext,8,valid_o,'O');
				return t_IMM;
			}

{dec}+[Dd]?		{
				TOKEN;
				yylval.i = aton(yytext,10,valid_d,'D');
				return t_IMM;
			}

{hex}+[Hh]		{
				TOKEN;
				yylval.i = aton(yytext,16,valid_x,'H');
				return t_IMM;
			}

"0"[Bb]{bin}+		{
				TOKEN;
				yylval.i = aton(yytext+2,2,valid_b,0);
				return t_IMM;
			}

"0"[Xx]{hex}+		{
				TOKEN;
				yylval.i = aton(yytext+2,16,valid_x,0);
				return t_IMM;
			}

"$"			{ TOKEN; yylval.i = PC; return t_IMM; }
","			{ TOKEN; return COMMA; }
":"                     { TOKEN; return COLON; }
"("			{ TOKEN; return LPAREN; }
")"			{ TOKEN; return RPAREN; }
"'"			{ TOKEN; return QUOTE; }
"+"			{ TOKEN; return PLUS; }
"-"			{ TOKEN; return MINUS; }
"*"			{ TOKEN; return MUL; }
"/"			{ TOKEN; return DIV; }
"%"			{ TOKEN; return MOD; }
"<<"			{ TOKEN; return SHL; }
">>"			{ TOKEN; return SHR; }
"&"                     { TOKEN; return AND; }
"|"                     { TOKEN; return OR; }
"^"                     { TOKEN; return XOR; }
"~"                     { TOKEN; return NOT; }

\"[^\"\n]+\"            {	/* anything enclosed in double quotes, w/o CR */
				TOKEN;
				yylval.s = strdup(yytext + 1);
				yylval.s[strlen(yylval.s)-1] = '\0';
				return t_STR;
			}

\'[^\'\n]+\'		{	/* anything enclosed in single quotes, w/o CR */
				TOKEN;
				yylval.i = yytext[1];
				if (yyleng > 3)
					yylval.i += 256 * yytext[2];
				return t_IMM;
			}

{alpha}{alnum}*		{	/* alpha followed by alpha numerical */
				TOKEN;
				yylval.s = strdup(yytext);
				return t_SYM;
			}

[\t ]			{	/* white space */
				TOKEN;
			}

";"[^\n]*\n		|	/* comment until CR */
[\n]			{	/* CR */
				TOKEN;
				if (plst) {
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

void yyerror(char * msg, ...)
{
	va_list arg;
	fprintf(stderr, "line %d: ", line_no);
	va_start(arg, msg);
	fprintf(stderr, msg, arg);
	va_end(arg);
	fprintf(stderr, " at \"%s\"\n", yytext);
}

int yywrap(void)
{
	if (pass_no < 2) {
		rewind(inpfile);
		PC = 0;
		line_no = 1;
		pass_no++;
		printf("pass %d\n", pass_no);
		return 0;
	}
	return 1;
}

