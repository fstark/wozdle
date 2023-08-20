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
