.PHONY: default all clean res

TARGET_NAME = test_gfx.exe
TARGET = bin/${TARGET_NAME}
ASM = nasm
ASMFLAGS = -fobj -Wall
LD = alink
LDFLAGS = -oEXE -m

default: $(TARGET)
all: res default

OBJECTS = test_gfx.o pztimer.o

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
	python3 ../tools/convert_to_bios.py res/320_200.data -g 4 -o bin/32020004.raw
	python3 ../tools/convert_to_bios.py res/640_200.data -g 6 -o bin/64020002.raw
	python3 ../tools/convert_to_bios.py res/160_200.data -g 8 -o bin/16020016.raw
	python3 ../tools/convert_to_bios.py res/320_200.data -g 9 -o bin/32020016.raw
	python3 ../tools/convert_to_bios.py res/640_200.data -g 10 -o bin/64020004.raw

run: $(TARGET)
	echo "Running game..."
	dosbox-x -conf ../conf/dosbox-x.conf -c "mount c ./bin/ && dir" -c "c:" -c ${TARGET_NAME}
