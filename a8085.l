%{
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include "a8085.tab.h"

extern char lstbuff[256];
extern char *plst;
extern int line_no;
extern int pass_no;
extern FILE *inpfile;
extern uint16_t PC;
extern void pass2(void);

static const char *valid_b = "01";
static const char *valid_o = "01234567";
static const char *valid_d = "0123456789";
static const char *valid_x = "0123456789ABCDEF";
int aton(char *src, int base, const char *valid, char end);

#define	TOKEN do { \
	if (!plst) \
		break; \
	plst += snprintf(plst, sizeof(lstbuff) - (size_t)(plst - lstbuff), "%s", yytext); \
} while (0)

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

[Ss][Pp]		{ TOKEN; return t_SP; }
[Pp][Ss][Ww]		{ TOKEN; return t_PSW; }

[Bb]			{ TOKEN; return t_B; }
[Cc]			{ TOKEN; return t_C; }
[Dd]			{ TOKEN; return t_D; }
[Ee]			{ TOKEN; return t_E; }
[Hh]			{ TOKEN; return t_H; }
[Ll]			{ TOKEN; return t_L; }
[Mm]			{ TOKEN; return t_M; }
[Aa]			{ TOKEN; return t_A; }

[Nn][Oo][Pp]		{ TOKEN; return t_NOP; }
[Rr][Aa][Ll]		{ TOKEN; return t_RAL; }
[Rr][Aa][Rr]		{ TOKEN; return t_RAR; }
[Rr][Ll][Cc]		{ TOKEN; return t_RLC; }
[Rr][Rr][Cc]		{ TOKEN; return t_RRC; }
[Dd][Aa][Aa]		{ TOKEN; return t_DAA; }
[Cc][Mm][Aa]		{ TOKEN; return t_CMA; }
[Ss][Tt][Cc]		{ TOKEN; return t_STC; }
[Cc][Mm][Cc]		{ TOKEN; return t_CMC; }

[Ll][Xx][Ii]		{ TOKEN; return t_LXI; }
[Dd][Aa][Dd]		{ TOKEN; return t_DAD; }
[Ss][Tt][Aa]		{ TOKEN; return t_STA; }
[Ss][Tt][Aa][Xx]	{ TOKEN; return t_STAX; }
[Ss][Hh][Ll][Dd]	{ TOKEN; return t_SHLD; }
[Ii][Nn][Xx]		{ TOKEN; return t_INX; }
[Ii][Nn][Rr]		{ TOKEN; return t_INR; }
[Mm][Vv][Ii]		{ TOKEN; return t_MVI; }

[Ll][Dd][Aa]		{ TOKEN; return t_LDA; }
[Ll][Dd][Aa][Xx]	{ TOKEN; return t_LDAX; }
[Ll][Hh][Ll][Dd]	{ TOKEN; return t_LHLD; }
[Dd][Cc][Xx]		{ TOKEN; return t_DCX; }
[Dd][Cc][Rr]		{ TOKEN; return t_DCR; }

[Mm][Oo][Vv]		{ TOKEN; return t_MOV; }
[Hh][Ll][Tt]		{ TOKEN; return t_HLT; }

[Aa][Dd][Dd]		{ TOKEN; return t_ADD; }
[Aa][Dd][Cc]		{ TOKEN; return t_ADC; }
[Ss][Uu][Bb]		{ TOKEN; return t_SUB; }
[Ss][Bb][Bb]		{ TOKEN; return t_SBB; }
[Aa][Nn][Aa]		{ TOKEN; return t_ANA; }
[Oo][Rr][Aa]		{ TOKEN; return t_ORA; }
[Xx][Rr][Aa]		{ TOKEN; return t_XRA; }
[Cc][Mm][Pp]		{ TOKEN; return t_CMP; }

[Rr][Ee][Tt]		{ TOKEN; return t_RET; }
[Rr][Nn][Cc]		{ TOKEN; return t_RNC; }
[Rr][Cc]		{ TOKEN; return t_RC; }
[Rr][Nn][Zz]		{ TOKEN; return t_RNZ; }
[Rr][Zz]		{ TOKEN; return t_RZ; }
[Rr][Pp][Oo]		{ TOKEN; return t_RPO; }
[Rr][Pp][Ee]		{ TOKEN; return t_RPE; }
[Rr][Pp]		{ TOKEN; return t_RP; }
[Rr][Mm]		{ TOKEN; return t_RM; }

[Jj][Mm][Pp]		{ TOKEN; return t_JMP; }
[Jj][Nn][Cc]		{ TOKEN; return t_JNC; }
[Jj][Cc]		{ TOKEN; return t_JC; }
[Jj][Nn][Zz]		{ TOKEN; return t_JNZ; }
[Jj][Zz]		{ TOKEN; return t_JZ; }
[Jj][Pp][Oo]		{ TOKEN; return t_JPO; }
[Jj][Pp][Ee]		{ TOKEN; return t_JPE; }
[Jj][Pp]		{ TOKEN; return t_JP; }
[Jj][Mm]		{ TOKEN; return t_JM; }

[Cc][Aa][Ll][Ll]	{ TOKEN; return t_CALL; }
[Cc][Nn][Cc]		{ TOKEN; return t_CNC; }
[Cc][Cc]		{ TOKEN; return t_CC; }
[Cc][Nn][Zz]		{ TOKEN; return t_CNZ; }
[Cc][Zz]		{ TOKEN; return t_CZ; }
[Cc][Pp][Oo]		{ TOKEN; return t_CPO; }
[Cc][Pp][Ee]		{ TOKEN; return t_CPE; }
[Cc][Pp]		{ TOKEN; return t_CP; }
[Cc][Mm]		{ TOKEN; return t_CM; }

[Aa][Dd][Ii]		{ TOKEN; return t_ADI; }
[Aa][Cc][Ii]		{ TOKEN; return t_ACI; }
[Ss][Uu][Ii]		{ TOKEN; return t_SUI; }
[Ss][Bb][Ii]		{ TOKEN; return t_SBI; }
[Aa][Nn][Ii]		{ TOKEN; return t_ANI; }
[Oo][Rr][Ii]		{ TOKEN; return t_ORI; }
[Xx][Rr][Ii]		{ TOKEN; return t_XRI; }
[Cc][Pp][Ii]		{ TOKEN; return t_CPI; }

[Dd][Ii]		{ TOKEN; return t_DI; }
[Ee][Ii]		{ TOKEN; return t_EI; }
[Ii][Nn]		{ TOKEN; return t_IN; }
[Oo][Uu][Tt]		{ TOKEN; return t_OUT; }
[Pp][Oo][Pp]		{ TOKEN; return t_POP; }
[Pp][Uu][Ss][Hh]	{ TOKEN; return t_PUSH; }
[Rr][Ss][Tt]		{ TOKEN; return t_RST; }
[Xx][Cc][Hh][Gg]	{ TOKEN; return t_XCHG; }
[Xx][Tt][Hh][Ll]	{ TOKEN; return t_XTHL; }

[Dd][Bb]		{ TOKEN; return t_DB; }
[Dd][Ee][Ff][Bb]	{ TOKEN; return t_DEFB; }
[Dd][[Ww]		{ TOKEN; return t_DW; }
[Dd][Ee][Ff][Ww]	{ TOKEN; return t_DEFW; }
[Dd][Dd]		{ TOKEN; return t_DD; }
[Dd][Ee][Ff][Dd]	{ TOKEN; return t_DEFD; }
[Dd][Ee][Ff][Ll]	{ TOKEN; return t_DEFL; }
[Dd][Ee][Ff][Mm]	{ TOKEN; return t_DEFM; }
[Dd][Ss]		{ TOKEN; return t_DS; }
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

"0"[Xx]{hex}+		{
				TOKEN;
				yylval.i = aton(yytext,16,valid_x,0);
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

\'[^\'\n]+\'		{	/* anything enclosed in quotes, w/o CR */
				TOKEN;
				yylval.i = yytext[1];
				if (yyleng > 3)
					yylval.i += 256 * yytext[2];
				return t_IMM;
			}

{alpha}{alnum}*		{	/* seqeuence of alnum starting witn alpha */
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
				if (plst)
					plst = lstbuff;
				BEGIN(INITIAL);
				line_no++;
				return EOL;
			}

%%

int aton(char *src, int base, const char *valid, char end)
{
	int result = 0;
	int sign = 1;
	char * pos;

	while (*src && !strchr(valid, toupper(*src)) && (toupper(*src) != end)) {
		if (*src == '+')
			sign = +1;
		if (*src == '-')
			sign = -sign;
		src++;
	}
	while (*src && ((pos = strchr(valid, toupper(*src))) != NULL)) {
		result *= base;
		if (pos)
			result += (int)(pos - valid);
		src++;
	}
	result *= sign;
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
		pass2();
		return 0;
	}
	return 1;
}

