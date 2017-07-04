.PHONY: default all clean

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
	python3 misc/convert_to_320_200_16.py res/intro.data -o bin/image.raw

run: $(TARGET)
	echo "Running game..."
	dosbox-x -conf misc/dosbox-x.conf -c "mount c ./bin/ && dir" -c "c:" -c "unigames.exe"
