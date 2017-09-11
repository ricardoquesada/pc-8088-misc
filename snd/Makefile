.PHONY: default all clean

ASM = nasm
ASMFLAGS = -fobj -Wall
LD = alink
LDFLAGS = -oEXE -m

TARGETS = tandysnd vgmplayer pvmplayer
default: $(TARGETS)
all: default

.PRECIOUS: $(TARGETS) $(OBJECTS)

clean:
	echo "Cleaning..."
	-rm -f *.o

tandysnd:
	$(ASM) $(ASMFLAGS) $@.asm -o $@.o
	$(LD) $@.o $(LDFLAGS) -o ../bin/$@.exe
	dosbox-x -conf ../conf/dosbox-x.conf -c "mount c ../bin/ && dir" -c "c:" -c "$@.exe zelda2.snd"

vgmplayer:
	$(ASM) $(ASMFLAGS) $@.asm -o $@.o
	$(LD) $@.o $(LDFLAGS) -o ../bin/$@.exe
	dosbox-x -conf ../conf/dosbox-x.conf -c "mount c ../bin/ && dir" -c "c:" -c "vgmpla~1.exe"

pvmplayer:
	$(ASM) $(ASMFLAGS) $@.asm -o $@.o
	$(LD) $@.o $(LDFLAGS) -o ../bin/$@.exe
	dosbox-x -conf ../conf/dosbox-x.conf -c "mount c ../bin/ && dir" -c "c:" -c "pvmpla~1.exe"
