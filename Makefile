CC	=	gcc
LEX	=	flex
YACC	=	bison --yacc
DEBUG	=	1

ifeq ($(DEBUG),1)
CFLAGS	= -O1 -g
LDFLAGS	=
else
CFLAGS	= -O2
LDFLAGS	= -s
endif

all:	az80

az80:	       az80.tab.o az80yy.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^

az80yy.o:	az80yy.c az80.tab.h
	$(CC) $(CFLAGS) -o $@ -c $<

az80yy.c:	az80.l
	$(LEX) -o$@ -i $<

az80.tab.o:	az80.tab.c az80.tab.h
	$(CC) $(CFLAGS) -o $@ -c $<

az80.tab.c:	az80.y
	$(YACC)	-d -t -v $<
	mv y.tab.c $@
	mv y.tab.h az80.tab.h
	mv y.output az80.output

clean:
	rm -f *.o *.lst
	rm -f az80 az80.out az80.output az80.tab.c az80.tab.h az80yy.c

export: 	clean
	zip  -r ../az80 .
