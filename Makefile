CC=	gcc
LEX=	flex
YACC=	bison --yacc

all:	a8085 az80

az80:	       az80.tab.o az80yy.o
	$(CC) -o $@ $^

az80yy.o:	az80yy.c az80.tab.h
	$(CC) -O3 -o $@ -c $<

az80yy.c:	az80.l
	$(LEX)	-o$@ -i $<

az80.tab.o:	az80.tab.c az80.tab.h
	$(CC) -O3 -o $@ -c $<

az80.tab.c:	az80.y
	$(YACC)	-d -t -v $<
	mv y.tab.c $@
	mv y.tab.h az80.tab.h
	mv y.output az80.output

a8085:	       a8085.tab.o a8085yy.o
	$(CC) -o $@ $^

a8085yy.o:	a8085yy.c a8085.tab.h
	$(CC) -O3 -o $@ -c $<

a8085yy.c:	a8085.l
	$(LEX)	-o$@ -i $<

a8085.tab.o:	a8085.tab.c a8085.tab.h
	$(CC) -O3 -o $@ -c $<

a8085.tab.c:	a8085.y
	$(YACC)	-d -t -v $<
	mv y.tab.c $@
	mv y.tab.h a8085.tab.h
	mv y.output a8085.output

clean:
	rm -f *.o *.lst
	rm -f az80 az80.out az80.output az80.tab.c az80.tab.h az80yy.c
	rm -f a8085 a8085.out a8085.output a8085.tab.c a8085.tab.h a8085yy.c

export: 	clean
	zip  -r ../az80 .
