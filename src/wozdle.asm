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

; Transforms a 5 character word into a 4 bytes number
; a transcodes to a 1
; abcde => dddeeeee bcccccdd aaaabbbb 0000000a   
;            NUM0     NUM1     NUM2     NUM3
; "APPLE" => 41 50 50 4C 45
;         => 0000 0001  0001 0000  0001 0000  0000 1100  0000 0101
;         =>     00001      10000      10000      01100      00101
;         => .......0 00011000 01000001 10000101
;         => 10000101 01000001 00011000 00000000 
; "apple" => 85 41 18 00   

    ; LDA #"A"
    ; STA WORD0
    ; LDA #"P"
    ; STA WORD1
    ; LDA #"P"
    ; STA WORD2
    ; LDA #"L"
    ; STA WORD3
    ; LDA #"E"
    ; STA WORD4

    LDA #$0d
    JSR ECHO
    JSR ECHO

    LDX #$00
    LDY #$00
LOOP:
    LDA TEST,Y
    CMP #$00
    BEQ HALT
    CMP #$01
    BNE CONT
    JSR W2N
    INY
    LDX #$00
    JMP LOOP
CONT:
    STA WORD0,X
    INX
    INY
    JMP LOOP

HALT:
    JMP HALT

TEST:
.byte "APPLE"   ; 00184185
.byte 1
.byte "STEVE"   ; 013a16c5
.byte 1
.byte "OOOOO"   ; 00f7bdef
.byte 1
.byte "ZZZZZ"   ; 01ad6b5a
.byte 1
.byte "PPPPP"   ; 01084210
.byte 1
.byte 0
; .byte $85, $41, $18, $00


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

        ;   OUTPUT
    LDA #$20
    TAX
    LDA NUM0
    JSR PRBYTE
    TXA
    JSR ECHO

    LDA NUM1
    JSR PRBYTE
    TXA
    JSR ECHO

    LDA NUM2
    JSR PRBYTE
    TXA
    JSR ECHO

    LDA NUM3
    JSR PRBYTE
    TXA
    JSR ECHO

    LDA #$0d
    JSR ECHO

    RTS
