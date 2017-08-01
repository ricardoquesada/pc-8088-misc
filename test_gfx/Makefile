.PHONY: default all clean res

TARGET_NAME = t320200.exe
TARGET = bin/${TARGET_NAME}
ASM = nasm
ASMFLAGS = -fobj -Wall
LD = alink
LDFLAGS = -oEXE -m

default: $(TARGET)
all: res default

OBJECTS = test_320_200_16.o pztimer.o

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

res:
	echo "Generating resources..."
	python3 ../tools/convert_to_320_200_16.py res/intro.data -o bin/32020016.raw

run: $(TARGET)
	echo "Running game..."
	dosbox-x -conf ../conf/dosbox-x.conf -c "mount c ./bin/ && dir" -c "c:" -c ${TARGET_NAME}
