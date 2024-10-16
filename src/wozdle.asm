* = $2000
;* = $0280

;   WozMon definitions

PRBYTE = $FFDC
ECHO   = $FFEF

KBD   = $D010	; Keyboard I/O
KBDCR = $D011

; ---------------------------------------------------------------------------------
;   ZP Variables
; ---------------------------------------------------------------------------------

;   WORD contains an 5 letter word and is used as parameter for most word
;   manipulation routines
WORD  = $00     ;   5 ASCII characters, 'A'-'Z' (5 bytes)

;   NUM contains a 4 byte number that is a reprensentation of a word
;   Used by most conversion routintes
NUM   = $05     ;   a 25 bits number (4 bytes)

;   VOCPTR is the current entry in the vocabulary data structure
VOCPTR = $09    ;   Pointer to the vocabulary (2 bytes)

;   ANSPTR is the current entry in the answer data structure
ANSPTR = $0B    ;   Pointer to the answer bitmap (2 bytes)

;   When scanning the Answers, this is the index we are looking for
ANSINX = $0D    ;   Index of answer searched in answers (2 bytes)

;   Contains the 8 bits of the current answer bitmap
ANSCUR = $0F    ;   Workin area, current 8 bits of answer bitmap (1 byte)

;   This is the word that the player must find
TARGET = $10    ;   Target word to find (5 bytes) (5 bytes)

;   Address of a zero-terminated string
;   Used as an argument for MSG related functions
MSG    = $15    ;   Pointer to message to display (2 bytes)

; 0=>non exist, 1=>gray, 2=>yellow, 3=>green
WHITE = 0
GRAY = 1
YELLOW = 2
GREEN = 3

;   The colors of the current guess
;   Set and used in the printing routines of the word
COLORS = $17    ;   Colors of the current guess (5 bytes)

;   Used as an input argument for color detection routines
GUESSIX = $1F       ;   Current guess drawn (1 byte)
GUESSCHARIX = $1D   ;   Current letter index checked from guess (1 byte)

MAXGUESS = 6
;   The current number of guesses done. Games stops at MAXGUESSES
GUESSCOUNT = $1E;   Current number of guesses done (1 byte)

;   Stores the complete history of player input
;   Used to re-draw the screen
HISTORY = $20   ;   30 bytes containing the guess history (30 bytes)

;   Status of every letter in the keyboard (26 bytes)
LETTERS = $3E           ;   The 26 letters and what we know about them (WHITE, GRAY, YELLOW, GREEN)

SCANMASK = $58          ;   The scan mask used when drawing a big letter
TMP = $59
BIGWIDTH = $5A          ;   With of the big string to display (6 for the title, 5 for the target word)
BIGCHAR = $5B           ;   The char used to draw big letters

WAITMO5 = $5C           ;   The counter for displaying the mo5 ad (2 bytes)

SYMBOL_GREEN = "!"
SYMBOL_YELLOW = "?"
SYMBOL_GRAY = " "


; ---------------------------------------------------------------------------------
;   Main code 
; ---------------------------------------------------------------------------------

START:
.(
        ;   ZP variables initialisation
        ;   GUESSCOUNT = 0
    LDA #0
    STA GUESSCOUNT

        ;   LETTERS [0..25] = WHITE
    LDX #26
LOOP1:
    DEX
    STA LETTERS,X
    BNE LOOP1

        ;   Generates a random number
    JSR RNDINIT

        ;   Clear screen
    JSR PAGEFEED

    ; JMP MAIN

        ;   Display rules
    JSR MSGINLINE
    .byte $0d, $0d,
    .byte "Rules: you must guess a 5 letter word", $0d,
    .byte "       you have 6 tries", $0d
    .byte "       type when the cursor is", $0d
    .byte "       in the bottom-left corner", $0d
    .byte "       space to undo entry", $0d,$0d
    .byte "       ! : Letter placed properly", $0d
    .byte "       ? : Letter placed improperly", $0d,$0d, 0

    JSR MSGINLINE
    .byte "       may the woz be with you", $0d, $0d, $0d, $0d, $d, 0

        ;   Display large welcome message
    LDA #<WOZDLE
    STA MSG
    LDA #>WOZDLE
    STA MSG+1
    LDA #6
    STA BIGWIDTH
    LDA #"*"
    STA BIGCHAR
    JSR DRAWBIGTEXT
MAIN:

CONT:
        ; We draw all the guesses
    LDA #0
    STA GUESSIX
LOOP2:
    LDA GUESSCOUNT
    CMP GUESSIX
    BEQ CONTGUESS       ;   Stop at GUESSCOUNT
    JSR DRAWGUESS       ;   Draw guess (automatically includes the keyboard if needed)
    INC GUESSIX
    JMP LOOP2

CONTGUESS:
    JSR GUESSGET        ;   Ask user for a guess
    BNE REFRESH         ;   If we don't know the guess, we need to redraw everything

    LDA GUESSCOUNT      ;   So the draw knows the keyboard is needed
    STA GUESSIX         ;   note that GUESSCOUNT will be inc in update
    JSR UPDATE          ;   Update keyboard colors and stuff
    JSR DRAWGUESS2      ;   Draws the guess, without the guessed word

    ; HERE WE TEST FOR END GAME STATUS
        ;   Check if won (GREEN is 3)
    LDA COLORS
    AND COLORS+1
    AND COLORS+2
    AND COLORS+3
    AND COLORS+4
    CMP #GREEN
    BNE CONT3

        ;   Player won
    JSR WON
    JMP START
CONT3:
        ;   Check if lost
    LDA GUESSCOUNT
    CMP #MAXGUESS
    BNE CONTGUESS       ;   Ask for next guess  

        ;   Player lost
    JSR LOST
    JMP START

REFRESH:
    JSR PAGEFEED        ;   Scroll screen off
    LDA GUESSCOUNT
    BNE MAIN            ;   We don't display a message if there are already guesses
    JSR MSGINLINE
    .byte "ENTER YOUR WORDS:", $d, $d, $0
    JMP MAIN            ;   Redraw game and continue
.)

WON:
.(
    JSR PAGEFEED        ;   Scroll screen off

    JSR MSGINLINE
    .byte "------- CONGRATULATIONS, YOU WON -------", $d, $d, 0


    LDA #<TARGET
    STA MSG
    LDA #>TARGET
    STA MSG+1
    LDA #5
    STA BIGWIDTH
    LDA #"*"
    STA BIGCHAR
    JSR DRAWBIGTEXT

    JMP DRAWSUMMARY
.)

LOST:
.(
    JSR PAGEFEED        ;   Scroll screen off

    JSR MSGINLINE
    .byte "     YOU LOST. THE TARGET WORD WAS:", $d, $d, $d, 0

    LDA #<TARGET
    STA MSG
    LDA #>TARGET
    STA MSG+1
    LDA #5
    STA BIGWIDTH
    LDA #"?"
    STA BIGCHAR
    JSR DRAWBIGTEXT

    JMP DRAWSUMMARY
.)

DRAWSUMMARY:
.(
    JSR MSGINLINE
    .byte $d, "------------- YOUR GUESSES -------------", $d, $d, 0

    JSR MSGINLINE
    .byte "1:",0

    LDA #0
    STA GUESSIX
    JSR DRAWGUESS1
 
    JSR MSGINLINE
    .byte "  2:",0

    INC GUESSIX
    JSR DRAWGUESS1

    JSR MSGINLINE
    .byte "  3:",0

    INC GUESSIX
    JSR DRAWGUESS1

    ; line 2
    JSR MSGINLINE
    .byte "  ",0

    LDA #0
    STA GUESSIX
    JSR DRAWCOL1        ;   Draw colors

    JSR MSGINLINE
    .byte "    ",0

    INC GUESSIX
    JSR DRAWCOL1        ;   Draw colors

    JSR MSGINLINE
    .byte "    ",0

    INC GUESSIX
    JSR DRAWCOL1        ;   Draw colors

    JSR MSGINLINE
    .byte $d,$d,"4:",0

    LDA #3
    STA GUESSIX
    JSR DRAWGUESS1

    JSR MSGINLINE
    .byte "  5:",0

    INC GUESSIX
    JSR DRAWGUESS1

    JSR MSGINLINE
    .byte "  6:",0

    INC GUESSIX
    JSR DRAWGUESS1

    ; line 4
    JSR MSGINLINE
    .byte "  ",0

    LDA #3
    STA GUESSIX
    JSR DRAWCOL1        ;   Draw colors

    JSR MSGINLINE
    .byte "    ",0

    INC GUESSIX
    JSR DRAWCOL1        ;   Draw colors

    JSR MSGINLINE
    .byte "    ",0

    INC GUESSIX
    JMP DRAWCOL1        ;   Draw colors
.)

DRAWGUESS1:
.(
        ;   We skip if over the guess count
    LDA GUESSIX
    CMP GUESSCOUNT
    BMI CONT

    LDA #" "
    LDX #10
    JMP ECHOR

CONT:
    JSR FETCHHISTORY    ;   WORD = HISTORY[GUESSIX]
    JMP PRTWORD
.)

DRAWCOL1:
.(
        ;   We skip if over the guess count
    LDA GUESSIX
    CMP GUESSCOUNT
    BMI CONT

        ;   Could be shared with DRAWGUESS1
    LDA #" "
    LDX #10
    JSR ECHOR
    RTS

CONT:
    JSR FETCHHISTORY    ;   WORD = HISTORY[GUESSIX]
    JSR WRD2COL         ;   Update the color status
    JMP PRTCOLORS       ;   Print colors symbols
.)

    ;   Prints the word, separated by spaces
PRTWORD:
.(
    LDX #0
LOOP2:
    LDA WORD,X
    JSR ECHO
    LDA #" "
    JSR ECHO
    INX
    CPX #5
    BNE LOOP2

    RTS
.)

; ---------------------------------------------------------------------------------
;   Echoes a repeated character
; ---------------------------------------------------------------------------------
ECHOR:
.(
    JSR ECHO
    DEX
    CPX #0
    BNE ECHOR
    RTS
.)


;   Copies the GUESSIX's history word into WORD
FETCHHISTORY:
.(
                         ; Multiply GUESSIX by 5
    LDA GUESSIX
    ASL
    ASL
    ADC GUESSIX

                        ; Copy the guess at HISTORY+A in WORD
    TAX
    LDY #0

LOOP1:
    LDA HISTORY,X
    STA WORD,Y
    INX
    INY
    CPY #5
    BNE LOOP1

    RTS
.)

; ---------------------------------------------------------------------------------
;   Draw a guess line (guess, colors, keyboard)
;   two entry points, one is used if redrawing the game fully
;   second durint play (as the input routine already displayed the word)
; ---------------------------------------------------------------------------------
DRAWGUESS:
    JSR FETCHHISTORY
    JSR PRTWORD

DRAWGUESS2:
    LDA GUESSIX
    CLC
    ADC #1
    CMP GUESSCOUNT
    BNE SKIPKBD

    JSR MSGINLINE
    .byte "______________________________", 0
    JSR WRD2COL         ;   Update the color status
    JSR PRTCOLORS       ;   Print colors symbols

    JMP DRAWKBD

SKIPKBD:
    LDA #$d
    JSR ECHO
    JSR WRD2COL         ;   Update the color status
    JSR PRTCOLORS       ;   Print colors symbols
    JSR MSGINLINE
    .byte $d,$d,$d,0

    RTS


    ;   Draws a keyboard line
    ;   Remove letters if unavailable
    ;   Follows letter by '!' or '?' depending on color
DRAWKBD:
.(
    LDY #$00
LOOP:
    LDA KBDTEXT,Y
    BEQ END

        ;   If not a letter, skip
    CMP #"Z"+1
    BPL NONLETTER
    CMP #"A"
    BMI NONLETTER

        ;   Get the index in the LETTERS state
        ;   Carry is already cleared by the previous failed
    SBC #"A"
    TAX

        ;   State of the letter
    LDA LETTERS,X

    CMP #WHITE      ;   Letter has never been used
    BNE CONT1
    LDA KBDTEXT,Y
    JMP CONT4

CONT1:
    CMP #GRAY       ;   Letter is not in the word
    BNE CONT2
    INY             ;   We duplicate the next character
    LDA KBDTEXT,Y
    JSR ECHO
    JMP CONT4

CONT2:
    CMP #YELLOW     ;   Letter is somewhere
    BNE CONT3
    LDA KBDTEXT,Y     ;   We draw the letter
    JSR ECHO
    INY
    LDA #SYMBOL_YELLOW        ;   Followed by a '?'
    JMP CONT4

CONT3:
                    ;   We know we are green
    LDA KBDTEXT,Y     ;   We draw the letter
    JSR ECHO
    INY
    LDA #SYMBOL_GREEN        ;   Followed by a '!'
    JMP CONT4

NONLETTER:
CONT4:
    JSR ECHO
    INY
    JMP LOOP
END:
    RTS
.)

KBDTEXT:
    .byte "\\Q  W  E  R  T  Y  U  I  O  P "
    .byte "           \\A  S  D  F  G  H  J  K _L__/"
    .byte "            \\Z__X__C__V__B__N__M__/     ", 0

;   Updates the keyboard status, update history and game turn
UPDATE:
.(
    JSR WRD2COL         ;   Get current color status

            ;   Update the LETTERS array with the new COLORS if needed
    LDX #0
LOOP:
    LDA WORD,X
    SEC                 ;   Beware SBC works the opposite way of what you may think
    SBC #"A"
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


; Update color state according to current word
WRD2COL:
.(
        ;   Compare WORD and TARGET according to Wozdle rules

        ;   Fills the COLORS array with the correct color rules

        ;   Everything by default
    JSR SETALLGRAY

        ;   Find the greens and exclude them
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

        ;   Find the yellows and exclude them
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

        ; SETYELLOW and SETGREEN has excluded chars by ORing them with $80
    JMP UNEXCLUDE

        ;   Init word colors to all gray
    SETALLGRAY:
    .(
        LDA #GRAY
        STA COLORS
        STA COLORS+1
        STA COLORS+2
        STA COLORS+3
        STA COLORS+4
        RTS
    .)

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
    .(
        LDA #$80
        ORA TARGET,Y
        STA TARGET,Y
        RTS
    .)

        ;   Clear all exclusion flags
    UNEXCLUDE:
    .(
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
    .)
.)



WOZDLE:
.byte "WOZDLE"

    ;   Print all colors for the current word
PRTCOLORS:
.(
    LDY #0
LOOP:
    LDA COLORS,Y
    CMP #GREEN
    BNE CONT1
    LDA #SYMBOL_GREEN
    JMP CONT3
CONT1:
    CMP #YELLOW
    BNE CONT2
    LDA #SYMBOL_YELLOW
    JMP CONT3
CONT2:
    LDA #SYMBOL_GRAY
CONT3:
    JSR ECHO
    LDA #" "
    JSR ECHO
    INY
    CPY #05
    BNE LOOP
    RTS
.)


; Seek answer of index ANSWINX
; Stored in NUM
ANSSEEK:
.(
    JSR NUMCLR

    LDA #<ANSWERS
    STA ANSPTR
    LDA #>ANSWERS
    STA ANSPTR+1

NEXTBYTE:
    JSR ANSNEXT     ;   Loads 8 bits of answers
    STA ANSCUR

    LDX #8
NEXTBIT:
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
    BNE NEXTBIT

    JMP NEXTBYTE

DONE:
    RTS

        ; Loads A with the next 8 bitmap of answers and increment answer ptr
        ;   (We could win a byte as X is always zero, and LDA (ANSPTR,X) would be LDA (ANSPTR),Y)
    ANSNEXT:
    .(
        LDY #0
        LDA (ANSPTR),Y
        INC ANSPTR
        BNE CONT
        INC ANSPTR+1
    CONT:
        RTS
    .)
.)

; ---------------------------------------------------------------------------------
;   Generates a random TARGET word
; ---------------------------------------------------------------------------------
RNDINIT:
.(
        ;   Display user message
    JSR MSGINLINE
    .byte $d, $d, "     -- press space for new game -- ", 0

        ;   Eats any key already pressed
    LDA KBD           
    LDA #0
    STA WAITMO5
    STA WAITMO5+1

        ;   Wait for space while incrementing random
LOOP1:
                        ;   Increment ANSINX to create entrpy
                        ;   based on player speed
    INC ANSINX
    BNE CONT
    INC ANSINX+1
    INC WAITMO5
    BNE CONT
    INC WAITMO5+1
    LDA WAITMO5+1
    AND #$0F
    BNE CONT
    JSR MO5
    JMP RNDINIT
CONT:
    LDA KBDCR           ;   Key pressed?
    BPL LOOP1           ;   No
    LDA KBD             ;   Key pressed
    AND #$7f            ;   Last 6 bits
    CMP #"A"
    BEQ HACK_APPLE
    CMP #"S"
    BEQ HACK_STARK
    CMP #" "            ;   Space?
    BNE LOOP1           ;   Nope

        ; Get the number mod ANSCOUNT (2309)
        ; By adding ANSCOUNT until we have a carry
MODULO:
    CLC
MODULOOP:
    LDA ANSINX
    ADC #<ANSCOUNT
    STA ANSINX
    LDA ANSINX+1
    ADC #>ANSCOUNT
    STA ANSINX+1
    BCC MODULOOP

SEEK:
        ;   Here ANSINX is a random number between 0 and ANSCOUNT-1
    JSR ANSSEEK         ;   We load the corresponding vocabulatory enrty
                        ;   (note the time to load gives the player an indication of the place of the word)

    JSR N2W             ;   Gets it in ASCII form into TARGET
    LDA WORD
    STA TARGET
    LDA WORD+1
    STA TARGET+1
    LDA WORD+2
    STA TARGET+2
    LDA WORD+3
    STA TARGET+3
    LDA WORD+4
    STA TARGET+4

    LDA #$d
    JMP ECHO

HACK_APPLE:
    ; Hack for apple
    LDA #96
    STA ANSINX
    LDA #00
    STA ANSINX+1
    JMP SEEK

HACK_STARK:
    ; Hack for stark
    LDA #<1904
    STA ANSINX
    LDA #>1904
    STA ANSINX+1
    JMP SEEK
.)

; ---------------------------------------------------------------------------------
;   Reads a vocabulary word into WORD
; ---------------------------------------------------------------------------------
GUESSGET:
.(
        ; Get 5 chars with echo
    LDX #0
LOOPX:
    JSR KBDGET
    CMP #" "
    BEQ EXIT
    CMP #"A"
    BMI LOOPX
    CMP #"Z"+1
    BPL LOOPX
CONT:
    STA WORD,X
    JSR ECHO
    LDA #" "
    JSR ECHO
    INX
    CPX #5
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

    ORA NUM+2           ;   Check if NUM-NUM+3 is zero
    ORA NUM+1
    ORA NUM

    RTS                 ;   Z = 1 if valid guess
EXIT:
    LDA #1              ; Make sure Z != 1
    RTS
.)

; ---------------------------------------------------------------------------------
;   Print inline message
; ---------------------------------------------------------------------------------
MSGINLINE:
.(
        ;   Recover the PC from the stack
    PLA
    STA MSG
    PLA
    STA MSG+1
        ;   Add 1 to PC
    INC MSG
BNE CONT1
    INC MSG+1

        ;   MSG contains the message
CONT1:
    JSR MSGOUT
    CLC
    TYA
    ADC MSG
    STA MSG
    BCC CONT2
    INC MSG+1
CONT2:
    LDA MSG+1
    PHA
    LDA MSG
    PHA
    RTS
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
        INC MSG
        BNE LOOP
        INC MSG+1
        JMP LOOP
    END:
        RTS
    .)
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
.(
    LDA KBDCR
    BPL KBDGET
    LDA KBD
    AND #$7F
    ; JSR PRBYTE
    RTS
.)

; ---------------------------------------------------------------------------------
;   Num management support routines
; ---------------------------------------------------------------------------------

NUMCLR:         ;   Sets 'aaaaa' as the current numerical word
.(
    LDA #$00
    STA NUM
    STA NUM+1
    STA NUM+2
    STA NUM+3
    JMP NUMADJUST
.)

NUMADJUST:      ;   Adjusts num by adding 'aaaaa'
.(
    CLC
    LDA #$21
    ADC NUM
    STA NUM
    LDA #$84
    ADC NUM+1
    STA NUM+1
    LDA #$10
    ADC NUM+2
    STA NUM+2
    LDA #$00
    ADC NUM+3
    STA NUM+3

    LDA #<VOCABULARY
    STA VOCPTR
    LDA #>VOCABULARY
    STA VOCPTR+1

    RTS
.)

NEXTVOCPTR:
.(
    LDY #$00
    LDA (VOCPTR),Y
    ROL
    BCC NEXTVOCPTR1
    ROL
    BCC NEXTVOCPTR2

    .(
            ;   Adds 3 bytes (16384-)
        LDY #$02
        LDA (VOCPTR),Y
        CLC
        ADC NUM
        STA NUM

        DEY
        LDA (VOCPTR),Y
        ADC NUM+1
        STA NUM+1

        DEY
        LDA (VOCPTR),Y
        AND #$3f
        ADC NUM+2
        STA NUM+2

        BCC DONE
        INC NUM+3

    DONE:
        CLC
        LDA #$03
        ADC VOCPTR
        STA VOCPTR

        BCC DONE2
        INC VOCPTR+1

    DONE2:
        RTS
    .)

    ;   Note: preserves X
    NEXTVOCPTR1:
    .(
            ;   Adds 1 bytes (128-16383)
        LDA (VOCPTR),Y
        AND #$7f
        CLC
        ADC NUM
        STA NUM

        BCC DONE
        INC NUM+1
        BNE DONE
        INC NUM+2
        BNE DONE
        INC NUM+3
    DONE:
        INC VOCPTR
        BNE DONE2
        INC VOCPTR+1
    DONE2:
        RTS
    .)

    NEXTVOCPTR2:
    .(
            ;   Adds 2 bytes (128-16383), big endian
        LDY #$01
        LDA (VOCPTR),Y
        CLC
        ADC NUM
        STA NUM

        DEY
        LDA (VOCPTR),Y
        AND #$3f
        ADC NUM+1
        STA NUM+1

        BCC DONE
        INC NUM+2
        BNE DONE
        INC NUM+3

    DONE:
        CLC
        LDA #$02
        ADC VOCPTR
        STA VOCPTR
        BCC DONE2
        INC VOCPTR+1
    DONE2:
        RTS
    .)
.)

; ---------------------------------------------------------------------------------
;   Words to numbers back and forth mapping
; ---------------------------------------------------------------------------------

; Mapping from a 5 character word into a 4 bytes number
; a transcodes to a 1
; abcde => dddeeeee bcccccdd aaaabbbb 0000000a   
;            NUM     NUM+1     NUM+2     NUM+3
; "APPLE" => 41 50 50 4C 45
;         => 0000 0001  0001 0000  0001 0000  0000 1100  0000 0101
;         =>     00001      10000      10000      01100      00101
;         => .......0 00011000 01000001 10000101
;         => 10000101 01000001 00011000 00000000 
; "apple" => 85 41 18 00   


N2W:
    LDA #$40
    STA WORD+4
    STA WORD+3
    STA WORD+2
    STA WORD+1
    STA WORD

        ; NUM
    LDA NUM
    TAX
    AND #$1F
    ORA WORD+4
    STA WORD+4

    TXA
    ; No AND, as all bits goes right
    LSR
    LSR
    LSR
    LSR
    LSR
    ORA WORD+3
    STA WORD+3

        ; NUM+1
    LDA NUM+1
    TAX
    AND #$03
    ASL
    ASL
    ASL
    ORA WORD+3
    STA WORD+3
    
    TXA
    AND #$7c
    LSR
    LSR
    ORA WORD+2
    STA WORD+2
    
    TXA
    AND #$80
    LSR
    LSR
    LSR
    LSR
    LSR
    LSR
    LSR ; (Should be CLC + 2 ROL)
    ORA WORD+1
    STA WORD+1

        ; NUM+2
    LDA NUM+2
    TAX
    AND #$0f
    ASL
    ORA WORD+1
    STA WORD+1

    TXA
    AND #$f0
    LSR
    LSR
    LSR
    LSR
    ORA WORD
    STA WORD

        ; NUM+3
    LDA NUM+3
    ASL
    ASL
    ASL
    ASL
    ORA WORD
    STA WORD

    RTS

;   Creates the number for the word (WORD => NUM)
W2N:
        ;   4th letter
    LDA WORD+4
    EOR #$40    ;   Letter index
    STA NUM

        ;   3rd letter
    LDA WORD+3
    EOR #$40    ;   Letter index
    TAX
    ASL
    ASL
    ASL
    ASL
    ASL
    ORA NUM
    STA NUM
    TXA
    LSR
    LSR
    LSR
    STA NUM+1

        ; 2nd letter
    LDA WORD+2
    EOR #$40    ;   Letter index
    ASL
    ASL
    ORA NUM+1
    STA NUM+1

        ; 1st letter
    LDA WORD+1
    EOR #$40    ;   Letter index
    TAX
    ROR         ;   Could do better if NUM+1 was already shifted one bit
    ROR
    AND #$80
    ORA NUM+1
    STA NUM+1
    TXA
    LSR
    STA NUM+2

        ;  0th letter
    LDA WORD
    EOR #$40    ;   Letter index
    CLC
    ROL
    ROL
    ROL
    ROL
    TAX
    LDA #$00
    ADC #$00
    STA NUM+3
    TXA
    ORA NUM+2
    STA NUM+2
    RTS

; ---------------------------------------------------------------------------------
;   Test routines
; ---------------------------------------------------------------------------------

    ;   Tests words-num conversions
TEST:
.(
    LDA #$0d
    JSR ECHO
    JSR ECHO

    LDX #$00
    LDY #$00
LOOP0:
    LDA TESTDATA,Y
    CMP #$00
    BEQ DONE
    STA WORD,X
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
    CMP NUM,X
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

ECHOPASSED:
    LDX #$00
LOOP2:
    LDA MSGPASSED,X
    JSR ECHO
    INX
    CMP #$00
    BNE LOOP2
    RTS
.)

HALT:
    JMP HALT

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
    LDA WORD
    JSR ECHO
    LDA WORD+1
    JSR ECHO
    LDA WORD+2
    JSR ECHO
    LDA WORD+3
    JSR ECHO
    LDA WORD+4
    JSR ECHO
    LDA #$20
    JSR ECHO
    RTS

#include "obj/data.asm"

XXX:
    LDA #$d
    JSR ECHO
    JSR ECHO
    JSR ECHO
    LDA #<T
    STA MSG
    LDA #>T
    STA MSG+1
    JSR DRAWBIGTEXT
    RTS

T:
    .byte "UVWXY"

;   Draw a text in big font
DRAWBIGTEXT:
.(
    LDA #$01
    STA SCANMASK
LOOP:
    JSR DRAWBIGTEXTLINE
    LDA #$d
    JSR ECHO
    ASL SCANMASK
    BNE LOOP
    RTS
.)

DRAWBIGTEXTLINE:
.(
        ;   Starts with some space to center
    LDA #40
    SEC
    SBC BIGWIDTH
    SBC BIGWIDTH
    SBC BIGWIDTH
    SBC BIGWIDTH
    SBC BIGWIDTH
    SBC BIGWIDTH
    LSR                 ;   Space = (WIDTH-6*BIGWIDTH)/2
                        ;   #### Stoopid, do WIDTH/2-3*BIGWIDTH
    TAX
    LDA #" "
LOOP2:
    JSR ECHO
    DEX
    BNE LOOP2

        ;   Now display one line of characters
    LDY #0
LOOP:
    LDA (MSG),Y         ;   Character to display

        ;   Compute the index in CHARROM (ACC-'A')*5

    SEC
    SBC #"A"
    ASL
    ASL
    ADC (MSG),Y
    SEC
    SBC #"A"
    TAX                 ;   Index in CHARROM for this char 

    TYA
    PHA
    LDY #5              ;   5 columns per character
LOOP3:
    LDA CHARROM,X
    AND SCANMASK
    BEQ SPACE:
    LDA BIGCHAR
    JMP PRINT
SPACE:
    LDA #" "
PRINT:
    JSR ECHO
    INX
    DEY
    BNE LOOP3           ;   Next column
    LDA #" "
    JSR ECHO
    PLA
    TAY
    INY                 ;   Next char
    CPY BIGWIDTH        ;   End of line
    BNE LOOP
    RTS
.)

CHARROM:
        ;   A
    .byte %01111100
    .byte %00010010
    .byte %00010001
    .byte %00010010
    .byte %01111100
        ;   B
    .byte %01111111
    .byte %01001001
    .byte %01001001
    .byte %01001001
    .byte %00110110
        ;   C
    .byte %00111110
    .byte %01000001
    .byte %01000001
    .byte %01000001
    .byte %00100010
        ;   D
    .byte %01111111
    .byte %01000001
    .byte %01000001
    .byte %01000001
    .byte %00111110
        ;   E
    .byte %01111111
    .byte %01001001
    .byte %01001001
    .byte %01001001
    .byte %01000001
        ;   F
    .byte %01111111
    .byte %00001001
    .byte %00001001
    .byte %00001001
    .byte %00000001
        ;   G
    .byte %00111110
    .byte %01000001
    .byte %01000001
    .byte %01010001
    .byte %01110010
        ;   H
    .byte %01111111
    .byte %00001000
    .byte %00001000
    .byte %00001000
    .byte %01111111
        ;   I
    .byte %00000000
    .byte %01000001
    .byte %01111111
    .byte %01000001
    .byte %00000000
        ;   J
    .byte %00100000
    .byte %01000000
    .byte %01000000
    .byte %01000000
    .byte %00111111
        ;   K
    .byte %01111111
    .byte %00001000
    .byte %00010100
    .byte %00100010
    .byte %01000001
        ;   L
    .byte %01111111
    .byte %01000000
    .byte %01000000
    .byte %01000000
    .byte %01000000
        ;   M
    .byte %01111111
    .byte %00000010
    .byte %00001100
    .byte %00000010
    .byte %01111111
        ;   N
    .byte %01111111
    .byte %00000100
    .byte %00001000
    .byte %00010000
    .byte %01111111
        ;   O
    .byte %00111110
    .byte %01000001
    .byte %01000001
    .byte %01000001
    .byte %00111110
        ;   P
    .byte %01111111
    .byte %00001001
    .byte %00001001
    .byte %00001001
    .byte %00000110
        ;   Q
    .byte %00111110
    .byte %01000001
    .byte %01010001
    .byte %00100001
    .byte %01011110
        ;   R
    .byte %01111111
    .byte %00001001
    .byte %00011001
    .byte %00101001
    .byte %01000110
        ;   S
    .byte %00100110
    .byte %01001001
    .byte %01001001
    .byte %01001001
    .byte %00110010
        ;   T
    .byte %00000001
    .byte %00000001
    .byte %01111111
    .byte %00000001
    .byte %00000001
        ;   U
    .byte %00111111
    .byte %01000000
    .byte %01000000
    .byte %01000000
    .byte %00111111
        ;   v
    .byte %00011111
    .byte %00100000
    .byte %01000000
    .byte %00100000
    .byte %00011111
        ;   W
    .byte %00111111
    .byte %01000000
    .byte %00110000
    .byte %01000000
    .byte %00111111
        ;   X
    .byte %01100011
    .byte %00010100
    .byte %00001000
    .byte %00010100
    .byte %01100011
        ;   Y
    .byte %00000011
    .byte %00000100
    .byte %01111000
    .byte %00000100
    .byte %00000011
        ;   W
    .byte %01100011
    .byte %01010001
    .byte %01001001
    .byte %01000101
    .byte %01100011

MO5:
.(
    JSR PAGEFEED
    JSR MSGINLINE

.byte "@@@@@@@@@@@@@@@@&^^-;,;^^&#@@@@@@@@@@@@@@@"
.byte "@@@@@@@@@@@@#**+     ..:;^*@@@@@@@@@@@@@"
.byte "@@@@@@@@@@&-:..       ... .+@@@@@@@@@@@@"
.byte "@@@@@@@@%!     ..       ....+%@@@@@@@@@@"
.byte "@@@@@@@#;                  . :^#@@@@@@@@"
.byte "@@@@@@@=              .:;;:    =@@@@@@@@"
.byte "@@@@@@@;     ,,.  ..  :!+=-:   :=@@@@@@@"
.byte "@@@@@@*.    :=?^!!--;;;^??=^,   .&@@@@@@"
.byte "@@@@@@+     ,??=+++=+^^++^^+^:   +@@@@@@"
.byte "@@@@@@?     !=^;,::,-^-,..:;^!  ,%@@@@@@"
.byte "@@@@@@*    :++!,.   :++: .:;^+: ?@@@@@@@"
.byte "@@@@@@%:   ;?=+^!!!!-&%+--^+?&!.*@@@@@@@"
.byte "@@@@@@@+ ,:,=====+^^=&**?^^=??^:+@@@@@@@"
.byte "@@@@@@@#:,,.!-!!!;;!!!-^-;,;!-!.+@@@@@@@"
.byte "@@@@@@@@^   :;;,..,,. ..::..,;:,%@@@@@@@"
.byte "@@@@@@@@%-. ..::.::,;;!!;,,....?@@@@@@@@"
.byte "@@@@@@@@@%-!  ...,;;!-^^^^,. :=@@@@@@@@@"
.byte "@@@@@@@@%?*=,.  ..,;;,,,;;..,?@@@@@@@@@@"
.byte "@@@@##%*&%#&-,.....:....:..:+?%@@@@@@@@@"
.byte "@#%***%%####?;::.  .......,!^**%#@@@@@@@"
.byte "%%%%##%%##%##=,,:::...::,!-;^##%%%##@@@@"
.byte "##%%%%%%%##%##?;,,,,;,;!-^!;+%####%%####"
.byte "%%%%%%%%%####*?+!;,,,,!--!,-?###%%%%%%%%"
.byte "                  WOZ",0

.byte "            ___   ____________",$d
.byte "           / _ ! / __/ __/ __ \\",$d
.byte "          / __ !_\\ \\_\\ \\/ /_/ /",$d
.byte "   __  __/_/_!_/___/___/\\____/_  __  ___"
.byte "  /  !/  / __ \\/ __/ / ___/ __ \\/  !/  /"
.byte " / /!_/ / /_/ /__ \\_/ /__/ /_/ / /!_/ /",$d
.byte "/_/  /_/\\____/____(_)___/\\____/_/  /_/",$d
.byte " ________________",$d
.byte "!                !",$d
.byte "!                !            !",$d
.byte "!       __       !            !",$d
.byte "!      /  \\      !             \\__     ",$d
.byte "!      \\__/      !   REJOUER      \\",$d
.byte "!    ______      !            ____!____",$d
.byte "!   !    X !     !     !     !  _   _  !"
.byte "!   !    X !     !     !     ! ! ! ! ! !"
.byte "!___!____X_!_____/     !     ! !_! !_! !"
.byte "                   ___/      !         !"
.byte "    PRESERVER     /          !         !"
.byte "        _________!_________  !         !"
.byte "       !   !               ! !_________!"
.byte "       ! --+--      _   _  !",$d
.byte "       !   !   - - (_) (_) !  EXPLORER",$d
.byte "       !___________________!           ",$0


LOOP:
    LDA KBDCR           ;   Key pressed?
    BPL LOOP            ;   No

    JSR PAGEFEED

    RTS
.)


