CC ?= gcc
CFLAGS ?= -O2 -Wall
all: razerctl
razerctl: razerctl.c
	$(CC) $(CFLAGS) -o $@ $<
clean:
	rm -f razerctl burn *.o
.PHONY: all clean
