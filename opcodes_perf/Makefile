.PHONY: default all clean res

TARGET_NAME = perf.exe
TARGET = ../bin/${TARGET_NAME}
ASM = nasm
ASMFLAGS = -fobj -Wall
LD = alink
LDFLAGS = -oEXE -m

default: $(TARGET)
all: res default

OBJECTS = perf.o ../common/pztimer.o

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
	echo "Running..."
	dosbox-x -conf ../conf/dosbox-x_tandy.conf -c "mount c ../bin/ && dir" -c "c:" -c ${TARGET_NAME}

