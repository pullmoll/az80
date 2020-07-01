#### AZ80 - Another Z80 assembler

This software is free for any use. The author cannot be held
responsible for any problems it might cause, in no case. If
you don't understand or accept this, delete az80 immediately.

# Purpose:
  AZ80 was written as a lex/yacc exercise. Lex and Yacc are
  compiler tools: lexical analyzer and 'yet another compiler compiler'.
  AZ80 was written to assemble some tools for the EACA Colour Genie
  and the V-Tech VZ200/VZ300 on the PC and transfer them to an emulator.

# Operation:
  az80 [options] source[.z80] [output[.bin] [listing[.lst]]

  <source> is the filename of a Z80 assembly language program.
  The default extension is .z80 and is appended if you omit an
  extension in the filename.

  The output is by default <source>.bin, or
  <source>.cas, if you specify the emit to tape format option.

  The listing is <source>.lst, unless you specify a different name.

  The options can be one or more of:
  -d  debug the the lexical analyzer and parser output (don't do it!)
  -l  generate listing (off by default, unless a listing file is specified)
  -s  output a symbol table with the listing
  -x  output symbol cross references with the symbol table
  -c  create cassette tape format (Colour Genie .cas image).
      The first ORG defines the load address, the END expression
      defines the entry point.
  -v  create cassette tape format (V-Tech VZ200/VZ300 .vz image).

# Default keywords:
  DEFB	define byte(s)
        exmaple:  DEFB 1,2,3,4
                  DEFB 12h,34h,56h

  DEFL	define label
        example:  name DEFL 64000

  DEFM	define message
        exmaple:  DEFM "ABCD"

  DEFW	define word(s)
        exmaple:  DEFW 7000h, 01c9h

  EQU	define a symbol
        exmaple: offs EQU 10

  ORG	set origin of program code
        example:  ORG 8000h

  END   define end of program and entry point
        example:  END start

Regards,

Jürgen Buchmüller <pullmoll@t-online.de>


