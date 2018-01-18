.PHONY: default all clean res

TARGET_NAME = undiagjr.exe
TARGET = ${TARGET_NAME}
ASM = nasm
ASMFLAGS = -fobj -Wall
LD = alink
LDFLAGS = -oEXE -m

default: $(TARGET)
all: default

OBJECTS = undiagjr.o

%.o: %.asm
	$(ASM) $(ASMFLAGS) $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	echo "Linking..."
	$(LD) $(OBJECTS) $(LDFLAGS) -o $@

clean:
	echo "Cleaning..."
	-rm -f *.o *.map *.exe

run: $(TARGET)
	echo "Running..."
	dosbox-x -conf ../conf/dosbox-x_pcjr.conf -c "mount c ./ && dir" -c "c:" -c ${TARGET_NAME}
