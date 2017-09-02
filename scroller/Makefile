.PHONY: default all clean

ASM = nasm
ASMFLAGS = -fobj -Wall
LD = alink
LDFLAGS = -oEXE -m

TARGETS = s160100
default: $(TARGETS)
all: default

.PRECIOUS: $(TARGET) $(OBJECTS)

clean:
	echo "Cleaning..."
	-rm -f *.o
	-rm -f $(TARGET)

s160100:
	$(ASM) $(ASMFLAGS) s160100.asm -o s160100.o
	$(LD) s160100.o $(LDFLAGS) -o ../bin/s160100.exe
	dosbox-x -conf ../conf/dosbox-x.conf -c "mount c ../bin/ && dir" -c "c:" -c s160100.exe
