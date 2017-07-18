.PHONY: default all clean

TARGET = bin/dumpbios.exe
ASM = nasm
ASMFLAGS = -fobj -Wall
LD = alink
LDFLAGS = -oEXE -m

default: $(TARGET)
all: default

OBJECTS = dumpbios.o

%.o: %.asm
	$(ASM) $(ASMFLAGS) $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	echo "Linking..."
	$(LD) $(OBJECTS) $(LDFLAGS) -o $@

clean:
	echo "Cleaning..."
	-rm -f *.o
	-rm -f $(TARGET)

run: $(TARGET)
	echo "Running game..."
	dosbox-x -conf ./dosbox-x.conf -c "mount c ./bin/ && dir" -c "c:" -c "dumpbios.exe"
