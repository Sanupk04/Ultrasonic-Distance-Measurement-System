; ---------------- 8051 ASM: Ultrasonic + LCD ----------------
    ORG 0H
    LJMP MAIN

; ---------------- DATA ----------------
    ORG 30H
RANGE:      DS 2        ; 16-bit range
TIME:       DS 2
TMP:        DS 2

MSG1:       DB "Distance: ",0
MSG2:       DB " cm      ",0
MSG_ERR:    DB "Check Sensor...",0

; ---------------- I/O BIT DEFINITIONS ----------------
RS      BIT P0.0
RW      BIT P0.1
EN      BIT P0.2

TRIG    BIT P3.5
ECHO    BIT P3.2

LCD_DATA EQU P2

; ---------------- DELAYS ----------------
LCD_DELAY:
    MOV     R0, #0
DELAY1:
    MOV     R1, #0
DELAY2:
    DJNZ    R1, DELAY2
    DJNZ    R0, DELAY1
    RET

NOP10:
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    RET

; ---------------- LCD COMMAND ----------------
LCD_CMD:
    ; Input: A = command
    MOV     LCD_DATA, A
    CLR     RS
    CLR     RW
    SETB    EN
    ACALL   LCD_DELAY
    CLR     EN
    RET

; ---------------- LCD DATA ----------------
LCD_DAT:
    ; Input: A = data
    MOV     LCD_DATA, A
    SETB    RS
    CLR     RW
    SETB    EN
    ACALL   LCD_DELAY
    CLR     EN
    RET

; ---------------- LCD INIT ----------------
LCD_INIT:
    MOV     A, #38H
    ACALL   LCD_CMD
    MOV     A, #0CH
    ACALL   LCD_CMD
    MOV     A, #06H
    ACALL   LCD_CMD
    MOV     A, #01H
    ACALL   LCD_CMD
    ACALL   LCD_DELAY
    RET

; ---------------- LCD SHOW STRING ----------------
SHOW_STR:
    ; Input: DPTR points to string
SHOW_LOOP:
    CLR     A
    MOVC    A, @A+DPTR
    JZ      SHOW_DONE
    ACALL   LCD_DAT
    INC     DPTR
    SJMP    SHOW_LOOP
SHOW_DONE:
    RET

; ---------------- SEND PULSE ----------------
SEND_PULSE:
    SETB    TRIG
    ACALL   NOP10
    CLR     TRIG
    RET

; ---------------- ULTRASONIC READ ----------------
ULTRASONIC:
    CLR     C               ; Clear carry
    ACALL   SEND_PULSE
    ; Wait for ECHO = 1 with timeout
    MOV     R2, #255
WAIT_HIGH:
    JNB     ECHO, DEC_TIMEOUT
    SJMP    START_TIMER

DEC_TIMEOUT:
    DJNZ    R2, WAIT_HIGH
    MOV     DPTR, #RANGE
    MOV     A, #0
    MOVX    @DPTR, A
    MOVX    @DPTR+1, A
    RET

START_TIMER:
    CLR     TR0             ; Ensure Timer0 stopped
    MOV     TH0, #0
    MOV     TL0, #0
    SETB    TR0

WAIT_LOW:
    JB      ECHO, WAIT_LOW
    CLR     TR0

    ; Save timer value
    MOV     A, TH0
    MOV     DPTR, #TIME
    MOVX    @DPTR, A
    MOV     A, TL0
    MOVX    @DPTR+1, A

    ; Calculate distance (rough approximation)
    MOV     DPTR, #TIME
    MOVX    A, @DPTR        ; High byte
    MOV     B, A
    MOVX    A, @DPTR+1      ; Low byte
    MOV     R0, A
    ; Approx: distance = time/58 (integer)
    MOV     A, R0
    MOV     R1, #58
    DIV     AB
    MOV     DPTR, #RANGE
    MOVX    @DPTR, A
    RET

; ---------------- MAIN ----------------
    ORG 100H
MAIN:
    ; Timer0 Mode1
    MOV     TMOD, #01H
    ; Initialize LCD
    ACALL   LCD_INIT

MAIN_LOOP:
    ; Line 1
    MOV     A, #80H
    ACALL   LCD_CMD
    MOV     DPTR, #MSG1
    ACALL   SHOW_STR

    ; Read Ultrasonic
    ACALL   ULTRASONIC
    MOV     DPTR, #RANGE
    MOVX    A, @DPTR
    CJNE    A, #0, SHOW_DIST
    ; Show error
    MOV     DPTR, #MSG_ERR
    ACALL   SHOW_STR
    SJMP    LOOP_DELAY

SHOW_DIST:
    ; Move to line 2
    MOV     A, #0C0H
    ACALL   LCD_CMD

    ; Convert hundreds, tens, units
    MOV     B, #100
    DIV     AB              ; A=hundreds, B=remainder
    ADD     A, #30H
    ACALL   LCD_DAT

    MOV     A, B
    MOV     B, #10
    DIV     AB              ; A=tens, B=units
    ADD     A, #30H
    ACALL   LCD_DAT

    MOV     A, B
    ADD     A, #30H
    ACALL   LCD_DAT

    MOV     DPTR, #MSG2
    ACALL   SHOW_STR

LOOP_DELAY:
    ACALL   LCD_DELAY
    SJMP    MAIN_LOOP

    END
