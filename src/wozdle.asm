* = $280

;   WozMon definitions

PRBYTE = $FFDC
ECHO   = $FFEF

KBD   = $D010	; Keyboard I/O
KBDCR = $D011

; ---------------------------------------------------------------------------------
;   ZP Variables
;   TODO WORD0-WORD4 and NUM0-NUM3 into +1,2,3, etc...
; ---------------------------------------------------------------------------------


WORD  = $20
WORD0 = WORD     ;   The current word register in alphabetical form
WORD1 = $21
WORD2 = $22
WORD3 = $23
WORD4 = $24

NUM   = $25
NUM0  = NUM      ;   The current word register in numerical form
NUM1  = $26
NUM2  = $27
NUM3  = $28

VOCPTR = $29    ;   Pointer to the vocabulary
ANSPTR = $2B    ;   Pointer to the answer bitmap

ANSINX = $2D    ;   Index of answer searched in answers

ANSCUR = $2F    ;   Workin area, current 8 bits of answer bitmap

MSG    = $30    ;   Pointer to message to display

TARGET = $32    ;   Target word to find (5 bytes)

WHITE = 0
GRAY = 1
YELLOW = 2
GREEN = 3
; 0=>non exist, 1=>gray, 2=>yellow, 3=>green
COLORS = $37    ;   Colors of the guess (size 5)

; GUESSCHAR = $3C ;   Current char checked form guess
GUESSCHARIX = $3D   ;   Current letter index checked form guess

GUESSCOUNT = $3E;   Current number of guesses done
GUESSIX = $3F   ;   Current guess drawn
HISTORY = $40   ;   30 bytes containing the guess history
LETTERS = $5E           ; The 26 letters and what we know about them (WHITE, GRAY, YELLOW, GREEN)

MAXGUESS = 6

INITGAME:
.(
    LDA #$00
    STA GUESSCOUNT      ; No guesses yet

        ;   Sets the 26 letters to WHITE
    LDX #26
LOOP1:
    DEX
    STA LETTERS,X
    BNE LOOP1

    JSR RNDINIT         ;   Generates a random word to search

    JSR PAGEFEED

    LDA #<MSGRULES
    STA MSG
    LDA #>MSGRULES
    STA MSG+1
    JSR MSGOUT

    LDA #<WELCOME
    STA MSG
    LDA #>WELCOME
    STA MSG+1
    JSR MSGOUT
MAIN:

CONT:

        ; Draw all the guesses
    LDA #$0
    STA GUESSIX
LOOP2:
    LDA GUESSCOUNT
    CMP GUESSIX
    BEQ CONT2            ;   Stop at GUESSCOUNT
    JSR DRAWGUESS       ;   Draw guess
    INC GUESSIX
    JMP LOOP2

CONT2:
    JSR GUESSGET        ;   Ask user for a guess
    BNE REFRESH

    JSR UPDATE          ;   Update keyboard and stuff

    LDA GUESSCOUNT      ;   So the draw knows the keyboard is needed
    SEC
    SBC #1
    STA GUESSIX
    JSR DRAWGUESS2      ;   Draws the guess, without the guessed word
    JMP CONT2           ;   Ask for next guess  

REFRESH:
    JSR PAGEFEED
    JMP MAIN


EXIT:
    JMP HALT
.)

DRAWGUESS:
                        ; Multiply GUESSIX by 5
    LDA GUESSIX
    ASL
    ASL
    ADC GUESSIX

                        ; Copy the guess in WORD while
    TAX
    LDY #0
        ; Transfers from X to Y
    JSR CPYECHO1
    JSR CPYECHO1
    JSR CPYECHO1
    JSR CPYECHO1
    JSR CPYECHO1

DRAWGUESS2:

    LDA GUESSIX
    CLC
    ADC #1
    CMP GUESSCOUNT
    BNE SKIPKBD1

    LDA #<KBDTOP
    STA MSG
    LDA #>KBDTOP
    STA MSG+1
    JSR MSGOUT
    JMP CONTKBD1

SKIPKBD1:
    LDA #$0d
    JSR ECHO

CONTKBD1:
    JSR WRD2COL         ;   Update the color status
    JSR PRTCOLORS       ;   Print colors symbols

    LDA GUESSIX ; ### Ugly duplication
    CLC
    ADC #1
    CMP GUESSCOUNT
    BNE SKIPKBD

    LDA #<KBD0
    STA MSG
    LDA #>KBD0
    STA MSG+1
    JSR DRAWKBDLINE

    LDA #<KBD1
    STA MSG
    LDA #>KBD1
    STA MSG+1
    JSR DRAWKBDLINE

    LDA #<KBD2
    STA MSG
    LDA #>KBD2
    STA MSG+1
    JSR DRAWKBDLINE
    RTS

SKIPKBD:
    LDA #$0d
    JSR ECHO
    JSR ECHO
    JSR ECHO

    RTS

CPYECHO1:
    LDA HISTORY,X
    STA WORD,Y
    JSR ECHO
    LDA #" "
    JSR ECHO
    INX
    INY
    RTS

    ;   Draws a keyboard line
    ;   Remove letters if unavailable
    ;   Follows letter by '!' or '?' depending on color
DRAWKBDLINE:
.(
    LDY #$00
LOOP:
    LDA (MSG),Y
    BEQ END

        ;   If not a letter, skip
    CMP #"A"
    BMI NONLETTER
    CMP #"Z"+1
    BPL NONLETTER

        ;   Get the index in the LETTERS state
    SEC
    SBC #"A"
    TAX

        ;   State of the letter
    LDA LETTERS,X

    CMP #WHITE      ;   Letter has never been used
    BNE CONT1
    LDA (MSG),Y
    JSR ECHO
    JMP CONT4

CONT1:
    CMP #GRAY       ;   Letter is not in the word
    BNE CONT2
    INY             ;   We duplicate the next character
    LDA (MSG),Y
    JSR ECHO
    JSR ECHO
    JMP CONT4

CONT2:
    CMP #YELLOW     ;   Letter is somewhere
    BNE CONT3
    LDA (MSG),Y     ;   We draw the letter
    JSR ECHO
    INY
    LDA #"?"        ;   Followed by a '?'
    JSR ECHO
    JMP CONT4

CONT3:
                    ;   We know we are green

    LDA (MSG),Y     ;   We draw the letter
    JSR ECHO
    INY
    LDA #"!"        ;   Followed by a '!'
    JSR ECHO
    JMP CONT4

NONLETTER:
    JSR ECHO

CONT4:
    INY
    JMP LOOP
END:
    RTS
.)

KBDTOP:
    .byte "______________________________", 0
KBD0:
    .byte "\Q  W  E  R  T  Y  U  I  O  P ", 0
KBD1:
    .byte "           \A  S  D  F  G  H  J  K _L__/", 0
KBD2:
    .byte "            \Z__X__C__V__B__N__M__/     ", 0

;   Updates the keyboard status, win/lose, game turn, etc...
UPDATE:
.(
    JSR WRD2COL         ;   Get current color status

    LDX #0
LOOP:
    LDA WORD,X
    SEC                 ;   Beware SBC works the opposite of what you may think
    SBC #$41
    TAY
    LDA COLORS,X
    CMP LETTERS,Y       ;   Update only if status is "better"
    BMI SKIP
    STA LETTERS,Y
SKIP:
    INX
    CPX #5 
    BNE LOOP

        ;   Add word to history
                        ; Multiply GUESSCOUNT by 5
    LDA GUESSCOUNT
    ASL
    ASL
    ADC GUESSCOUNT

                        ; Copy the guess in history
    TAX
    LDA WORD
    STA HISTORY,X
    LDA WORD+1
    STA HISTORY+1,X
    LDA WORD+2
    STA HISTORY+2,X
    LDA WORD+3
    STA HISTORY+3,X
    LDA WORD+4
    STA HISTORY+4,X

                        ;   Increment guess count
    INC GUESSCOUNT

    RTS
.)


    JSR TEST
    ; JSR DBGVOCDUMP

    JSR RNDINIT
    LDA #">"
    JSR ECHO
    JSR DBGW


; Update color state according to current word
WRD2COL:
        ;   Compare WORD and TARGET according to Wozdle rules

        ;   Fills the COLORS array with the correct color rules
    JSR SETALLGRAY

    LDA #0
    STA GUESSCHARIX
    JSR SETGREEN
    INC GUESSCHARIX
    JSR SETGREEN
    INC GUESSCHARIX
    JSR SETGREEN
    INC GUESSCHARIX
    JSR SETGREEN
    INC GUESSCHARIX
    JSR SETGREEN

    LDA #0
    STA GUESSCHARIX
    JSR SETYELLOW
    INC GUESSCHARIX
    JSR SETYELLOW
    INC GUESSCHARIX
    JSR SETYELLOW
    INC GUESSCHARIX
    JSR SETYELLOW
    INC GUESSCHARIX
    JSR SETYELLOW

    JSR UNEXCLUDE

    ; LDA #$0d
    ; JSR ECHO
    ; LDA #" "
    ; JSR ECHO
    ; JSR PRTCOLORS

    RTS




WELCOME:
.byte "  *   *  ***  ***** ****  *     *****", $0d
.byte "  *   * *   * *   * *   * *     *", $0d
.byte "  *   * *   *    *  *   * *     *", $0d
.byte "  *   * *   *   *   *   * *     ***", $0d
.byte "  * * * *   *  *    *   * *     *", $0d
.byte "  * * * *   * *   * *   * *     *", $0d
.byte "   * *   ***  ***** ****  ***** *****", $0d, $0d
; WELCOME:
.byte $0d,$00


    ; .byte $0d
    ; .byte "  WOZDLE                                "
    ; .byte "  (BY FRED & ANTOINE STARK)             "
    ; .byte "                                        "
    ; .byte "E A T E N ______________________________"
    ; .byte "?   ?     \Q  W  E  R  T  Y  U  I  O  P "
    ; .byte "           \A  S  D  F  G  H  J  K _L__/"
    ; .byte "            \Z__X__C__V__B__N__M__/     "
    .byte 0

    ;   Print all colors for the current word
PRTCOLORS:
.(
    LDY #0
LOOP:
    LDA COLORS,Y
    CMP #GREEN
    BNE CONT1
    LDA #"!"
    JMP CONT3
CONT1:
    CMP #YELLOW
    BNE CONT2
    LDA #"?"
    JMP CONT3
CONT2:
    LDA #" "
CONT3:
    JSR ECHO
    LDA #" "
    JSR ECHO
    INY
    CPY #05
    BNE LOOP
    RTS
.)

    ;   Init word colors to all gray
SETALLGRAY:
    LDA #GRAY
    STA COLORS
    STA COLORS+1
    STA COLORS+2
    STA COLORS+3
    STA COLORS+4
    RTS

    ;   Test if GUESSCHARIX whould be greened
SETGREEN:
.(
    LDY GUESSCHARIX         ;   Load guess character
    LDA WORD,Y
    CMP TARGET,Y      ;   At same place in target?
    BNE DONE
    JSR EXCLUDE         ;   We now exlude this char
    LDA #GREEN          ;   Is green
    STA COLORS,Y
DONE:
    RTS
.)

    ;   Test if GUESSCHARIX should be yellowed.
SETYELLOW:
.(
    LDY GUESSCHARIX         ;   Load guess character
    LDA COLORS,Y      ;   Skip green
    CMP #GREEN
    BEQ DONE
    LDA WORD,Y
    LDY #$0            ;   Loop over target
LOOP:
    CMP TARGET,Y
    BNE CONT
    JSR EXCLUDE         ;   If found, exclude this letter of target
                        ;   from the next calculations
    LDA #YELLOW         ;   Sets the letter color
    LDY GUESSCHARIX
    STA COLORS,Y
    RTS
CONT:
    INY
    CPY #5
    BNE LOOP
DONE:
    RTS
.)

    ;   Excludes the character at index Y
EXCLUDE:
    LDA #$80
    ORA TARGET,Y
    STA TARGET,Y
    RTS

    ;   Clear all exclusion flags
UNEXCLUDE:
    LDA #$7F
    TAX
    AND TARGET
    STA TARGET
    TXA
    AND TARGET+1
    STA TARGET+1
    TXA
    AND TARGET+2
    STA TARGET+2
    TXA
    AND TARGET+3
    STA TARGET+3
    TXA
    AND TARGET+4
    STA TARGET+4
    RTS

    LDA #$7f
    STA <ANSINX
    LDA #$01
    STA <ANSINX+1

    JSR ANSSEEK
    JSR N2W
    JSR DBGW
    JMP HALT

; Seek answer of index ANSWINX
; Stored in NUM0-3
ANSSEEK:
.(
    JSR NUMCLR

    LDA #<ANSWERS
    STA ANSPTR
    LDA #>ANSWERS
    STA ANSPTR+1

LOOP1:
    JSR ANSNEXT     ;   Loads 8 bits of answers
    STA ANSCUR

    LDX #$08
LOOP2:
    JSR NEXTVOCPTR  ;   Jumps vocabulary pointer to next word

    ROL ANSCUR
    BCC CONTINUE
                    ;   Current word is an answer

    LDA ANSINX      ;   Are we done? (ANSINX==0)
    ORA ANSINX+1   
    BEQ DONE

    LDA ANSINX      ;   Decrement answer index
    BNE SKIPDEC
    DEC ANSINX+1
SKIPDEC:
    DEC ANSINX

CONTINUE:
    DEX
    BNE LOOP2
    JMP LOOP1

DONE:
    RTS

    ; Loads A with the next 8 bitmap of answers and increment answer ptr
    ; note could be faster is pointer is one *behind*
ANSNEXT:
    LDA #$00
    TAY
    LDA (ANSPTR),Y
    TAY
    INC ANSPTR
    BNE CONT
    INC ANSPTR+1
CONT:
    TYA
    RTS
.)

    JMP HALT

; ---------------------------------------------------------------------------------
;   Gnerates a random TARGET word
; ---------------------------------------------------------------------------------
RNDINIT:
.(
        ;   Display user message
    LDA #<RNDMSG
    STA MSG
    LDA #>RNDMSG
    STA MSG+1
    JSR MSGOUT

        ;   Eats any key already pressed
    LDA KBD           

        ;   Wait for space while incrementing random
LOOP1:
                        ;   Increment ANSINX to create entrpy
                        ;   based on player speed
    INC ANSINX
    BNE CONT
    INC ANSINX+1
CONT:
    LDA KBDCR           ;   Key pressed?
    BPL LOOP1           ;   No
    LDA KBD             ;   Key pressed
    AND #$3f            ;   Last 6 bits
    CMP #$20            ;   Space?
    BNE LOOP1           ;   Nope

        ; Get the number mod ANSCOUNT (2309)
        ; By adding ANSCOUNT until we have a carry
LOOP2:
    CLC
    LDA ANSINX
    ADC #<ANSCOUNT
    STA ANSINX
    LDA ANSINX+1
    ADC #>ANSCOUNT
    STA ANSINX+1
    BCC LOOP2

    ; Hack for apple
    ; LDA #96
    ; STA ANSINX
    ; LDA #00
    ; STA ANSINX+1

        ;   Here ANSINX is a random number between 0 and ANSCOUNT-1
    JSR ANSSEEK         ;   We load the corresponding vocabulatory enrty
                        ;   (note the time to load gives the player an indication of the place of the word)

    JSR N2W             ;   Gets it in ASCII form into TARGET
    LDA WORD0
    STA TARGET
    LDA WORD1
    STA TARGET+1
    LDA WORD2
    STA TARGET+2
    LDA WORD3
    STA TARGET+3
    LDA WORD4
    STA TARGET+4

    RTS

RNDMSG:
    .byte $0d, $0d, "       -- press space to start --"
    .byte $0d, $00
.)

MSGRULES:
    .byte $0d, $0d,
    .byte "Rules: you must guess a 5 letter word", $0d,
    .byte "       you have 6 tries", $0d
    .byte "       type when the cursor is", $0d
    .byte "       in the bottom-left corner", $0d,$0d
    .byte "       ! : Letter placed properly", $0d
    .byte "       ? : Letter placed improperly", $0d, $0d
    .byte "       may the woz be with you", $0d, $0d, $0d, $0d, $0d
    .byte $0d, $00

; ---------------------------------------------------------------------------------
;   Reads a vocabulary word into WORD
; ---------------------------------------------------------------------------------
GUESSGET:
.(
        ; Get 5 chars with echo
    LDX #0
LOOPX:
    JSR KBDGET
    STA WORD,X
    JSR ECHO
    LDA #" "
    JSR ECHO
    INX
    CPX #05
    BNE LOOPX

    JSR W2N             ; As num

    ;   We will seek in the vocabulary, starting at -NUM (+aaaaa)
    ;   If we end up with exactly zero, the word is in the vocabulary

    LDA #$FF            ; 2 complement
    TAX
    EOR NUM
    STA NUM
    TXA
    EOR NUM+1
    STA NUM+1
    TXA
    EOR NUM+2
    STA NUM+2
    TXA
    EOR NUM+3
    STA NUM+3

    INC NUM
    BNE INCDONE
    INC NUM+1
    BNE INCDONE
    INC NUM+2
    BNE INCDONE
    INC NUM+3
INCDONE:

    JSR NUMADJUST       ;   Adds 'aaaaa' to the number

        ;   Scan the vocabulary until num is larger or equal to zero
LOOP:
    JSR NEXTVOCPTR      ;   Next vocabulary entry
    LDA NUM+3           ;   While negative
    BNE LOOP            ;   Loop

    ORA NUM+2           ;   Check if NUM0-NUM3 is zero
    ORA NUM+1
    ORA NUM

    RTS                 ;   Z = 1 if valid guess
.)

; ---------------------------------------------------------------------------------
;   Print message
; ---------------------------------------------------------------------------------
MSGOUT:
.(
    LDY #$00
LOOP:
    LDA (MSG),Y
    BEQ END
    JSR ECHO
    INY
    JMP LOOP
END:
    RTS
.)

; ---------------------------------------------------------------------------------
;   Scrolls a blank new screen
; ---------------------------------------------------------------------------------

PAGEFEED:
.(
    LDA #$0d
    LDX #$24
LOOP:
    JSR ECHO
    DEX
    BNE LOOP
    RTS
.)

; ---------------------------------------------------------------------------------
;   Reads a character, no echo
; ---------------------------------------------------------------------------------

KBDGET:
    LDA KBDCR
    BPL KBDGET
    LDA KBD
    AND #$7F
    ; JSR PRBYTE
    RTS

KBDPEEK:
.(
    LDA KBDCR
    BMI DONE
    LDA #$00
    RTS
DONE:
    LDA KBD
    RTS
.)


; ---------------------------------------------------------------------------------
;   Num management support routines
; ---------------------------------------------------------------------------------

NUMCLR:         ;   Sets 'aaaaa' as the current numerical word
    LDA #$00
    STA NUM0
    STA NUM1
    STA NUM2
    STA NUM3
NUMADJUST:      ;   Adjusts num by adding 'aaaaa'
    CLC
    LDA #$21
    ADC NUM0
    STA NUM0
    LDA #$84
    ADC NUM1
    STA NUM1
    LDA #$10
    ADC NUM2
    STA NUM2
    LDA #$00
    ADC NUM3
    STA NUM3

    LDA #<VOCABULARY
    STA VOCPTR
    LDA #>VOCABULARY
    STA VOCPTR+1

    RTS






;   Note: preserves X
NEXTVOCPTR1:
        ;   Adds 1 bytes (128-16383)
    LDA (VOCPTR),Y
    AND #$7f
    CLC
    ADC NUM0
    STA NUM0

    LDA #$00
    ADC NUM1
    STA NUM1
    LDA #$00
    ADC NUM2
    STA NUM2
    LDA #$00
    ADC NUM3
    STA NUM3

    CLC
    LDA #$01
    ADC VOCPTR
    STA VOCPTR
    LDA #$00
    ADC VOCPTR+1
    STA VOCPTR+1

    RTS

NEXTVOCPTR2:
        ;   Adds 2 bytes (128-16383)
    LDY #$01
    LDA (VOCPTR),Y
    CLC
    ADC NUM0
    STA NUM0

    DEY
    LDA (VOCPTR),Y
    AND #$3f
    ADC NUM1
    STA NUM1

    LDA #$00
    ADC NUM2
    STA NUM2
    LDA #$00
    ADC NUM3
    STA NUM3

    CLC
    LDA #$02
    ADC VOCPTR
    STA VOCPTR
    LDA #$00
    ADC VOCPTR+1
    STA VOCPTR+1

    RTS

NEXTVOCPTR:
    LDY #$00
    LDA (VOCPTR),Y
    ROL
    BCC NEXTVOCPTR1
    ROL
    BCC NEXTVOCPTR2

NEXTVOCPTR3:
        ;   Adds 3 bytes (16384-)
    LDY #$02
    LDA (VOCPTR),Y
    CLC
    ADC NUM0
    STA NUM0

    DEY
    LDA (VOCPTR),Y
    ADC NUM1
    STA NUM1

    DEY
    LDA (VOCPTR),Y
    AND #$3f
    ADC NUM2
    STA NUM2

    LDA #$00
    ADC NUM3
    STA NUM3

    CLC
    LDA #$03
    ADC VOCPTR
    STA VOCPTR
    LDA #$00
    ADC VOCPTR+1
    STA VOCPTR+1

    RTS

; ---------------------------------------------------------------------------------
;   Words to numbers back and forth mapping
; ---------------------------------------------------------------------------------

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
    AND #$1F
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
    AND #$03
    ASL
    ASL
    ASL
    ORA WORD3
    STA WORD3
    
    TXA
    AND #$7c
    LSR
    LSR
    ORA WORD2
    STA WORD2
    
    TXA
    AND #$80
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
    AND #$0f
    ASL
    ORA WORD1
    STA WORD1

    TXA
    AND #$f0
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

; ---------------------------------------------------------------------------------
;   Test routines
; ---------------------------------------------------------------------------------

    ;   Tests words-num conversions
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
    JSR W2N ; Way to test, mostly good [blog? yes]

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
    RTS
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
.byte "ABAFT"   ; 001104d4
.byte $d4,$04,$11,$00
.byte "ABADT"   ; 00110494
.byte $94,$04,$11,$00
.byte 0

; ---------------------------------------------------------------------------------
;   Debug helpers
; ---------------------------------------------------------------------------------

;   Dumps all vocabulary
DBGVOCDUMP:
    JSR NUMCLR
    LDA #<VOCABULARY
    STA VOCPTR
    LDA #>VOCABULARY
    STA VOCPTR+1

LL:
    JSR NEXTVOCPTR
    JSR N2W
    JSR DBGW
    ; JSR KBDIN
    JMP LL

    JMP HALT

DBGW:
    LDA WORD0
    JSR ECHO
    LDA WORD1
    JSR ECHO
    LDA WORD2
    JSR ECHO
    LDA WORD3
    JSR ECHO
    LDA WORD4
    JSR ECHO
    LDA #$20
    JSR ECHO
    RTS

#include "obj/data.asm"
