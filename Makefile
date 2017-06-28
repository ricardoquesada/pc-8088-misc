.SILENT:

.PHONY: res run

DOSBOX_PATH=~/Applications/DOSBox.app/Contents/MacOS/DOSBox

SRC=src/main.asm

all: res unigames

unigames: ${SRC}
	echo "Compiling..."
	nasm -f elf -o obj/$@.o $^
	smlrl -small obj/$@.o -o bin/unigames.exe -map obj/unigames.map

res:
	echo "Generating resources..."
	python3 scripts/convert_to_320_200_16.py res/intro.data -o bin/image.raw

run:
	echo "Running game..."
	${DOSBOX_PATH} bin/unigames.exe

clean:
	rm obj/*
	rm bin/*
