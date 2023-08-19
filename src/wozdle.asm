* = $280

;   COMMON APPLE1 WOZMON

PRBYTE = $FFDC
ECHO   = $FFEF

WORD0 = $20
WORD1 = $21
WORD2 = $22
WORD3 = $23
WORD4 = $24

NUM0  = $25
NUM1  = $26
NUM2  = $27
NUM3  = $28


; Mapping from a 5 character word into a 4 bytes number
; a transcodes to a 1
; abcde => dddeeeee bcccccdd aaaabbbb 0000000a   
;            NUM0     NUM1     NUM2     NUM3
; "APPLE" => 41 50 50 4C 45
;         => 0000 0001  0001 0000  0001 0000  0000 1100  0000 0101
;         =>     00001      10000      10000      01100      00101
;         => .......0 00011000 01000001 10000101
;         => 10000101 01000001 00011000 00000000 
; "apple" => 85 41 18 00   

    JMP TEST

N2W:
    LDA #$40
    STA WORD4
    STA WORD3
    STA WORD2
    STA WORD1
    STA WORD0

        ; NUM0
    LDA NUM0
    TAX
    AND $1F
    ORA WORD4
    STA WORD4

    TXA
    ; No AND, as all bits goes right
    LSR
    LSR
    LSR
    LSR
    LSR
    ORA WORD3
    STA WORD3

        ; NUM1
    LDA NUM1
    TAX
    AND $03
    ASL
    ASL
    ASL
    ORA WORD3
    STA WORD3
    
    TXA
    AND $7c
    LSR
    LSR
    ORA WORD2
    STA WORD2
    
    TXA
    AND $80
    LSR
    LSR
    LSR
    LSR
    LSR
    LSR
    LSR ; (Should be CLC + 2 ROL)
    ORA WORD1
    STA WORD1

        ; NUM2
    LDA NUM2
    TAX
    AND $0f
    ASL
    ORA WORD1
    STA WORD1

    TXA
    AND $f0
    LSR
    LSR
    LSR
    LSR
    ORA WORD0
    STA WORD0

        ; NUM3
    LDA NUM3
    ASL
    ASL
    ASL
    ASL
    ORA WORD0
    STA WORD0

    RTS

;   Creates the number for the word (WORD0 => NUM0)
W2N:
        ;   4th letter
    LDA WORD4
    EOR #$40    ;   Letter index
    STA NUM0

        ;   3rd letter
    LDA WORD3
    EOR #$40    ;   Letter index
    TAX
    ASL
    ASL
    ASL
    ASL
    ASL
    ORA NUM0
    STA NUM0
    TXA
    LSR
    LSR
    LSR
    STA NUM1

        ; 2nd letter
    LDA WORD2
    EOR #$40    ;   Letter index
    ASL
    ASL
    ORA NUM1
    STA NUM1

        ; 1st letter
    LDA WORD1
    EOR #$40    ;   Letter index
    TAX
    ROR         ;   Could do better if NUM1 was already shifter of one bit
    ROR
    AND #$80
    ORA NUM1
    STA NUM1
    TXA
    LSR
    STA NUM2

        ;  0th letter
    LDA WORD0
    EOR #$40    ;   Letter index
    CLC
    ROL
    ROL
    ROL
    ROL
    TAX
    LDA #$00
    ADC #$00
    STA NUM3
    TXA
    ORA NUM2
    STA NUM2
    RTS

    ;   Tests conversions
TEST:
    LDA #$0d
    JSR ECHO
    JSR ECHO

    LDX #$00
    LDY #$00
LOOP0:
    LDA TESTDATA,Y
    CMP #$00
    BEQ DONE
    STA WORD0,X
    INX
    INY

    CPX #$05
    BNE LOOP0
    JSR W2N
    JSR N2W
    JSR W2N ; Way to test, mostly good [blog?]

    LDX #$00
LOOP1:
    LDA TESTDATA,Y
    CMP NUM0,X
ERROR:
    BNE ERROR
    INY
    INX
    CPX #$04
    BNE LOOP1

    LDX #$00
    JMP LOOP0

DONE:
    JSR ECHOPASSED
HALT:
    JMP HALT

ECHOPASSED:
    LDX #$00
LOOP2:
    LDA MSGPASSED,X
    JSR ECHO
    INX
    CMP #$00
    BNE LOOP2
    RTS


MSGPASSED:
.byte "TEST PASSED"
.byte $d,0

TESTDATA:
.byte "APPLE"   ; 00184185
.byte $85,$41,$18,$00
.byte "STEVE"   ; 013a16c5
.byte $c5,$16,$3a,$01
.byte "OOOOO"   ; 00f7bdef
.byte $ef,$bd,$f7,$00
.byte "ZZZZZ"   ; 01ad6b5a
.byte $5a,$6b,$ad,$01
.byte "PPPPP"   ; 01084210
.byte $10,$42,$08,$01
.byte 0

#include "obj/vocabulary.asm"
