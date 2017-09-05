.PHONY: default all clean

ASM = nasm
ASMFLAGS = -fobj -Wall
LD = alink
LDFLAGS = -oEXE -m

TARGETS = s160100 s320200
default: $(TARGETS)
all: default

.PRECIOUS: $(TARGET) $(OBJECTS)

clean:
	echo "Cleaning..."
	-rm -f *.o
	-rm -f $(TARGET)

s160100:
	$(ASM) $(ASMFLAGS) $@.asm -o $@.o
	$(LD) $@.o $(LDFLAGS) -o ../bin/$@.exe
	dosbox-x -conf ../conf/dosbox-x.conf -c "mount c ../bin/ && dir" -c "c:" -c $@.exe

s320200:
	$(ASM) $(ASMFLAGS) $@.asm -o $@.o
	$(LD) $@.o $(LDFLAGS) -o ../bin/$@.exe
	dosbox-x -conf ../conf/dosbox-x.conf -c "mount c ../bin/ && dir" -c "c:" -c $@.exe
