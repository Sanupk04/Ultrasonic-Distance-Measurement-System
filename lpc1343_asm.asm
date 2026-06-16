AREA    ULTRASONIC_LCD, CODE, READONLY
    THUMB
    EXPORT  __main

/* ---------------- GPIO Addresses ---------------- */
GPIO1_DIR   EQU 0x50018000
GPIO1_DATA  EQU 0x500103FC

GPIO2_DIR   EQU 0x50028000
GPIO2_DATA  EQU 0x500203FC

GPIO3_DIR   EQU 0x50030000
GPIO3_DATA  EQU 0x500303FC

/* ---------------- LCD Control Pins ---------------- */
RS  EQU 1<<0
RW  EQU 1<<1
EN  EQU 1<<2

/* ---------------- Ultrasonic Pins ---------------- */
TRIG    EQU 1<<0
ECHO    EQU 1<<1

/* ---------------- Variables ---------------- */
    AREA    ULTRASONIC_LCD_DATA, DATA, READWRITE
range   DCD 0
i       DCD 0

/* ---------------- MICROSECOND DELAY ---------------- */
lcd_delay
    PUSH    {R0,R1}
    LDR     R0, =1000
delay_loop1
    SUBS    R0, R0, #1
    BNE     delay_loop1
    POP     {R0,R1}
    BX      LR

delay_us
    PUSH    {R0,R1}
    LDR     R0, [SP,#8]     ; us parameter
    MOV     R1, #10
    MUL     R0, R0, R1      ; rough us*10 loops
delay_us_loop
    SUBS    R0, R0, #1
    BNE     delay_us_loop
    POP     {R0,R1}
    BX      LR

/* ---------------- LCD COMMAND ---------------- */
lcd_cmd
    PUSH    {R0,R1,R2}
    LDR     R0, [SP,#12]        ; cmd_val
    LDR     R1, =GPIO1_DATA
    STRB    R0, [R1]            ; put data on D0-D7
    LDR     R2, =GPIO2_DATA
    LDR     R1, [R2]
    BIC     R1, R1, #(RS|RW)   ; RS=0, RW=0
    STR     R1, [R2]
    ORR     R1, R1, #EN         ; EN=1 pulse
    STR     R1, [R2]
    BL      lcd_delay
    BIC     R1, R1, #EN
    STR     R1, [R2]
    POP     {R0,R1,R2}
    BX      LR

/* ---------------- LCD DATA ---------------- */
lcd_data
    PUSH    {R0,R1,R2}
    LDR     R0, [SP,#12]        ; data_val
    LDR     R1, =GPIO1_DATA
    STRB    R0, [R1]
    LDR     R2, =GPIO2_DATA
    LDR     R1, [R2]
    ORR     R1, R1, #RS         ; RS=1
    BIC     R1, R1, #RW         ; RW=0
    ORR     R1, R1, #EN         ; EN=1
    STR     R1, [R2]
    BL      lcd_delay
    BIC     R1, R1, #EN
    STR     R1, [R2]
    POP     {R0,R1,R2}
    BX      LR

/* ---------------- LCD INIT ---------------- */
lcd_init
    PUSH    {LR}
    LDR     R0, =0x38
    BL      lcd_cmd
    LDR     R0, =0x0E
    BL      lcd_cmd
    LDR     R0, =0x06
    BL      lcd_cmd
    LDR     R0, =0x0C
    BL      lcd_cmd
    LDR     R0, =0x80
    BL      lcd_cmd
    POP     {LR}
    BX      LR

/* ---------------- LCD SHOW STRING ---------------- */
lcd_show
    PUSH    {R0,R1,LR}
show_loop
    LDRB    R0, [R0], #1        ; load char, increment pointer
    CMP     R0, #0
    BEQ     show_done
    BL      lcd_data
    B       show_loop
show_done
    POP     {R0,R1,LR}
    BX      LR

/* ---------------- ULTRASONIC INIT ---------------- */
ultrasonic_init
    PUSH    {R0,R1,LR}
    LDR     R0, =GPIO3_DIR
    LDR     R1, [R0]
    ORR     R1, R1, #TRIG       ; TRIG output
    BIC     R1, R1, #ECHO       ; ECHO input
    STR     R1, [R0]
    POP     {R0,R1,LR}
    BX      LR

/* ---------------- SEND PULSE ---------------- */
send_pulse
    PUSH    {R0,R1,LR}
    LDR     R0, =GPIO3_DATA
    LDR     R1, [R0]
    ORR     R1, R1, #TRIG
    STR     R1, [R0]
    MOV     R0, #10
    BL      delay_us
    LDR     R1, [R0]
    BIC     R1, R1, #TRIG
    STR     R1, [R0]
    POP     {R0,R1,LR}
    BX      LR

/* ---------------- GET RANGE ---------------- */
get_range
    PUSH    {R0,R1,R2,LR}
    MOV     R0, #0
    BL      send_pulse

wait_high
    LDR     R1, =GPIO3_DATA
    LDR     R2, [R1]
    TST     R2, #ECHO
    BEQ     wait_high

count_loop
    LDR     R2, =GPIO3_DATA
    LDR     R2, [R2]
    TST     R2, #ECHO
    BEQ     count_done
    ADD     R0, R0, #1
    MOV     R1, #1
    BL      delay_us
    B       count_loop

count_done
    MOV     R1, #58
    SDIV    R0, R0, R1          ; range = count / 58
    POP     {R0,R1,R2,LR}
    BX      LR

/* ---------------- MAIN ---------------- */
__main
    ; SystemInit called externally
    ; GPIO1 = LCD DATA
    LDR     R0, =GPIO1_DIR
    MOV     R1, #0xFF
    STR     R1, [R0]
    ; GPIO2 = LCD CONTROL
    LDR     R0, =GPIO2_DIR
    LDR     R1, [R0]
    ORR     R1, R1, #(RS|RW|EN)
    STR     R1, [R0]

    BL      ultrasonic_init
    BL      lcd_init
    LDR     R0, =msg_distance
    BL      lcd_show

main_loop
    BL      get_range
    ; convert to hundreds, tens, ones
    MOV     R1, R0
    MOV     R2, #100
    UDIV    R3, R1, R2
    ADD     R3, R3, #'0'
    BL      lcd_data

    MOV     R1, R0
    MOV     R2, #10
    UDIV    R3, R1, R2
    MOV     R4, R3
    MUL     R4, R4, #10
    SUB     R3, R3, R4
    ADD     R3, R3, #'0'
    BL      lcd_data

    MOV     R3, R0
    UDIV    R4, R3, #10
    MUL     R4, R4, #10
    SUB     R3, R3, R4
    ADD     R3, R3, #'0'
    BL      lcd_data

    LDR     R0, =msg_cm
    BL      lcd_show

    ; small delay
    LDR     R0, =50000
delay_main_loop
    SUBS    R0, R0, #1
    BNE     delay_main_loop

    B       main_loop

/* ---------------- DATA STRINGS ---------------- */
    AREA    ULTRASONIC_LCD_CONST, DATA, READONLY
msg_distance
    DCB     "Distance:",0
msg_cm
    DCB     "cm",0

    END
