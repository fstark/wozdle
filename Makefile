all: 32KWOZDLE.BIN

obj/wozdle.snp: WOZDLE
	( /bin/echo -en "LOAD:\x02\x80DATA:" ; cat WOZDLE ) > obj/wozdle.snp

WOZDLE: src/wozdle.asm obj/data.asm
	mkdir -p obj
	xa -C -o WOZDLE src/wozdle.asm

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

32KWOZDLE.BIN: WOZDLE bin/makeeprom
	bin/makeeprom 8192 < WOZDLE > 32KWOZDLE.BIN

obj/wozdle.bin: WOZDLE bin/makeeprom
	# bin/makeeprom 24576 < WOZDLE > obj/wozdle.bin
	bin/makeeprom 8192 < WOZDLE > obj/wozdle.bin
	# bin/makeeprom 28672 < WOZDLE > obj/wozdle.bin

eeprom: 32KWOZDLE.BIN
	@echo "Copy of binary into a X28C256 via MiniPro"
	minipro -p X28C256 -w 32KWOZDLE.BIN

eprom: 32KWOZDLE.BIN
	@echo "Copy of binary into a AM27C256 via MiniPro"
	# minipro -p AM27C256@DIP28 -w 32KWOZDLE.BIN
	minipro -p D27256@DIP28 -w 32KWOZDLE.BIN
