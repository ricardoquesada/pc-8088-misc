all:
	#nasm -fbin src/main.asm -o binexe.exe -i/Users/riq/src/nasm-2.13.01/misc/
	nasm -f elf src/main.asm -o obj/main.o
	smlrl -small obj/main.o -o mama.exe

clean:
	rm *.exe
	rm obj/*
