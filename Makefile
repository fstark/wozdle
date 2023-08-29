all: bin/wozdleutil obj/wozdle.snp

obj/wozdle.snp: obj/wozdle.o65
	( echo -e foo )
	( /bin/echo -en "LOAD:\x02\x80DATA:" ; cat obj/wozdle.o65 ) > obj/wozdle.snp

obj/wozdle.o65: src/wozdle.asm obj/data.asm
	mkdir -p obj
	xa -C -o obj/wozdle.o65 src/wozdle.asm

clean:
	rm -rf bin obj

bin/wozdleutil: src/wozdleutil.cpp
	mkdir -p bin
	c++ src/wozdleutil.cpp -o bin/wozdleutil

obj/data.asm: data/vocabulary.txt data/answers.txt bin/wozdleutil
	mkdir -p obj
	bin/wozdleutil > obj/data.asm

# Test under mame
test: obj/wozdle.snp
	mame -debug apple1 -ui_active -resolution 640x480 -snapshot obj/wozdle.snp

bin/makeeprom: src/makeeprom.cpp
	mkdir -p bin
	c++ src/makeeprom.cpp -o bin/makeeprom

obj/wozdle.bin: obj/wozdle.o65 bin/makeeprom
	# bin/makeeprom 24576 < obj/wozdle.o65 > obj/wozdle.bin
	bin/makeeprom 8192 < obj/wozdle.o65 > obj/wozdle.bin

eeprom: obj/wozdle.bin
	@echo "Copy of binary into a X28C256 via MiniPro"
	minipro -p X28C256 -w obj/wozdle.bin

eprom: obj/wozdle.bin
	@echo "Copy of binary into a AM27C256 via MiniPro"
	# minipro -p AM27C256@DIP28 -w obj/wozdle.bin
	minipro -p D27256@DIP28 -w obj/wozdle.bin
