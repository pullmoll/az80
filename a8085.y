%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdbool.h>
#include <ctype.h>
#include <limits.h>

#define TAPE_EXT ".co"
#define DDEC_EXT ".dec"

typedef uint8_t  byte;
typedef	uint16_t word;

typedef	struct	symbol_s {
    struct symbol_s *next;
    int pass_no;
    int64_t value;
    int refs;
    int *line_no;
    char *name;
}   symbol_t;

void emit(void);
void pass2(void);

void addsym(char * name, int value);
int getsym(char * name);

int symb_no = 0;
int line_no = 1;
int pass_no = 1;
byte opcode = 0x00;
byte arg[64*1024] = {0, };
bool expflg  = 0;	/* print expression result */
bool opcode_flag  = 0;
bool ofsflg  = 0;
int argcnt  = 0;
word eexp = 0;
word PC	= 0;
word end = 0;
word tmp = 0;

char lstbuff[256+1] = "";
char *plst  = NULL;

symbol_t *sym = NULL;
symbol_t *sym0 = NULL;

char inpname[PATH_MAX] = "";
char outname[PATH_MAX] = "";
char lstname[PATH_MAX] = "";

FILE *inpfile = NULL;
FILE *outfile = NULL;
FILE *lstfile = NULL;

bool f_list  = false;
bool f_tape  = false;
bool f_ddec  = false;
bool f_syms  = false;
bool f_xref  = false;
bool f_first = false;

char tape_name[6+1];
byte tape_buf[256];
byte tape_csum = 0;
word tape_base = 0;
word tape_entry = 0;
word tape_end = 0;
word tape_pc  = 0;

word ddec_csum = 0;
word ddec_count = 0;

%}

%start	file

%union {
	int64_t i;
	char* s;
}

%token		EOL COMMA COLON LPAREN RPAREN QUOTE PLUS MINUS MUL DIV MOD
%token		SHL SHR AND OR XOR NOT

%token		t_B t_C t_D t_E t_H t_L t_M t_A
%token		t_SP t_PSW

%token	<i>	t_IMM
%token	<s>	t_SYM
%token	<s>	t_STR

%token		t_ACI t_ADC t_ADD t_ADI t_ANA t_ANI t_ARHL
%token		t_CALL t_CC t_CM t_CMA t_CMC t_CMP t_CNC t_CNZ t_CP t_CPE t_CPI t_CPO t_CZ
%token		t_DAA t_DAD t_DCR t_DCX t_DI t_DSUB
%token		t_EI
%token		t_HLT
%token		t_IN t_INR t_INX
%token		t_JC t_JM t_JMP t_JNC t_JNX t_JNZ t_JP t_JPE t_JPO t_JX t_JZ
%token		t_LDA t_LDAX t_LDHI t_LDSI t_LHLD t_LHLX t_LXI
%token		t_MOV t_MVI
%token		t_NOP
%token		t_ORA t_ORI t_OUT
%token		t_PCHL t_POP t_PUSH
%token		t_RAL t_RAR t_RC t_RET t_RIM t_RLC t_RLDE t_RM t_RNC t_RNZ t_RP t_RPE t_RPO t_RRC t_RST t_RSTV t_RZ
%token		t_SBB t_SBI t_SHLD t_SHLX t_SIM t_SPHL t_STA t_STAX t_STC t_SUB t_SUI
%token		t_XCHG t_XRA t_XRI t_XTHL

%token		t_DB t_DW t_DD t_DS t_DEFB t_DEFL t_DEFM t_DEFS t_DEFW t_DEFD
%token		t_ALIGN t_END t_EQU t_EVEN t_ORG

%type	<i>	expr simple term factor

%%

file	:	line
	|	line error
	;

line	:	line token
		{
		    emit();
		}
	|	token
		{
		    emit();
		}
	;

token	:	EOL
		{
		    opcode_flag = false;
		}
	|	t_SYM
		{
		    opcode_flag = false;
		    addsym($1, PC);
		    free($1);
		}
	|	t_SYM COLON
		{
		    opcode_flag = false;
		    addsym($1, PC);
		    free($1);
		}
	|	t_SYM	t_EQU imm16			EOL
		{
		    opcode_flag = false;
		    argcnt = 0;
		    expflg = 1;
		    eexp = arg[0] + 256 * arg[1];
		    addsym($1,eexp);
		    free($1);
		}
	|	t_SYM	t_DEFL imm16			EOL
		{
		    opcode_flag = false;
		    argcnt = 0;
		    expflg = 1;
		    eexp = arg[0] + 256 * arg[1];
		    addsym($1, eexp);
		    free($1);
		}
	|	t_ADC	s08				EOL
		{
		    opcode |= 0x88;
		}
	|	t_ACI	imm8				EOL
		{
		    opcode = 0xCE;
		}
	|	t_ADD	s08				EOL
		{
		    opcode |= 0x80;
		}
	|	t_ADI	imm8				EOL
		{
		    opcode = 0xC6;
		}
	|	t_DAD	r16				EOL
		{
		    opcode |= 0x09;
		}
	|	t_ANA	s08				EOL
		{
		    opcode |= 0xA0;
		}
	|	t_ANI	imm8				EOL
		{
		    opcode = 0xE6;
		}
	|	t_CALL	imm16				EOL
		{
		    opcode = 0xCD;
		}
	|	t_CNZ	imm16				EOL
		{
		    opcode |= 0xC4;
		}
	|	t_CZ	imm16				EOL
		{
		    opcode |= 0xCC;
		}
	|	t_CNC	imm16				EOL
		{
		    opcode |= 0xD4;
		}
	|	t_CC	imm16				EOL
		{
		    opcode |= 0xDC;
		}
	|	t_CPO	imm16				EOL
		{
		    opcode |= 0xE4;
		}
	|	t_CPE	imm16				EOL
		{
		    opcode |= 0xEC;
		}
	|	t_CP	imm16				EOL
		{
		    opcode |= 0xF4;
		}
	|	t_CM	imm16				EOL
		{
		    opcode |= 0xFC;
		}
	|	t_CMC					EOL
		{
		    opcode = 0x3F;
		}
	|	t_CMP	s08				EOL
		{
		    opcode |= 0xB8;
		}
	|	t_CPI	imm8				EOL
		{
		    opcode = 0xFE;
		}
	|	t_CMA					EOL
		{
		    opcode = 0x2F;
		}
	|	t_DAA					EOL
		{
		    opcode = 0x27;
		}
	|	t_DCR	s08				EOL
		{
		    opcode = (opcode << 3) | 0x05;
		}
	|	t_DCX	r16				EOL
		{
		    opcode |= 0x0B;
		}
	|	t_DI					EOL
		{
		    opcode = 0xF3;
		}
	|	t_EI					EOL
		{
		    opcode = 0xFB;
		}
	|	t_XCHG					EOL
		{
		    opcode = 0xEB;
		}
	|	t_XTHL					EOL
		{
		    opcode = 0xE3;
		}
	|	t_HLT					EOL
		{
		    opcode = 0x76;
		}
	|	t_IN	imm8				EOL
		{
		    opcode = 0xDB;
		}
	|	t_INR	s08				EOL
		{
		    opcode = (opcode << 3) | 0x04;
		}
	|	t_INX	r16				EOL
		{
		    opcode |= 0x03;
		}
	|	t_JMP	imm16				EOL
		{
		    opcode = 0xC3;
		}
	|	t_JNZ	imm16				EOL
		{
		    opcode |= 0xC2;
		}
	|	t_JZ	imm16				EOL
		{
		    opcode |= 0xCA;
		}
	|	t_JNC	imm16				EOL
		{
		    opcode |= 0xD2;
		}
	|	t_JC	imm16				EOL
		{
		    opcode |= 0xDA;
		}
	|	t_JPO	imm16				EOL
		{
		    opcode |= 0xE2;
		}
	|	t_JPE	imm16				EOL
		{
		    opcode |= 0xEA;
		}
	|	t_JP	imm16				EOL
		{
		    opcode |= 0xF2;
		}
	|	t_JM	imm16				EOL
		{
		    opcode |= 0xFA;
		}
	|	t_LXI	r16 COMMA imm16			EOL
		{
		    opcode |= 0x01;
		}
	|	t_SPHL					EOL
		{
		    opcode = 0xE3;
		}
	|	t_MOV	r08 COMMA s08			EOL
		{
		    opcode |= 0x40;
		}
	|	t_MVI	r08 COMMA imm8			EOL
		{
		    opcode |= 0x06;
		}
	|	t_STAX	t_B				EOL
		{
		    opcode = 0x02;
		}
	|	t_LDAX	t_B				EOL
		{
		    opcode = 0x0A;
		}
	|	t_STAX	t_D				EOL
		{
		    opcode = 0x12;
		}
	|	t_LDAX	t_D				EOL
		{
		    opcode = 0x1A;
		}
	|	t_SHLD	imm16				EOL
		{
		    opcode = 0x22;
		}
	|	t_LHLD	imm16				EOL
		{
		    opcode = 0x2A;
		}
	|	t_STA	imm16				EOL
		{
		    opcode = 0x32;
		}
	|	t_LDA	imm16				EOL
		{
		    opcode = 0x3A;
		}
	|	t_PCHL					EOL
		{
		    opcode = 0xE9;
		}
	|	t_NOP					EOL
		{
		    opcode = 0x00;
		}
	|	t_ORA	s08				EOL
		{
		    opcode |= 0xB0;
		}
	|	t_ORI	imm8				EOL
		{
		    opcode = 0xF6;
		}
	|	t_OUT	imm8				EOL
		{
		    opcode = 0xD3;
		}
	|	t_POP	r16pp				EOL
		{
		    opcode |= 0xC1;
		}
	|	t_PUSH	r16pp				EOL
		{
		    opcode |= 0xC5;
		}
	|	t_RET					EOL
		{
		    opcode = 0xC9;
		}
	|	t_RNZ					EOL
		{
		    opcode |= 0xC0;
		}
	|	t_RZ					EOL
		{
		    opcode |= 0xC8;
		}
	|	t_RNC					EOL
		{
		    opcode |= 0xD0;
		}
	|	t_RC					EOL
		{
		    opcode |= 0xD8;
		}
	|	t_RPO					EOL
		{
		    opcode |= 0xE0;
		}
	|	t_RPE					EOL
		{
		    opcode |= 0xE8;
		}
	|	t_RP					EOL
		{
		    opcode |= 0xF0;
		}
	|	t_RM					EOL
		{
		    opcode |= 0xF8;
		}
	|	t_RAL					EOL
		{
		    opcode = 0x17;
		}
	|	t_RLC					EOL
		{
		    opcode = 0x07;
		}
	|	t_RAR					EOL
		{
		    opcode = 0x1F;
		}
	|	t_RRC					EOL
		{
		    opcode = 0x0F;
		}
	|	t_RST	rst				EOL
		{
		    opcode |= 0xC7;
		}
	|	t_SBB	s08				EOL
		{
		    opcode |= 0x98;
		}
	|	t_SBI	imm8				EOL
		{
		    opcode = 0xDE;
		}
	|	t_STC					EOL
		{
		    opcode = 0x37;
		}
	|	t_SUB	s08				EOL
		{
		    opcode |= 0x90;
		}
	|	t_SUI	imm8				EOL
		{
		    opcode |= 0xD6;
		}
	|	t_XRA	s08				EOL
		{
		    opcode |= 0xA8;
		}
	|	t_XRI	imm8				EOL
		{
		    opcode = 0xEE;
		}
	|	t_DB	imm8l				EOL
		{
		    opcode_flag = false;
		}
	|	t_DW	imm16l				EOL
		{
		    opcode_flag = false;
		}
	|	t_DD	imm32l				EOL
		{
		    opcode_flag = false;
		}
	|	t_DS	imm16				EOL
		{
		    opcode_flag = false;
		    argcnt = arg[0] + 256 * arg[1];
		    if (argcnt > sizeof(arg)) {
			fprintf(stderr, "line (%d) warning: size clipped to assembler limits (%d : %d)\n", line_no, argcnt, sizeof(arg));
			argcnt = sizeof(arg);
		    }
		    memset(arg, 0, argcnt);
		}
	|	t_DEFB	imm8l				EOL
		{
		    opcode_flag = false;
		}
	|	t_DEFW	imm16l				EOL
		{
		    opcode_flag = false;
		}
	|	t_DEFD	imm32l				EOL
		{
		    opcode_flag = false;
		}
	|	t_DEFS	imm16				EOL
		{
		    opcode_flag = false;
		    argcnt = arg[0] + 256 * arg[1];
		    if (argcnt > sizeof(arg)) {
			fprintf(stderr, "line (%d) warning: size clipped to assembler limits (%d : %d)\n", line_no, argcnt, sizeof(arg));
			argcnt = sizeof(arg);
		    }
		    memset(arg, 0, argcnt);
		}
	|	t_DEFM	strlist				EOL
		{
		    opcode_flag = false;
		}
	|	t_ORG	imm16				EOL
		{
		    opcode_flag = false;
		    argcnt = 0;
		    expflg = 1;
		    eexp = arg[0] + 256 * arg[1];
		    PC = eexp;
		}
	|	t_ALIGN	imm8				EOL
		{
		    opcode_flag = false;
		    argcnt = 0;
		    expflg = 1;
		    eexp = PC;
		    tmp = arg[0] - 1;
		    while (PC & tmp) {
			    arg[argcnt++] = 0;
		    }
		}
	|	t_EVEN					EOL
		{
		    opcode_flag = false;
		    argcnt = 0;
		    expflg = 1;
		    eexp = PC;
		    if (PC & 1) {
			    arg[argcnt++] = 0;
		    }
		}
	|	t_END	imm16				EOL
		{
		    opcode_flag = false;
		    argcnt = 0;
		    expflg = 1;
		    eexp = arg[0] + 256 * arg[1];
		    tape_end = PC;
		    end = eexp;
		}
	;

s08	:	t_B { opcode |= 0x00; }
	|	t_C { opcode |= 0x01; }
	|	t_D { opcode |= 0x02; }
	|	t_E { opcode |= 0x03; }
	|	t_H { opcode |= 0x04; }
	|	t_L { opcode |= 0x05; }
	|	t_M { opcode |= 0x06; }
	|	t_A { opcode |= 0x07; }
	;

r08	:	t_B { opcode |= 0x00; }
	|	t_C { opcode |= 0x08; }
	|	t_D { opcode |= 0x10; }
	|	t_E { opcode |= 0x18; }
	|	t_H { opcode |= 0x20; }
	|	t_L { opcode |= 0x28; }
	|	t_M { opcode |= 0x30; }
	|	t_A { opcode |= 0x38; }
	;

r16	:	t_B { opcode |= 0x00; }
	|	t_D { opcode |= 0x10; }
	|	t_H { opcode |= 0x20; }
	|	t_SP { opcode |= 0x30; }
	;

r16pp	:	t_B { opcode |= 0x00; }
	|	t_D { opcode |= 0x10; }
	|	t_H { opcode |= 0x20; }
	|	t_PSW { opcode |= 0x30; }
	;

expr	:	simple
		{
		    $$ = $1;
		}
	|	expr SHL simple
		{
		    $$ = $1 << $3;
		}
	|	expr SHR simple
		{
		    $$ = $1 >> $3;
		}
	;

simple	:	term
		{
		    $$ = $1;
		}
	|	simple PLUS term
		{
		    $$ = $1 + $3;
		}
	|	simple MINUS term
		{
		    $$ = $1 - $3;
		}
	|	simple AND term
		{
		    $$ = $1 & $3;
		}
	;

term	:	factor
		{
		    $$ = $1;
		}
	|	PLUS factor
		{
		    $$ = $2;
		}
	|	MINUS factor
		{
		    $$ = -$2;
		}
	|	NOT factor
		{
		    $$ = ~$2;
		}
	|	term MUL factor
		{
		    $$ = $1 * $3;
		}
	|	term DIV factor
		{
		    $$ = $1 / $3;
		}
	|	term MOD factor
		{
		    $$ = $1 % $3;
		}
	|	term OR factor
		{
		    $$ = $1 | $3;
		}
	|	term XOR factor
		{
		    $$ = $1 ^ $3;
		}
	;

factor	:	t_IMM
		{
		    $$ = $1;
		}
	|	t_SYM
		{
		    $$ = getsym($1);
		    free($1);
		}
	|	LPAREN expr RPAREN
		{
		    $$ = $2;
		}
	;

imm8	:	expr
		{
		    if ($1 < -255 || $1 > 255) {
			    fprintf(stderr, "line (%d) warning: size exceeds BYTE (%d)\n", line_no, $1);
		    }
		    arg[argcnt++] = $1;
		}
	;

imm8l	:	imm8 COMMA imm8l
	|	imm8
	;

imm16	:	expr
		{
		    if ($1 < -65535 || $1 > 65535) {
			    fprintf(stderr, "line (%d) warning: size exceeds WORD (%d)\n", line_no, $1);
		    }
		    arg[argcnt++] = $1 % 256;
		    arg[argcnt++] = ($1 >> 8) % 256;
		}
	;

imm16l	:	imm16 COMMA imm16l
	|	imm16
	;

imm32	:	expr
		{
		    if ($1 < -2147483648ll || $1 > 21474836647ll) {
			    fprintf(stderr, "line (%d) warning: size exceeds DWORD (%d)\n", line_no, $1);
		    }
		    arg[argcnt++] = $1 % 256;
		    arg[argcnt++] = ($1 >> 8) % 256;
		    arg[argcnt++] = ($1 >> 16) % 256;
		    arg[argcnt++] = ($1 >> 24) % 256;
		}
	;

imm32l	:	imm32 COMMA imm32
	|	imm32
	;

str	:	t_STR
		{
		    int len = snprintf(arg + argcnt, sizeof(arg) - argcnt, "%s", $1);
		    if (len < strlen($1)) {
			fprintf(stderr, "line (%d) warning: string overflow ('%s')\n", line_no, $1);
		    }
		    argcnt += len;
		    free($1);
		}
	|	imm8
	;

strlist	:	str COMMA strlist
	|	str
	;

rst	:	expr
		{
		    if ($1 < 0 || $1 > 7) {
			    fprintf(stderr, "line (%d) invalid RST number %d\n", line_no, $1);
		    }
		    opcode |= ($1) << 3;
		}
	;
%%

int list(char * fmt, ...)
{
    va_list arg;
    int rc = 0;

    if (!f_list) {
	return rc;
    }

    if (pass_no < 2) {
	return rc;
    }

    va_start(arg, fmt);
    rc = vfprintf(lstfile, fmt, arg);
    va_end(arg);
    return rc;
}

void tape_name_conv(const char *src)
{
    int i;

    for (i = 0; i < 6; i++) {
	char ch = toupper(*src);
	if (*src && isalnum(ch)) {
	    tape_name[i] = ch;
	    src++;
	} else {
	    tape_name[i] = ' ';
	}
    }
    tape_name[i] = '\0';
}

void tape_flush(void)
{
    int i;

    /* write all data */
    // done

    /* write checksum over c */
    tape_csum = -tape_csum;
    fputc(tape_csum, outfile);
    tape_csum = 0;

    /* e - write 20 times 0x00 */
    for (i = 0; i < 20; i++) {
	fputc(0x00, outfile);
    }
}

void ddec_flush(void)
{
    if (ddec_count > 0) {
	int i;
	for (i = ddec_count; i < 15; i++) {
	    fprintf(outfile, ",0");
	}
	fprintf(outfile, ",%u\r\n", ddec_csum);
	ddec_csum = 0;
	ddec_count = 0;
    }
}

int outch(byte c)
{
    int rc = 0;

    if (0 == tape_base) {
	tape_pc = PC;
	tape_base = PC;
	tape_csum = 0;
    }

    if (pass_no == 1) {
	PC++;
	return rc;
    }

    rc = list("%02X ", c);
    if (f_tape) {
	fputc(c, outfile);
	tape_csum += c;
	tape_pc++;
    } else if (f_ddec) {
	fprintf(outfile, "%s%d",
		ddec_count ? "," : "", c);
	ddec_csum += c;
	if (++ddec_count == 15) {
	    fprintf(outfile, ",%d\r\n",
		    ddec_csum);
	    ddec_csum = 0;
	    ddec_count = 0;
	}
    } else {
	fputc(c, outfile);
    }
    PC++;
    return rc;
}

void emit(void)
{
	int i;
	int x = 0;

	if (opcode_flag || argcnt)
		x += list("%04X: ", PC);

	if (opcode_flag)
		x += outch(opcode);
	for (i = 0; i < argcnt && i < 8; i++)
		x += outch(arg[i]);
	if (strchr(lstbuff, '\n')) {
		if (!(opcode_flag || argcnt) && expflg)
			x += list("=%04X ", eexp);
		if (x >= 0 && x < 32)
			list("%*s", 32 - x, " ");
		list("%s", lstbuff);
	}
	if (argcnt > 8) {
		for (i = 8; i < argcnt; i++) {
			if ((i & 7) == 0)
				x = list("%04X: ", PC);
			x += outch(arg[i]);
			if ((i & 7) == 7)
				x += list("\n");
		}
		if (i & 7)
			x += list("\n");
	}
	opcode = 0;
	expflg = 0;
	opcode_flag = 1;
	ofsflg = 0;
	argcnt = 0;
}

void pass2(void)
{
    tape_entry = end;

    if (f_tape) {
	byte ch;
	int i;

	printf("Name  : %s\n", tape_name);
	printf("Base  : %04xH (%u)\n", tape_base, tape_base);
	printf("End   : %04xH (%u)\n", tape_end, tape_end);
	printf("Entry : %04xH (%u)\n", tape_entry, tape_entry);

	/* write 511 times 0x55 */
	for (i = 0; i < 511; i++) {
	    fputc(0x55, outfile);
	}

	/* write once 0x7f */
	fputc(0x7f, outfile);

	/* write .CO file identifier 0xd0 */
	fputc(0xd0, outfile);

	/* write 6 characters name (uppercase) */
	for (i = 0; i < 6; i++) {
	    ch = toupper(tape_name[i]);
	    tape_csum += ch;
	    fputc(ch, outfile);
	}

	/* write load address LSB, MSB */
	ch = tape_base % 256;
	tape_csum += ch;
	fputc(ch, outfile);
	ch = tape_base / 256;
	tape_csum += ch;
	fputc(ch, outfile);

	/* write length LSB, MSB */
	ch = (tape_end - tape_base) % 256;
	tape_csum += ch;
	fputc(ch, outfile);
	ch = (tape_end - tape_base) / 256;
	tape_csum += ch;
	fputc(ch, outfile);

	/* write entry point LSB, MSB */
	ch = tape_entry % 256;
	tape_csum += ch;
	fputc(ch, outfile);
	ch = tape_entry / 256;
	tape_csum += ch;
	fputc(ch, outfile);

	/* write 4 times 0x00 */
	for (i = 0; i < 4; i++) {
	    fputc(0x00, outfile);
	    tape_csum += 0x00;
	}

	/* write checksum over name, base, size, entry + 00s */
	tape_csum = - tape_csum;
	fputc(tape_csum, outfile);

	/* write 20 times 0x00 */
	for (i = 0; i < 20; i++) {
	    fputc(0x00, outfile);
	}

	/* write 511 times 0x55 */
	for (i = 0; i < 511; i++) {
	    fputc(0x55, outfile);
	}

	/* write once 0x7f */
	fputc(0x7f, outfile);

	/* write once 0x8d */
	fputc(0x8d, outfile);

	/* reset checksum */
	tape_csum = 0;
	return;
    }

    if (f_ddec) {
	/* Dekker's .DEC format */
	fprintf(outfile, "%u,%u,%u\r\n",
		tape_base, tape_end, tape_entry);
	ddec_csum = 0;
	ddec_count = 0;
    }
}

void addsym(char * name, int value)
{
    symbol_t *s, *s0, *s1;
    for (s = sym; (s); s = s->next) {
	if (strcasecmp(name, s->name) == 0) {
	    if (s->pass_no == pass_no) {
		fprintf(stderr, "line (%d) warning: double defined symbol %s\n",
			line_no, name);
	    }
	    s->line_no[0] = line_no;
	    s->pass_no = pass_no;
	    if (s->value != value) {
		fprintf(stderr, "line (%d) warning: %s has different value on pass 2\n",
			line_no, name);
	    }
	    s->value   = value;
	    return;
	}
    }
    for (s0 = NULL, s1 = sym; (s1); s0 = s1, s1 = s1->next)
	if (strcasecmp(name, s1->name) <= 0)
	    break;
    s = (symbol_t *) calloc(1, sizeof(symbol_t));
    if (!s) {
	fprintf(stderr, "error: out of memory!\n");
	exit(1);
    }
    s->next = s1;
    s->pass_no = pass_no;
    s->refs = 0;
    s->line_no = malloc(sizeof(int));
    *s->line_no = line_no;
    s->value = value;
    s->name = strdup(name);
    if (s0)
	s0->next = s;
    else
	sym = s;
    symb_no++;
}

int getsym(char * name)
{
    symbol_t *s;
    for (s = sym; (s); s = s->next) {
	if (strcasecmp(name, s->name) == 0) {
	    if (pass_no > 1) {
		s->refs += 1;
		s->line_no = (int *) realloc(s->line_no, (s->refs + 1) * sizeof(int));
		s->line_no[s->refs] = line_no;
	    }
	    return s->value;
	}
    }
    if (pass_no > 1)
	fprintf(stderr, "line (%d) undefined symbol: %s\n",
		line_no, name);
    return 0;
}

void prtsym(FILE * filp)
{
    symbol_t * s;
    int i;
    for (s = sym; (s); s = s->next) {
	fprintf(filp, "%-32.32s%04X line %d, %d references\n",
		s->name, s->value, s->line_no[0], s->refs);
	if (f_xref) {
	    if (s->refs > 0) {
		for (i = 0; i < s->refs; i++) {
		    if ((i & 7) == 0)
			fprintf(filp, "	 ");
		    fprintf(filp, "%d ", s->line_no[i+1]);
		    if ((i & 7) == 7)
			fprintf(filp,"\n");
		}
		if (i & 7)
		    fprintf(filp, "\n");
	    }
	}
    }
}

int main(int ac, char ** av)
{
    int i;
    char * p;

    if (ac < 2) {
	fprintf(stderr, "usage:\ta8085 [options] input[.asm] [output[.bin]] [listing[.lst]]\n");
	fprintf(stderr, "options can be one or more of:\n");
	fprintf(stderr, "-d\tgenerate parser debug output to stderr\n");
	fprintf(stderr, "-l\tgenerate listing (to file input.lst)\n");
	fprintf(stderr, "-s\toutput symbol table\n");
	fprintf(stderr, "-x\toutput cross reference with symbol table\n");
	fprintf(stderr, "-e\tgenerate Kurt W. Dekker's .dec output\n");
	fprintf(stderr, "-t[=name]\tgenerate Tandy Model 100 .co tape\n");
	exit(1);
    }

    for (i = 1; i < ac; i++) {
	if (av[i][0] == '-') {
	    switch (av[i][1]) {
	    case 'd': case 'D':
		yydebug = 1;
		break;
	    case 'l': case 'L':
		f_list = true;
		break;
	    case 's': case 'S':
		f_syms = true;
		break;
	    case 'x': case 'X':
		f_syms = true;
		f_xref = true;
		break;
	    case 'e': case 'E':
		f_ddec = true;
		break;
	    case 't': case 'T':
		f_tape = true;
		if (av[i][2] == '=') {
		    tape_name_conv(av[i] + 3);
		}
		break;
	    default:
		fprintf(stderr, "illegal option %s\n", av[i]);
		exit(1);
	    }
	} else if (!strlen(inpname)) {
	    strcpy(inpname, av[i]);
	} else if (!strlen(outname)) {
	    strcpy(outname, av[i]);
	} else if (!strlen(lstname)) {
	    strcpy(lstname, av[i]);
	} else {
	    fprintf(stderr, "additional argument %s ignored\n", av[i]);
	}
    }

    if (0 == strlen(inpname)) {
	fprintf(stderr, "input filename missing!\n");
	exit(1);
    }

    if (0 == strlen(outname)) {
	const char *ext = ".bin";
	if (f_tape) {
	    ext = TAPE_EXT;
	} else if (f_ddec) {
	    ext = DDEC_EXT;
	}
	strcpy(outname, inpname);
	p = strrchr(outname, '.');
	if (!p) {
	    p = outname + strlen(outname);
	}
	strcpy(p, ext);
    }

    if (f_tape) {
	if (!strlen(tape_name)) {
	    tape_name_conv(inpname);
	}
    }

    if (f_list) {
	if (!strlen(lstname)) {
	    strcpy(lstname, inpname);
	    p = strrchr(lstname, '.');
	    if (!p) {
		p = lstname + strlen(lstname);
	    }
	    strcpy(p, ".lst");
	}
    } else if (strlen(lstname)) {
	f_list = true;
	p = strrchr(lstname, '.');
	if (!p) {
	    p = lstname + strlen(lstname);
	}
	strcpy(p, ".lst");
    }
    p = strrchr(inpname, '.');
    if (!p) {
	strcat(inpname, ".asm");
    }

    inpfile = fopen(inpname, "r");
    if (!inpfile) {
	fprintf(stderr, "can't open %s\n", inpname);
	exit(1);
    }

    outfile = fopen(outname, "wb");
    if (!outfile) {
	fprintf(stderr, "can't create %s\n", outname);
	exit(1);
    }

    if (f_list) {
	lstfile = fopen(lstname, "w");
	if (!lstfile) {
	    fprintf(stderr, "can't create %s\n", outname);
	    exit(1);
	}
	plst = lstbuff;
	*plst = '\0';
    }

    printf("Assembling %s\npass 1\n", inpname);
    yyrestart(inpfile);
    yyparse();
    list("\n");

    if (f_syms) {
	prtsym((f_list) ? lstfile : stdout);
    }

    if (f_tape) {
	tape_flush();
    }

    if (f_ddec) {
	ddec_flush();
    }

    fclose(inpfile);
    fclose(outfile);

    if (f_list) {
	fclose(lstfile);
    }
    printf("%d lines, %d symbols\n", line_no, symb_no);

    return 0;
}
