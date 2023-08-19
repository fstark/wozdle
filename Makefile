all: bin/wozdleutil obj/wozdle.snp

obj/wozdle.snp: obj/wozdle.o65
	( echo -e foo )
	( /bin/echo -en "LOAD:\x02\x80DATA:" ; cat obj/wozdle.o65 ) > obj/wozdle.snp

obj/wozdle.o65: src/wozdle.asm obj/vocabulary.asm
	mkdir -p obj
	xa -o obj/wozdle.o65 src/wozdle.asm

clean:
	rm -rf bin obj

bin/wozdleutil: src/wozdleutil.cpp
	mkdir -p bin
	c++ src/wozdleutil.cpp -o bin/wozdleutil

obj/vocabulary.asm: data/vocabulary.txt bin/wozdleutil
	bin/wozdleutil > obj/vocabulary.asm

# Test under mame
test: obj/wozdle.snp
	mame -debug apple1 -ui_active -resolution 640x480 -snapshot obj/wozdle.snp
