
all: froottrek.rom

froottrek.rom: froottrek.bin
	bin2rom froottrek.bin froottrek.rom a000

froottrek.bin: froottrek.o lib.o
	ld65 -C froottrek.cfg --dbgfile froottrek.dbg -o froottrek.bin froottrek.o lib.o

froottrek.o: froottrek.s lib.inc
	ca65 -g froottrek.s

lib.o: lib.inc lib.s
	ca65 -g lib.s

clean:
	rm *.o *.bin *.rom *.map
