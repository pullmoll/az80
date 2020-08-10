%{
#include "az80.h"

#define CG_TAPE_EXT ".cas"
#define VZ_TAPE_EXT ".vz"

void emit(void);

int arg_byte(int64_t val);
int arg_word(int64_t val);
int arg_dword(int64_t val);

int symb_no = 0;
int line_no = 1;
int pass_no = 1;
byte prefix = 0x00;
byte prefcb = 0x00;
byte opcode = 0x00;
int offset = 0x00;
byte arg[64*1024] = {0, };
bool f_expression  = false;	/* print expression result */
bool f_opcode  = false;
bool f_offset  = false;
int argcnt  = 0;
word eexp = 0;
word PC	= 0;
word end = 0;
word tmp = 0;

char* lstbuff = NULL;
char* plst = NULL;

char* macbuff = NULL;
size_t macsize = 0;
size_t macsmax = 0;

symbol_t *sym = NULL;
symbol_t *sym0 = NULL;

char title[256+1] = "";
char inpname[PATH_MAX+1] = "";
char outname[PATH_MAX+1] = "";
char lstname[PATH_MAX+1] = "";

FILE *inpfile = NULL;
FILE *outfile = NULL;
FILE *lstfile = NULL;

bool f_list = false;
bool f_tape = false;
bool f_tape_cg = false;
bool f_tape_vz = false;
bool f_syms = false;
bool f_xref = false;
bool f_first = false;

char tape_name[6+1];
byte tape_buf[256];
byte tape_crc = 0;
byte tape_cnt = 0;
word tape_adr = 0;
word tape_pc  = 0;

%}

%start	file

%union {
	int64_t i;
	char *s;
}

%token		EOL COMMA COLON LPAREN RPAREN QUOTE PLUS MINUS MUL DIV MOD
%token		SHL SHR AND OR XOR NOT

%token		t_B t_C t_D t_E t_H t_L t_M t_A t_F t_I t_R t_LX t_HX t_LY t_HY
%token		t_BC t_DE t_HL t_AF t_SP t_IX t_IY
%token		t_cNZ t_cZ t_cNC t_cC t_cPO t_cPE t_cP t_cM
%token		t_PORTC

%token	<i>	t_IMM
%token	<s>	t_SYM
%token	<s>	t_STR

%token		t_ADC t_ADD t_AND
%token		t_BIT
%token		t_CALL t_CCF t_CP t_CPD t_CPDR t_CPI t_CPIR t_CPL
%token		t_DAA t_DEC t_DI t_DJNZ
%token		t_EI t_EX t_EXX
%token		t_HALT
%token		t_IM t_IN t_INC t_IND t_INDR t_INI t_INIR
%token		t_JP t_JR
%token		t_LD t_LDD t_LDDR t_LDI t_LDIR
%token		t_NEG t_NOP
%token		t_OR t_OTDR t_OTIR t_OUT t_OUTD t_OUTI
%token		t_POP t_PUSH
%token		t_RES t_RET t_RETI t_RETN t_RL t_RLA t_RLC t_RLCA t_RLD t_RR t_RRA t_RRC t_RRCA t_RRD t_RST
%token		t_SBC t_SCF t_SET t_SLA t_SLL t_SRA t_SRL t_SUB
%token		t_XOR

%token		t_DB t_DW t_DD t_DS t_DEFB t_DEFW t_DEFD t_DEFS t_DEFL t_DEFM
%token		t_ALIGN t_END t_EQU t_EVEN t_ORG t_TITLE t_MACRO t_ENDM t_LOCAL

%type	<i>	address mx my expr simple term factor

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
	/* no command emit */
	f_opcode = false;
}
|	t_SYM
{
	f_opcode = false;
	add_symbol($1, PC);
	free($1);
}
|	t_SYM COLON
{
	f_opcode = false;
	add_symbol($1, PC);
	free($1);
}
|	t_SYM	t_EQU imm16			EOL
{
	f_opcode = false;
	argcnt = 0;
	f_expression = true;
	eexp = arg[0] + 256 * arg[1];
	add_symbol($1,eexp);
	free($1);
}
|	t_SYM	t_DEFL imm16			EOL
{
	f_opcode = false;
	argcnt = 0;
	f_expression = true;
	eexp = arg[0] + 256 * arg[1];
	add_symbol($1, eexp);
	free($1);
}
|	t_LOCAL symlist				EOL
{
	f_opcode = false;
	argcnt = 0;
	printf("local symbols: %s\n", yylval.s);
}
|	t_ADC	t_A COMMA s08			EOL
{
	opcode |= 0x88;
}
|	t_ADC	t_A COMMA s08xy			EOL
{
	opcode |= 0x88;
}
|	t_ADC	t_A COMMA imm8			EOL
{
	opcode = 0xCE;
}
|	t_ADC	t_HL COMMA r16			EOL
{
	prefix = 0xED;
	opcode |= 0x4A;
}
|	t_ADD	t_A COMMA s08			EOL
{
	opcode |= 0x80;
}
|	t_ADD	t_A COMMA s08xy			EOL
{
	opcode |= 0x80;
}
|	t_ADD	t_A COMMA imm8			EOL
{
	opcode = 0xC6;
}
|	t_ADD	t_HL COMMA r16			EOL
{
	opcode |= 0x09;
}
|	t_ADD	t_IX COMMA r16x			EOL
{
	prefix = 0xDD;
	opcode |= 0x09;
}
|	t_ADD	t_IY COMMA r16y			EOL
{
	prefix = 0xFD;
	opcode |= 0x09;
}
|	t_AND	s08				EOL
{
	opcode |= 0xA0;
}
|	t_AND	s08xy				EOL
{
	opcode |= 0xA0;
}
|	t_AND	imm8				EOL
{
	opcode = 0xE6;
}
|	t_BIT	bit COMMA s08			EOL
{
	prefcb = 0xCB;
	opcode |= 0x40;
}
|	t_CALL	imm16				EOL
{
	opcode = 0xCD;
}
|	t_CALL	cond COMMA imm16		EOL
{
	opcode |= 0xC4;
}
|	t_CCF					EOL
{
	opcode = 0x3F;
}
|	t_CP	s08				EOL
{
	opcode |= 0xB8;
}
|	t_CP	s08xy				EOL
{
	opcode |= 0xB8;
}
|	t_CP	imm8				EOL
{
	opcode = 0xFE;
}
|	t_CPD					EOL
{
	prefix = 0xED;
	opcode = 0xA9;
}
|	t_CPDR					EOL
{
	prefix = 0xED;
	opcode = 0xB9;
}
|	t_CPI					EOL
{
	prefix = 0xED;
	opcode = 0xA1;
}
|	t_CPIR					EOL
{
	prefix = 0xED;
	opcode = 0xB1;
}
|	t_CPL					EOL
{
	opcode = 0x2F;
}
|	t_DAA					EOL
{
	opcode = 0x27;
}
|	t_DEC	s08				EOL
{
	opcode = (opcode << 3) | 0x05;
}
|	t_DEC	r08xy				EOL
{
	opcode |= 0x05;
}
|	t_DEC	r16xy				EOL
{
	opcode |= 0x0B;
}
|	t_DI					EOL
{
	opcode = 0xF3;
}
|	t_DJNZ	ofs8				EOL
{
	opcode = 0x10;
}
|	t_EI					EOL
{
	opcode = 0xFB;
}
|	t_EX	t_AF COMMA t_AF QUOTE		EOL
{
	opcode = 0x08;
}
|	t_EX	t_DE COMMA t_HL			EOL
{
	opcode = 0xEB;
}
|	t_EX	LPAREN t_SP RPAREN COMMA t_HL	EOL
{
	opcode = 0xE3;
}
|	t_EX	LPAREN t_SP RPAREN COMMA t_IX	EOL
{
	prefix = 0xDD;
	opcode = 0xE3;
}
|	t_EX	LPAREN t_SP RPAREN COMMA t_IY	EOL
{
	prefix = 0xFD;
	opcode = 0xE3;
}
|	t_EXX					EOL
{
	opcode = 0xD9;
}
|	t_HALT					EOL
{
	opcode = 0x76;
}
|	t_IM	imode				EOL
{
	prefix = 0xED;
	opcode |= 0x56;
}
|	t_IN	LPAREN imm8 RPAREN		EOL
{
	opcode = 0xDB;
}
|	t_IN	r08 COMMA t_PORTC		EOL
{
	prefix = 0xED;
	opcode |= 0x40;
}
|	t_INC	s08				EOL
{
	opcode = (opcode << 3) | 0x04;
}
|	t_INC	r08xy				EOL
{
	opcode |= 0x04;
}
|	t_INC	r16xy				EOL
{
	opcode |= 0x03;
}
|	t_IND					EOL
{
	prefix = 0xED;
	opcode = 0xAA;
}
|	t_INDR					EOL
{
	prefix = 0xED;
	opcode = 0xBA;
}
|	t_INI					EOL
{
	prefix = 0xED;
	opcode = 0xA2;
}
|	t_INIR					EOL
{
	prefix = 0xED;
	opcode = 0xB2;
}
|	t_JP	t_M				EOL
{
	opcode = 0xE9;
}
|	t_JP	LPAREN t_IX RPAREN		EOL
{
	prefix = 0xDD;
	opcode = 0xE9;
}
|	t_JP	LPAREN t_IY RPAREN		EOL
{
	prefix = 0xFD;
	opcode = 0xE9;
}
|	t_JP	imm16				EOL
{
	opcode = 0xC3;
}
|	t_JP	cond COMMA imm16		EOL
{
	opcode |= 0xC2;
}
|	t_JR	ofs8				EOL
{
	opcode = 0x18;
}
|	t_JR	cond1 COMMA ofs8		EOL
{
	opcode |= 0x20;
}
|	t_LD	t_BC COMMA imm16		EOL
{
	opcode = 0x01;
}
|	t_LD	address COMMA t_BC		EOL
{
	prefix = 0xED;
	opcode = 0x43;
}
|	t_LD	t_BC COMMA address		EOL
{
	prefix = 0xED;
	opcode = 0x4B;
}
|	t_LD	t_DE COMMA imm16		EOL
{
	opcode = 0x11;
}
|	t_LD	address COMMA t_DE		EOL
{
	prefix = 0xED;
	opcode = 0x53;
}
|	t_LD	t_DE COMMA address		EOL
{
	prefix = 0xED;
	opcode = 0x5B;
}
|	t_LD	t_HL COMMA imm16		EOL
{
	opcode = 0x21;
}
|	t_LD	address COMMA t_HL		EOL
{
	opcode = 0x22;
}
|	t_LD	t_HL COMMA address		EOL
{
	opcode = 0x2A;
}
|	t_LD	t_SP COMMA imm16		EOL
{
	opcode = 0x31;
}
|	t_LD	address COMMA t_SP		EOL
{
	prefix = 0xED;
	opcode = 0x73;
}
|	t_LD	t_SP COMMA address		EOL
{
	prefix = 0xED;
	opcode = 0x7B;
}
|	t_LD	t_SP COMMA t_HL			EOL
{
	opcode = 0xE3;
}
|	t_LD	t_SP COMMA t_IX			EOL
{
	prefix = 0xDD;
	opcode = 0xE3;
}
|	t_LD	t_SP COMMA t_IY			EOL
{
	prefix = 0xFD;
	opcode = 0xE3;
}
|	t_LD	t_IX COMMA imm16		EOL
{
	prefix = 0xDD;
	opcode = 0x21;
}
|	t_LD	address COMMA t_IX		EOL
{
	prefix = 0xDD;
	opcode = 0x22;
}
|	t_LD	t_IX COMMA address		EOL
{
	prefix = 0xDD;
	opcode = 0x2A;
}
|	t_LD	t_IY COMMA imm16		EOL
{
	prefix = 0xFD;
	opcode = 0x21;
}
|	t_LD	address COMMA t_IY		EOL
{
	prefix = 0xFD;
	opcode = 0x22;
}
|	t_LD	t_IY COMMA address		EOL
{
	prefix = 0xFD;
	opcode = 0x2A;
}
|	t_LD	t_B COMMA s08			EOL
{
	opcode |= 0x40;
}
|	t_LD	t_C COMMA s08			EOL
{
	opcode |= 0x48;
}
|	t_LD	t_D COMMA s08			EOL
{
	opcode |= 0x50;
}
|	t_LD	t_E COMMA s08			EOL
{
	opcode |= 0x58;
}
|	t_LD	t_H COMMA s08			EOL
{
	opcode |= 0x60;
}
|	t_LD	t_L COMMA s08			EOL
{
	opcode |= 0x68;
}
|	t_LD	t_M COMMA s08			EOL
{
	opcode |= 0x70;
}
|	t_LD	t_A COMMA s08			EOL
{
	opcode |= 0x78;
}
|	t_LD	mx COMMA s08			EOL
{
	prefix = 0xDD;
	opcode |= 0x70;
	offset = $2;
	f_offset = true;
}
|	t_LD	my COMMA s08			EOL
{
	prefix = 0xFD;
	opcode |= 0x70;
	offset = $2;
	f_offset = true;
}
|	t_LD	t_B COMMA imm8			EOL
{
	opcode = 0x06;
}
|	t_LD	t_C COMMA imm8			EOL
{
	opcode = 0x0E;
}
|	t_LD	t_D COMMA imm8			EOL
{
	opcode = 0x16;
}
|	t_LD	t_E COMMA imm8			EOL
{
	opcode = 0x1E;
}
|	t_LD	t_H COMMA imm8			EOL
{
	opcode = 0x26;
}
|	t_LD	t_L COMMA imm8			EOL
{
	opcode = 0x2E;
}
|	t_LD	t_M COMMA imm8			EOL
{
	opcode = 0x36;
}
|	t_LD	t_A COMMA imm8			EOL
{
	opcode = 0x3E;
}
|	t_LD	mx COMMA imm8			EOL
{
	prefix = 0xDD;
	opcode = 0x36;
	offset = $2;
	f_offset = true;
}
|	t_LD	my COMMA imm8			EOL
{
	prefix = 0xFD;
	opcode = 0x36;
	offset = $2;
	f_offset = true;
}
|	t_LD	t_I COMMA t_A			EOL
{
	prefix = 0xED;
	opcode = 0x47;
}
|	t_LD	t_R COMMA t_A			EOL
{
	prefix = 0xED;
	opcode = 0x4F;
}
|	t_LD	t_A COMMA t_I			EOL
{
	prefix = 0xED;
	opcode = 0x57;
}
|	t_LD	t_A COMMA t_R			EOL
{
	prefix = 0xED;
	opcode = 0x5F;
}
|	t_LD	LPAREN t_BC RPAREN COMMA t_A	EOL
{
	opcode = 0x02;
}
|	t_LD	t_A COMMA LPAREN t_BC RPAREN	EOL
{
	opcode = 0x0A;
}
|	t_LD	LPAREN t_DE RPAREN COMMA t_A	EOL
{
	opcode = 0x12;
}
|	t_LD	t_A COMMA LPAREN t_DE RPAREN	EOL
{
	opcode = 0x1A;
}
|	t_LD	address COMMA t_A		EOL
{
	opcode = 0x32;
}
|	t_LD	t_A COMMA address		EOL
{
	opcode = 0x3A;
}
|	t_LD	r08xy COMMA t_B			EOL
{
	opcode |= 0x40;
}
|	t_LD	r08xy COMMA t_C			EOL
{
	opcode |= 0x41;
}
|	t_LD	r08xy COMMA t_D			EOL
{
	opcode |= 0x42;
}
|	t_LD	r08xy COMMA t_E			EOL
{
	opcode |= 0x43;
}
|	t_LD	r08xy COMMA t_A			EOL
{
	opcode |= 0x47;
}
|	t_LD	t_B COMMA s08xy			EOL
{
	opcode |= 0x40;
}
|	t_LD	t_C COMMA s08xy			EOL
{
	opcode |= 0x48;
}
|	t_LD	t_D COMMA s08xy			EOL
{
	opcode |= 0x50;
}
|	t_LD	t_E COMMA s08xy			EOL
{
	opcode |= 0x58;
}
|	t_LD	t_A COMMA s08xy			EOL
{
	opcode |= 0x78;
}
|	t_LD	r08xy COMMA s08xy		EOL
{
	opcode |= 0x40;
}
|	t_LDD					EOL
{
	prefix = 0xED;
	opcode = 0xA8;
}
|	t_LDDR					EOL
{
	prefix = 0xED;
	opcode = 0xB8;
}
|	t_LDI					EOL
{
	prefix = 0xED;
	opcode = 0xA0;
}
|	t_LDIR					EOL
{
	prefix = 0xED;
	opcode = 0xB0;
}
|	t_NEG					EOL
{
	prefix = 0xED;
	opcode = 0x44;
}
|	t_NOP					EOL
{
	opcode = 0x00;
}
|	t_OR	s08				EOL
{
	opcode |= 0xB0;
}
|	t_OR	s08xy				EOL
{
	opcode |= 0xB0;
}
|	t_OR	imm8				EOL
{
	opcode = 0xF6;
}
|	t_OTDR					EOL
{
	prefix = 0xED;
	opcode = 0xBB;
}
|	t_OTIR					EOL
{
	prefix = 0xED;
	opcode = 0xB3;
}
|	t_OUT	LPAREN imm8 RPAREN		EOL
{
	opcode = 0xD3;
}
|	t_OUT	t_PORTC COMMA r08		EOL
{
	prefix = 0xED;
	opcode = 0x41;
}
|	t_OUTD					EOL
{
	prefix = 0xED;
	opcode = 0xAB;
}
|	t_OUTI					EOL
{
	prefix = 0xED;
	opcode = 0xA3;
}
|	t_POP	r16pp				EOL
{
	opcode |= 0xC1;
}
|	t_PUSH	r16pp				EOL
{
	opcode |= 0xC5;
}
|	t_RES	bit COMMA s08			EOL
{
	prefcb = 0xCB;
	opcode |= 0x80;
}
|	t_RET					EOL
{
	opcode = 0xC9;
}
|	t_RET	cond				EOL
{
	opcode |= 0xC0;
}
|	t_RETI					EOL
{
	prefix = 0xED;
	opcode = 0x45;
}
|	t_RETN					EOL
{
	prefix = 0xED;
	opcode = 0x4D;
}
|	t_RL	s08				EOL
{
	prefcb = 0xCB;
	opcode |= 0x10;
}
|	t_RLA					EOL
{
	opcode = 0x17;
}
|	t_RLC	s08				EOL
{
	prefcb = 0xCB;
	opcode |= 0x00;
}
|	t_RLCA					EOL
{
	opcode = 0x07;
}
|	t_RLD					EOL
{
	prefix = 0xED;
	opcode = 0x6F;
}
|	t_RR	s08				EOL
{
	prefcb = 0xCB;
	opcode |= 0x18;
}
|	t_RRA					EOL
{
	opcode = 0x1F;
}
|	t_RRC	s08				EOL
{
	prefcb = 0xCB;
	opcode |= 0x08;
}
|	t_RRCA					EOL
{
	opcode = 0x0F;
}
|	t_RRD					EOL
{
	prefix = 0xED;
	opcode = 0x67;
}
|	t_RST	rst				EOL
{
	opcode |= 0xC7;
}
|	t_SBC	t_A COMMA s08			EOL
{
	opcode |= 0x98;
}
|	t_SBC	t_A COMMA s08xy			EOL
{
	opcode |= 0x98;
}
|	t_SBC	t_A COMMA imm8			EOL
{
	opcode = 0xDE;
}
|	t_SBC	t_HL COMMA r16			EOL
{
	prefix = 0xED;
	opcode |= 0x42;
}
|	t_SCF					EOL
{
	opcode = 0x37;
}
|	t_SET	bit COMMA s08			EOL
{
	prefcb = 0xCB;
	opcode |= 0xC0;
}
|	t_SLA	s08				EOL
{
	prefcb = 0xCB;
	opcode |= 0x20;
}
|	t_SLL	s08				EOL
{
	prefcb = 0xCB;
	opcode |= 0x30;
}
|	t_SRA	s08				EOL
{
	prefcb = 0xCB;
	opcode |= 0x28;
}
|	t_SRL	s08				EOL
{
	prefcb = 0xCB;
	opcode |= 0x38;
}
|	t_SUB	s08				EOL
{
	opcode |= 0x90;
}
|	t_SUB	s08xy				EOL
{
	opcode |= 0x90;
}
|	t_SUB	imm8				EOL
{
	opcode = 0xD6;
}
|	t_XOR	s08				EOL
{
	opcode |= 0xA8;
}
|	t_XOR	s08xy				EOL
{
	opcode |= 0xA8;
}
|	t_XOR	imm8				EOL
{
	opcode = 0xEE;
}
|	t_DB	imm8l				EOL
{
	f_opcode = false;
}
|	t_DW	imm16l				EOL
{
	f_opcode = false;
}
|	t_DD	imm32l				EOL
{
	f_opcode = false;
}
|	t_DS	imm16				EOL
{
	f_opcode = false;
	argcnt = arg[0] + 256 * arg[1];
	if (argcnt > sizeof(arg)) {
		warning("size clipped to assembler limits (%d : %d)\n", argcnt, sizeof(arg));
		argcnt = sizeof(arg);
	}
	memset(arg, 0, argcnt);
}
|	t_DEFB	imm8l				EOL
{
	f_opcode = false;
}
|	t_DEFW	imm16l				EOL
{
	f_opcode = false;
}
|	t_DEFD	imm32l				EOL
{
	f_opcode = false;
}
|	t_DEFS	imm16				EOL
{
	f_opcode = false;
	argcnt = arg[0] + 256 * arg[1];
	if (argcnt > sizeof(arg)) {
		warning("size clipped to assembler limits (%d : %d)\n", argcnt, sizeof(arg));
		argcnt = sizeof(arg);
	}
	memset(arg, 0, argcnt);
}
|	t_DEFS	imm16 COMMA imm8		EOL
{
	f_opcode = false;
	argcnt = arg[0] + 256 * arg[1];
	if (argcnt > sizeof(arg)) {
		warning("size clipped to assembler limits (%d : %d)\n", argcnt, sizeof(arg));
		argcnt = sizeof(arg);
	}
	memset(arg, arg[2], argcnt);
}
|	t_DEFM	strlist				EOL
{
	f_opcode = false;
}
|	t_ORG	imm16				EOL
{
	f_opcode = false;
	argcnt = 0;
	f_expression = true;
	eexp = arg[0] + 256 * arg[1];
	PC = eexp;
}
|	t_ALIGN	imm8				EOL
{
	f_opcode = false;
	argcnt = 0;
	f_expression = true;
	eexp = PC;
	tmp = arg[0] - 1;
	while (PC & tmp)
		arg[argcnt++] = 0;
}
|	t_EVEN					EOL
{
	f_opcode = false;
	argcnt = 0;
	f_expression = true;
	eexp = PC;
	if (PC & 1)
		arg[argcnt++] = 0;
}
|	t_END	imm16				EOL
{
	f_opcode = false;
	argcnt = 0;
	f_expression = true;
	eexp = arg[0] + 256 * arg[1];
	end = eexp;
}
|	t_TITLE	strlist				EOL
{
	f_opcode = false;
	if (argcnt >= sizeof(title)) {
		warning("title clipped to limits (%d : %d)\n", argcnt, sizeof(title));
		argcnt = sizeof(title);
	}
	snprintf(title, sizeof(title), "%s", arg);
	title[argcnt] = 0;
	argcnt = 0;
}
|	t_MACRO symlist				EOL
	t_ENDM					EOL
{
	printf("macbuff: %s\n", macbuff);
}
;

symlist	: sym
	| sym COMMA symlist
	;

sym	: t_SYM
{
	add_typed($1, TYPE_MACRO);
	free($1);
}
s08	:	t_B {
	opcode |= 0x00;
}
|	t_C {
	opcode |= 0x01;
}
|	t_D {
	opcode |= 0x02;
}
|	t_E {
	opcode |= 0x03;
}
|	t_H {
	opcode |= 0x04;
}
|	t_L {
	opcode |= 0x05;
}
|	t_M {
	opcode |= 0x06;
}
|	t_A {
	opcode |= 0x07;
}
|	mx {
	prefix = 0xDD;
	opcode |= 0x06;
	offset = $1;
	f_offset = true;
}
|	my {
	prefix = 0xFD;
	opcode |= 0x06;
	offset = $1;
	f_offset = true;
}
;

r08	:	t_B {
	opcode |= 0x00;
}
|	t_C {
	opcode |= 0x08;
}
|	t_D {
	opcode |= 0x10;
}
|	t_E {
	opcode |= 0x18;
}
|	t_H {
	opcode |= 0x20;
}
|	t_L {
	opcode |= 0x28;
}
|	t_F {
	opcode |= 0x30;
}
|	t_A {
	opcode |= 0x38;
}
;

s08xy	:	t_HX {
	prefix = 0xDD;
	opcode |= 0x05;
}
|	t_LX {
	prefix = 0xDD;
	opcode |= 0x06;
}
|	t_HY {
	prefix = 0xFD;
	opcode |= 0x05;
}
|	t_LY {
	prefix = 0xFD;
	opcode |= 0x06;
}
;

r08xy	:	t_HX {
	prefix = 0xDD;
	opcode |= 0x20;
}
|	t_LX {
	prefix = 0xDD;
	opcode |= 0x28;
}
|	t_HY {
	prefix = 0xFD;
	opcode |= 0x20;
}
|	t_LY {
	prefix = 0xFD;
	opcode |= 0x28;
}
;

r16	:	t_BC {
	opcode |= 0x00;
}
|	t_DE {
	opcode |= 0x10;
}
|	t_HL {
	opcode |= 0x20;
}
|	t_SP {
	opcode |= 0x30;
}
;

r16x	:	t_BC {
	opcode |= 0x00;
}
|	t_DE {
	opcode |= 0x10;
}
|	t_IX {
	opcode |= 0x20;
}
|	t_SP {
	opcode |= 0x30;
}
;

r16y	:	t_BC {
	opcode |= 0x00;
}
|	t_DE {
	opcode |= 0x10;
}
|	t_IY {
	opcode |= 0x20;
}
|	t_SP {
	opcode |= 0x30;
}
;

r16xy	:	t_BC {
	opcode |= 0x00;
}
|	t_DE {
	opcode |= 0x10;
}
|	t_HL {
	opcode |= 0x20;
}
|	t_SP {
	opcode |= 0x30;
}
|	t_IX {
	prefix = 0xDD;
	opcode |= 0x20;
}
|	t_IY {
	prefix = 0xFD;
	opcode |= 0x20;
}
;

r16pp	:	t_BC {
	opcode |= 0x00;
}
|	t_DE {
	opcode |= 0x10;
}
|	t_HL {
	opcode |= 0x20;
}
|	t_AF {
	opcode |= 0x30;
}
|	t_IX {
	prefix = 0xDD;
	opcode |= 0x20;
}
|	t_IY {
	prefix = 0xFD;
	opcode |= 0x20;
}
;

cond	:	t_cNZ	{
	opcode |= 0x00;
}
|	t_cZ	{
	opcode |= 0x08;
}
|	t_cNC	{
	opcode |= 0x10;
}
|	t_cC	{
	opcode |= 0x18;
}
|	t_cPO	{
	opcode |= 0x20;
}
|	t_cPE	{
	opcode |= 0x28;
}
|	t_cP	{
	opcode |= 0x30;
}
|	t_cM	{
	opcode |= 0x38;
}
;

cond1	:	t_cNZ	{
	opcode |= 0x00;
}
|	t_cZ	{
	opcode |= 0x08;
}
|	t_cNC	{
	opcode |= 0x10;
}
|	t_cC	{
	opcode |= 0x18;
}
;

address	:	LPAREN expr RPAREN
{
	arg[argcnt++] = $2 % 256;
	arg[argcnt++] = $2 / 256;
}
;

mx	:	LPAREN t_IX RPAREN
{
	$$ = 0;
}
|	LPAREN t_IX PLUS expr RPAREN
{
	$$ = $4;
}
|	LPAREN t_IX MINUS expr RPAREN
{
	$$ = -$4;
}
;

my	:	LPAREN t_IY RPAREN
{
	$$ = 0;
}
|	LPAREN t_IY PLUS expr RPAREN
{
	$$ = $4;
}
|	LPAREN t_IY MINUS expr RPAREN
{
	$$ = -$4;
}
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
	symbol_t* s = get_symbol($1);
	$$ = s ? s->u.value : 0;
	free($1);
}
|	LPAREN expr RPAREN
{
	$$ = $2;
}
;

imm8	:	expr
{
	arg_byte($1);
}
;

imm8l	:	imm8 COMMA imm8l
|	imm8
;

imm16	:	expr
{
	arg_word($1);
}
;

imm16l	:	imm16 COMMA imm16l
|	imm16
;

imm32	:	expr
{
	arg_dword($1);
}
;

imm32l	:	imm32 COMMA imm32
|	imm32
;

str	:	t_STR
{
	int len = snprintf(arg + argcnt, sizeof(arg) - argcnt, "%s", $1);
	if (len < strlen($1)) {
		warning("string overflow ('%s')\n", $1);
	}
	argcnt += len;
	free($1);
}
|	imm8
;

strlist	:	str COMMA strlist
|	str
;

ofs8	:	expr
{
	offset  = $1 - PC - 2;
	f_offset = true;
	if (pass_no > 1 && (offset < -128 || offset > +127)) {
		warning("JR out of range (%d)\n", $1 - PC - 2);
	}
}
;

bit	:	expr
{
	if ($1 < 0 || $1 > 7) {
		error("invalid bit number %d (range is 0 ... 7)\n", $1);
	}
	opcode |= ($1 & 7) << 3;
}
;

rst	:	expr
{
	if ($1 < 0 || $1 > 0x38 || $1 & 0x07) {
		error("invalid RST vector %04xH\n", $1);
	}
	opcode |= ($1 & 0x38);
}
;

imode	:	expr
{
	if ($1 < 0 || $1 > 2) {
		error("invalid interrupt mode %d\n", $1);
	}
	opcode |= ($1 % 3) << 3;
}
%%

int list(char * fmt, ...)
{
	va_list arg;
	int rc = 0;

	if (!f_list)
		return rc;
	if (pass_no < 2)
		return rc;
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
	if (0 == tape_cnt) {
		return;
	}

	if (f_tape_cg) {
		fputc(0x3C, outfile);
		fputc(tape_cnt, outfile);
		fputc(tape_adr & 255, outfile);
		fputc(tape_adr / 256, outfile);
		fwrite(tape_buf, 1, tape_cnt, outfile);
		fputc(tape_crc, outfile);
		tape_crc = 0;
	}

	if (f_tape_vz) {
		if (f_first) {
			fputc(tape_adr & 255, outfile);
			fputc(tape_adr / 256, outfile);
			f_first = 0;
		}
		fwrite(tape_buf, 1, tape_cnt, outfile);
	}

	tape_cnt = 0;
}

int outch(byte c)
{
	int rc = 0;

	if (pass_no == 1) {
		PC++;
		return rc;
	}

	rc = list("%02X ", c);
	if (f_tape) {
		if (PC != tape_pc || tape_cnt == 128) {
			tape_flush();
			tape_pc  = PC;
			tape_adr = PC;
			tape_crc = (tape_adr % 256) + (tape_adr / 256);
		}
		tape_buf[tape_cnt++] = c;
		tape_crc += c;
		tape_pc  += 1;
	} else {
		fputc(c, outfile);
	}
	PC++;
	return rc;
}

void emit(void)
{
	int x = 0;
	int i;

	if (f_opcode || argcnt > 0) {
		x += list("%04X: ", PC);
	}

	if (prefix) {
		x += outch(prefix);
	}
	if (prefcb) {
		x += outch(prefcb);
	}

	if (prefix && prefcb && f_offset) {
		x += outch(offset);
		x += outch(opcode);
	} else {
		if (f_opcode) {
			x += outch(opcode);
		}
		if (f_offset) {
			x += outch(offset);
		}
	}

	for (i = 0; i < argcnt && i < 8; i++) {
		x += outch(arg[i]);
	}

	if (strchr(lstbuff, '\n')) {

		if (!(f_opcode || argcnt > 0) && f_expression) {
			x += list("=%04X ", eexp);
		}

		if (x >= 0 && x < 32) {
			list("%*s", 32 - x, " ");
		}

		list("%s", lstbuff);
	}

	if (argcnt > 8) {
		for (i = 8; i < argcnt; i++)
		{
			if ((i & 7) == 0)
				x = list("%04X: ", PC);
			x += outch(arg[i]);
			if ((i & 7) == 7)
				x += list("\n");
		}
		if (i & 7)
			x += list("\n");
	}

	prefix = 0x00;
	prefcb = 0x00;
	opcode = 0x00;
	offset = 0x00;
	f_expression = false;
	f_opcode = true;
	f_offset = false;
	argcnt = 0;
}

void add_ref(symbol_t* sym)
{
	sym->refs += 1;
	sym->line_no = (int *) realloc(sym->line_no, (sym->refs + 1) * sizeof(int));
	if (!sym->line_no) {
		error("out of memory!\n");
		exit(1);
	}
	sym->line_no[sym->refs] = line_no;
}

void add_symbol(const char * name, int int64)
{
	symbol_t *s, *s0, *s1;
	for (s = sym; (s); s = s->next) {
		if (0 == strcasecmp(name, s->name)) {
			if (s->pass_no == pass_no)
				warning("double defined symbol %s\n", name);
			s->line_no[0] = line_no;
			s->pass_no = pass_no;
			if (s->u.value != int64) {
				warning("%s has different value on pass 2\n", name);
			}
			s->u.value = int64;
			return;
		}
	}

	for (s0 = NULL, s1 = sym; (s1); s0 = s1, s1 = s1->next)
		if (strcasecmp(name, s1->name) <= 0)
			break;

	s = (symbol_t *) calloc(1, sizeof(*s));
	if (!s) {
		error("out of memory!\n");
		exit(1);
	}

	s->next = s1;
	s->type = TYPE_CONST;
	s->pass_no = pass_no;
	s->refs = 0;
	s->line_no = malloc(sizeof(int));
	*s->line_no = line_no;
	s->u.value = int64;
	s->name = strdup(name);
	if (!s->name) {
		error("out of memory!\n");
		exit(1);
	}

	if (s0) {
		s0->next = s;
	} else {
		sym = s;
	}

	symb_no++;
}

symbol_t* get_symbol(char * name)
{
	symbol_t *s;
	for (s = sym; (s); s = s->next) {
		if (0 == strcasecmp(name, s->name)) {
			if (pass_no > 1) {
				s->refs += 1;
				s->line_no = (int *) realloc(s->line_no, (s->refs + 1) * sizeof(int));
				s->line_no[s->refs] = line_no;
			}
			return s;
		}
	}

	if (pass_no > 1) {
		warning("undefined symbol: %s\n", name);
	}

	return NULL;
}

void add_typed(const char * name, symtype_e type)
{
	symbol_t *s, *s0, *s1;

	for (s0 = NULL, s1 = sym; (s1); s0 = s1, s1 = s1->next)
		if (strcasecmp(name, s1->name) <= 0)
			break;

	if (!s1 || 0 != strcasecmp(name, s1->name)) {
		s = (symbol_t *) calloc(1, sizeof(*s));
		if (!s) {
			error("out of memory!\n");
			exit(1);
		}

		s->next = s1;
		s->type = type;
		s->pass_no = pass_no;
		s->refs = 0;
		s->line_no = malloc(sizeof(int));
		*s->line_no = line_no;
		s->name = strdup(name);
		if (!s->name) {
			error("out of memory!\n");
			exit(1);
		}

		if (s0) {
			s0->next = s;
		} else {
			sym = s;
		}
	}

	symb_no++;
}

symbol_t *get_typed(char *name, symtype_e type)
{
	symbol_t *s;
	for (s = sym; (s); s = s->next) {
		if (s->type != type)
			continue;
		if (!strcasecmp(name, s->name))
			return s;
	}
	return NULL;
}

int arg_byte(int64_t val)
{
	if (argcnt + 1 >= sizeof(arg)) {
		warning("argument buffer overrun\n");
		return -1;
	}
	if (val < -255 || val > 255) {
		warning("value exceeds BYTE (%lld)\n", val);
	}
	arg[argcnt++] = (byte)(val);
	return 1;
}

int arg_word(int64_t val)
{
	if (argcnt + 2 >= sizeof(arg)) {
		warning("argument buffer overrun\n");
		return -1;
	}
	if (val < -65535 || val > 65535) {
		warning("value exceeds WORD (%lld)\n", val);
	}
	arg[argcnt++] = (byte)(val >> 0);
	arg[argcnt++] = (byte)(val >> 8);
	return 2;
}

int arg_dword(int64_t val)
{
	if (argcnt + 4 >= sizeof(arg)) {
		warning("argument buffer overrun\n");
		return -1;
	}
	if (val < -2147483648ll || val > 21474836647ll) {
		warning("value exceeds DWORD (%lld)\n", val);
	}
	arg[argcnt++] = (byte)(val >> 0);
	arg[argcnt++] = (byte)(val >> 8);
	arg[argcnt++] = (byte)(val >> 16);
	arg[argcnt++] = (byte)(val >> 24);
	return 4;
}

void warning(const char* fmt, ...)
{
	va_list ap;
	fprintf(stderr, "Line %d %s: ", line_no, "warning");
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
}

void error(const char* fmt, ...)
{
	va_list ap;
	fprintf(stderr, "Line %d %s: ", line_no, "error");
	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
}

void prt_sym(FILE * filp)
{
	symbol_t * s;
	int i;
	for (s = sym; (s); s = s->next) {
		fprintf(filp, "%-32.32s%04X line %d, %d references\n",
			s->name, s->u.value, s->line_no[0], s->refs);
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
		fprintf(stderr, "usage: az80 [options] input[.z80] [output[.bin]] [listing[.lst]]\n");
		fprintf(stderr, "options can be one or more of:\n");
		fprintf(stderr, "-d\tgenerate parser debug output to stderr\n");
		fprintf(stderr, "-l\tgenerate listing (to file input.lst)\n");
		fprintf(stderr, "-s\toutput symbol table\n");
		fprintf(stderr, "-x\toutput cross reference with symbol table\n");
		fprintf(stderr, "-c[=name]\tgenerate tape in Colour Genie format with load address(es)\n");
		fprintf(stderr, "-v[=name]\tgenerate tape in VZ200/VZ300 format with load address\n");
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
			case 'c': case 'C':
				f_tape = true;
				f_tape_cg = true;
				if (av[i][2] == '=') {
					tape_name_conv(av[i] + 3);
				}
				break;
			case 'v': case 'V':
				f_tape = true;
				f_tape_vz = true;
				if (av[i][2] == '=') {
					tape_name_conv(av[i] + 3);
				}
				break;
			default:
				fprintf(stderr, "illegal option %s\n", av[i]);
				exit(1);
			}
		} else if (!strlen(inpname)) {
			snprintf(inpname, sizeof(inpname), "%s", av[i]);
		} else if (!strlen(outname)) {
			snprintf(outname, sizeof(outname), "%s", av[i]);
		} else if (!strlen(lstname)) {
			snprintf(lstname, sizeof(lstname), "%s", av[i]);
		} else {
			fprintf(stderr, "additional argument %s ignored\n", av[i]);
		}
	}

	if (0 == strlen(inpname)) {
		fprintf(stderr, "input filename missing!\n");
		exit(1);
	}

	if (0 == strlen(outname)) {
		snprintf(outname, sizeof(outname), inpname);
		p = strrchr(outname, '.');
		if (!p) {
			p = outname + strlen(outname);
		}
		strcpy(p, f_tape_cg ? CG_TAPE_EXT : f_tape_vz ? VZ_TAPE_EXT : ".bin");
	}

	if (f_tape) {
		if (0 == strlen(tape_name)) {
			tape_name_conv(inpname);
		}
	}

	if (f_list) {
		if (0 == strlen(lstname)) {
			snprintf(lstname, sizeof(lstname), "%s", inpname);
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
		strcat(inpname, ".z80");
	}

	inpfile = fopen(inpname, "r");
	if (!inpfile) {
		perror("fopen()");
		fprintf(stderr, "can't open %s\n", inpname);
		exit(1);
	}

	outfile = fopen(outname, "wb");
	if (!outfile) {
		perror("fopen()");
		fprintf(stderr, "can't create %s\n", outname);
		exit(1);
	}

	if (f_list) {
		lstbuff = malloc(MAX_LISTBUFF);
		lstfile = fopen(lstname, "w");
		if (!lstfile) {
			perror("fopen()");
			fprintf(stderr, "can't create %s\n", outname);
			exit(1);
		}
		plst = lstbuff;
		*plst = '\0';
	}

	if (f_tape) {
		if (f_tape_cg) {
			/* tape sync */
			fputc(0x66, outfile);
			/* tape header */
			fputc(0x55, outfile);
			p = tape_name;
			for (i = 0; i < 6; i++)
				fputc((*p) ? toupper(*p++) : ' ', outfile);
		}

		if (f_tape_vz) {
			char vz_name[16+1], *src = tape_name, *dst = vz_name;
			int i;

			memset(vz_name, 0, sizeof(vz_name));
			while (*src && *src != '.')
				*dst++ = toupper(*src);
			fputc(0x20, outfile);   /* magic */
			fputc(0x20, outfile);
			fputc(0x00, outfile);
			fputc(0x00, outfile);

			for (i = 0; i < sizeof(vz_name); i++) {
				fputc(vz_name[i], outfile);
			}

			fputc(0xf1, outfile);   /* magic value */

			f_first = 1;
		}
	}

	lstbuff = calloc(MAX_LISTBUFF, 1);

	printf("Assembling %s\n", inpname);
	printf("Pass #1\n");
	yyrestart(inpfile);
	yyparse();
	list("\n");

	if (f_syms) {
		prt_sym(f_list ? lstfile : stdout);
	}

	if (f_tape) {
		tape_flush();
		if (f_tape_cg) {
			/* Write the entry point block */
			fputc(0x78, outfile);
			fputc(end & 255, outfile);
			fputc(end / 256, outfile);
		}
	}

	fclose(inpfile);
	fclose(outfile);

	if (f_list) {
		fclose(lstfile);
	}

	printf("Statistics: %d lines, %d symbols\n", line_no, symb_no);

	return 0;
}
