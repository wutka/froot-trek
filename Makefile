
all: startrek.rom

startrek.rom: startrek.bin
	bin2rom startrek.bin startrek.rom 400

startrek.bin: startrek.o lib.o
	ld65 -C startrek.cfg -o startrek.bin startrek.o lib.o

startrek.o: startrek.s lib.inc
	ca65 startrek.s

lib.o: lib.inc lib.s
	ca65 lib.s

clean:
	rm *.o *.bin *.rom
