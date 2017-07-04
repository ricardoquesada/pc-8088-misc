.PHONY: default all clean

DOSBOX_PATH=~/Applications/DOSBox.app/Contents/MacOS/DOSBox

TARGET = bin/unigames.exe
ASM = nasm
ASMFLAGS = -fobj
LD = alink
LDFLAGS = -oEXE -m

default: $(TARGET)
all: res default

OBJECTS = $(patsubst src/%.asm, obj/%.o, $(wildcard src/*.asm))

obj/%.o: src/%.asm
	$(ASM) $(ASMFLAGS) $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS)
	echo "Linking..."
	$(LD) $(OBJECTS) $(LDFLAGS) -o $@

clean:
	echo "Cleaning..."
	-rm -f obj/*.o
	-rm -f $(TARGET)

res:
	echo "Generating resources..."
	python3 scripts/convert_to_320_200_16.py res/intro.data -o bin/image.raw

run:
	echo "Running game..."
	${DOSBOX_PATH} bin/unigames.exe
