CC=gcc
CFLAGS=-O2 -Wall -ggdb -Wno-unused-result
LIBS=-lm
PRJ=limlang

$(PRJ): $(PRJ).tab.o $(PRJ).lex.o
	$(CC) -o $@ $^ $(LIBS)

$(PRJ).lex.c: $(PRJ).l
	flex -o $@ $^

$(PRJ).tab.c $(PRJ).tab.h: $(PRJ).y
	bison --graph -t --report all -Wcounterexamples --defines $(PRJ).y

$(PRJ).lex.o: $(PRJ).lex.c $(PRJ).tab.h

$(PRJ).tab.o: $(PRJ).tab.c $(PRJ).tab.h

clean:
	rm -f *.o $(PRJ) *.h *.output *.gv *.svg *.lex.c *.tab.c
