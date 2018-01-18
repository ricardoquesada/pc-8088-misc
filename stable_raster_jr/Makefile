.PHONY: default all clean

ASM = nasm
ASMFLAGS = -fobj -Wall
LD = alink
LDFLAGS = -oEXE -m

default: scrollbar
all: default

clean:
	echo "Cleaning..."
	-rm -f *.o *.map *.exe

scrollbar:
	$(ASM) $(ASMFLAGS) $@.asm -o $@.o
	$(LD) $@.o $(LDFLAGS) -o ../bin/$@.exe
	dosbox-x -conf ../conf/dosbox-x_pcjr.conf -c "mount c ../bin/ && dir" -c "c:" -c "scroll~1.exe"
