;===============================================================================
; SEAWOLF / MISSILE - Bally/Astrocade Videocade #2002
; Programmed by Rick Spiece
;
; Version 0.003 - September 14, 2026
;   - Added semantic labels for routines, RAM, tables, and graphics.
;   - Identified the vector-object pool and overlapping instruction entries.
;   - Retains byte-for-byte identity with the original 2 KB cartridge ROM.
;
; Version 0.002 - December 7, 2011 - Adam Trionfo public disassembly
; Version 0.001 - July 29, 2011 - Adam Trionfo initial disassembly
;
; Assemble with zmac 1.3:
;   zmac -i -m -o seawolf.bin -x seawolf.lst Seawolf.asm
;===============================================================================

        INCLUDE "HVGLIB.H"

;-------------------------------------------------------------------------------
; Game RAM
;-------------------------------------------------------------------------------

PLAYER_PATTERN_PTR          EQU $4EBF   ; Pattern used for the player sprites
SOUND_COUNTDOWN             EQU $4EC1
GAME_FLAGS                  EQU $4EC2   ; Bit 6 selects Missile; bit 7 guards UPI
INTERRUPT_PHASE             EQU $4EC3
SPAWN_PHASE                 EQU $4EC4
EVEN_OBJECT_CURSOR          EQU $4EC5
ODD_OBJECT_CURSOR           EQU $4EC7
PLAYER1_SCORE               EQU $4EC9   ; Two-byte packed BCD
PLAYER2_SCORE               EQU $4ECB   ; Two-byte packed BCD
PLAYER2_AIM_X               EQU $4ECD
PLAYER2_SHOT_INDEX          EQU $4ECE
PLAYER_SHOT_FLAGS           EQU $4ECF
PLAYER1_SHOT_INDEX          EQU $4ED0
PLAYER1_AIM_X               EQU $4ED1
PLAYER1_OLD_SCREEN_ADDR     EQU $4ED2
PLAYER2_OLD_SCREEN_ADDR     EQU $4ED4
PLAYER1_LOAD_TIMER          EQU $4ED6
PLAYER2_LOAD_TIMER          EQU $4ED7
PLAYER1_RELOAD_TICK         EQU $4ED8
PLAYER2_RELOAD_TICK         EQU $4ED9

; Vector-block allocation. Offsets VBMR through VBOAH are defined in HVGLIB.H.
; Blocks 0-3 form two spawn pairs, 4-11 are interleaved projectile slots, and
; blocks 12-15 are the target/aircraft collision pool.
VECTOR_POOL                 EQU $4EDA
SPAWN_BLOCK_A0              EQU $4EDA
SPAWN_BLOCK_A1              EQU $4EE9
SPAWN_BLOCK_B0              EQU $4EF8
SPAWN_BLOCK_B1              EQU $4F07
GAME_PARAMETER_BUFFER       EQU SPAWN_BLOCK_B1 ; Reused before the pool starts
PLAYER1_PROJECTILE_0        EQU $4F16
PLAYER2_PROJECTILE_0        EQU $4F25
PLAYER1_PROJECTILE_1        EQU $4F34
PLAYER2_PROJECTILE_1        EQU $4F43
PLAYER1_PROJECTILE_2        EQU $4F52
PLAYER2_PROJECTILE_2        EQU $4F61
PLAYER1_PROJECTILE_3        EQU $4F70
PLAYER2_PROJECTILE_3        EQU $4F7F
TARGET_BLOCK_0              EQU $4F8E
TARGET_BLOCK_1              EQU $4F9D
TARGET_BLOCK_2              EQU $4FAC
TARGET_BLOCK_3              EQU $4FBB
SPAWN_TICK_A                EQU $4FCA
SPAWN_COUNT_A               EQU $4FCB
SPAWN_TICK_B                EQU $4FCC
SPAWN_COUNT_B               EQU $4FCD

VECTOR_BLOCK_BYTES          EQU $000F
PLAYER_VECTOR_STRIDE        EQU $001E   ; Every other vector block
GAME_FLAG_MISSILE           EQU 6
GAME_FLAG_UPI_ACTIVE        EQU 7
IM2_VECTOR_PAGE             EQU $23
IM2_VECTOR_OFFSET           EQU $10

;-------------------------------------------------------------------------------
; Cartridge header and menu
;-------------------------------------------------------------------------------

        ORG     FIRSTC

        DB      "U"                 ; User-cartridge sentinel

        DW      MENU_MISSILE_ENTRY  ; Next menu record
        DW      TEXT_SEAWOLF
        DW      START_SEAWOLF

MENU_MISSILE_ENTRY:
        DW      MENUST               ; End of cartridge menu list
        DW      TEXT_MISSILE
        DW      START_MISSILE

;-------------------------------------------------------------------------------
; Game entry points
;-------------------------------------------------------------------------------

START_MISSILE:
        CALL    INITIALIZE_GAME
        EI

        SYSTEM  INTPC            ;  UPI INTerPret with Context create

        DO      SETB             ;  UPI SET Byte
        DB      $40              ;  ... Data = 64
        DW      GAME_FLAGS

        DO      SETW             ;  UPI SET Word
        DW      PATTERN_MISSILE_LAUNCHER
        DW      PLAYER_PATTERN_PTR

        DO      COLSET           ;  UPI COLors SET
        DW      MISSILE_PALETTE

        DO      FILL             ;  UPI FILL memory with data
        DW      $4B90            ;  ... Memory Address = 19344
        DW      $00C8            ;  ... Byte Count = 200
        DB      $FF              ;  ... Data = 255

MISSILE_EVENT_LOOP:
        DO      SENTRY           ; UPI sense transitions
        DW      ALKEYS           ;  ALl KEYS Keypad Mask

        DO      DOIT             ;  UPI DOIT table, branch to translation
        DW      COMMON_DOIT_TABLE

        DO      DOIT             ;  UPI DOIT table, branch to translation
        DW      MISSILE_DOIT_TABLE

        DO      MJUMP            ;  UPI Macro JUMP to interpreter
        DW      MISSILE_EVENT_LOOP


START_SEAWOLF:
        CALL    INITIALIZE_GAME
        LD      A,$20
        OUT     (VOLC),A
        SYSTEM  INTPC            ;  UPI INTerPret with Context create

        DO      COLSET           ;  UPI COLors SET
        DW      SEAWOLF_PALETTE

        DO      SETW             ;  UPI SET Word
        DW      PATTERN_SEAWOLF_SUBMARINE
        DW      PLAYER_PATTERN_PTR

SEAWOLF_EVENT_LOOP:
        DO      SENTRY           ; UPI sense transitions
        DW      ALKEYS           ;  ALl KEYS Keypad Mask

        DO      DOIT             ;  UPI DOIT table, branch to translation handler
        DW      COMMON_DOIT_TABLE

        DO      DOIT             ;  UPI DOIT table, branch to translation handler
        DW      SEAWOLF_DOIT_TABLE

        DO      MJUMP            ;  UPI Macro JUMP to interpreter subroutine
        DW      SEAWOLF_EVENT_LOOP


; Prompts for game time, clears display/game RAM, and installs the IM 2 handler.
INITIALIZE_GAME:
        SYSSUK  GETPAR           ; UPI get game parameter
        DW      TEXT_TIME_PROMPT           ;  Prompt is "TIME"
        DB      $83              ;  ... Digits = 131
        DW      GAME_PARAMETER_BUFFER

        DI
        LD      HL,(GAME_PARAMETER_BUFFER)
        LD      (GTSECS),HL
        POP     HL
        LD      SP,PLAYER_PATTERN_PTR
        PUSH    HL

        SYSTEM  INTPC            ;  UPI INTerPret with Context create

        DO      SETOUT           ;  UPI SET some OUTput ports
        DB      $AE              ;  ... VERBL*2 = 174
        DB      $29              ;  ... HORCB/4 = 41
        DB      $08              ;  ... INMOD = 8

        DO      FILL             ;  UPI FILL memory with data
        DW      NORMEM           ;  ... Memory Address = $4000
        DW      $0D98            ;  ... Byte Count = 3480
        DB      $00              ;  ... Data = 0

        DO      FILL             ;  UPI FILL memory with data
        DW      PLAYER_PATTERN_PTR
        DW      $0110            ;  ... Byte Count = 272
        DB      $00              ;  ... Data = 0

        DO      FILL             ;  UPI FILL memory with data
        DW      CNT
        DW      $0006            ;  ... Byte Count = 6
        DB      $00              ;  ... Data = 0

        DO      SETB             ;  UPI SET Byte
        DB      $01              ;  ... Data = 1
        DW      SPAWN_COUNT_A

        DO      SETB             ;  UPI SET Byte
        DB      $02              ;  ... Data = 2
        DW      SPAWN_COUNT_B

        DO      SETW             ;  UPI SET Word
        DW      $1B01            ;  ... Data Word = 6913
        DW      CNT

        DO      SETW             ;  UPI SET Word
        DW      $AAAA            ;  ... Data Word = 43690
        DW      INTERRUPT_PHASE

        DO      SETB             ;  UPI SET Byte
        DB      $01              ;  ... Data = 1
        DW      GAMSTB

        DONT    XINTC            ;  UPI eXit INTerpreter with Context

        LD      A,IM2_VECTOR_PAGE
        LD      I,A
        LD      A,IM2_VECTOR_OFFSET
        OUT     (INFBK),A
        IM      2
        RET

; The SF4 entry begins one byte into the LD HL instruction. At $209E the
; remaining bytes decode as LD B,$08. This overlap saves one byte.
SEAWOLF_FLAG3_CHANGED:
        LD      B,$04
        DB      $21                  ; LD HL,nn opcode on the SF3 path
SEAWOLF_FLAG4_CHANGED:
        LD      B,$08
        LD      HL,PLAYER_SHOT_FLAGS
        LD      A,B
        CPL
        AND     (HL)
        LD      (HL),A
        LD      E,$00
        LD      C,$08
        EXX
        LD      B,$04
DRAW_ALL_TORPEDO_INDICATORS_LOOP:
        EXX
        CALL    DRAW_TORPEDO_INDICATOR_FROM_INDEX
        INC     E
        EXX
        DJNZ    DRAW_ALL_TORPEDO_INDICATORS_LOOP
DRAW_ONE_TORPEDO_INDICATOR_FROM_A:
        LD      E,A
        LD      C,$28
DRAW_TORPEDO_INDICATOR_FROM_INDEX:
        LD      HL,TORPEDO_INDICATOR_ADDRESS_TABLE
        PUSH    DE
        LD      D,$00
        ADD     HL,DE
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        BIT     2,B
        JR      NZ,DRAW_TORPEDO_INDICATOR_PATTERN
        LD      A,$44
        ADD     A,E
        LD      E,A
DRAW_TORPEDO_INDICATOR_PATTERN:
        LD      HL,PATTERN_TORPEDO_INDICATOR
        LD      A,B
        DI
        OUT     (XPAND),A
        LD      A,C
        SYSTEM  WRITP            ;  UPI WRITE With Pattern Size Lookup

        EI
        POP     DE
        RET

KEY_DOWN:
        LD      C,B
        EX      AF,AF'
MISSILE_POT0_CHANGED:
        LD      HL,PLAYER1_AIM_X
        LD      A,B
        CPL
        AND     $FC
        RRA
        RRA
        LD      B,(HL)
        LD      (HL),A
        CP      B
        RET     Z

        LD      E,A
        JR      REDRAW_PLAYER1
SEAWOLF_POT0_CHANGED:
        LD      HL,PLAYER1_AIM_X
        LD      C,$0B
        CALL    CONVERT_POT_POSITION
REDRAW_PLAYER1:
        LD      D,$45
        LD      HL,(PLAYER1_OLD_SCREEN_ADDR)
        LD      A,$04
        CALL    MOVE_PLAYER_SPRITE
        LD      (PLAYER1_OLD_SCREEN_ADDR),HL
        RET


MISSILE_POT1_CHANGED:
        LD      HL,PLAYER2_AIM_X
        LD      A,B
        CPL
        AND     $FC
        RRA
        RRA
        ADD     A,$52
        CP      $8E
        JR      C,CLAMP_PLAYER2_AIM
        LD      A,$8E
CLAMP_PLAYER2_AIM:
        LD      B,(HL)
        LD      (HL),A
        CP      B
        RET     Z

        LD      D,$45
        LD      E,A
        JR      REDRAW_PLAYER2
SEAWOLF_POT1_CHANGED:
        LD      HL,PLAYER2_AIM_X
        LD      C,$0C
        CALL    CONVERT_POT_POSITION
        LD      D,$4A
REDRAW_PLAYER2:
        LD      HL,(PLAYER2_OLD_SCREEN_ADDR)
        LD      A,$08
        CALL    MOVE_PLAYER_SPRITE
        LD      (PLAYER2_OLD_SCREEN_ADDR),HL
        RET


; Blanks the previous position and writes the player pattern at DE.
MOVE_PLAYER_SPRITE:
        PUSH    DE
        LD      DE,$0505
        DI
        OUT     (XPAND),A
        XOR     A
        LD      B,A
        CP      H
        LD      A,$08
        JR      Z,DRAW_NEW_PLAYER_SPRITE
        SET     6,H
        SYSTEM  BLANK            ;  UPI BLANK AREA

DRAW_NEW_PLAYER_SPRITE:
        POP     DE
        LD      HL,(PLAYER_PATTERN_PTR)
        SYSTEM  WRITP            ;  UPI WRITE WITH PATTERN SIZE

        EI
        EX      DE,HL
        RET


; Converts the raw knob value in B to an X coordinate in E.
; If the position did not change, the caller's return address is discarded.
CONVERT_POT_POSITION:
        LD      A,B
        CPL
        AND     $FC
        RRA
        ADD     A,C
        LD      B,(HL)
        LD      (HL),A
        LD      E,A
        CP      B
        RET     NZ
        POP     HL
        RET

COUNTER4_EXPIRED:
        LD      IX,SPAWN_BLOCK_A0
        LD      C,$05
        JR      SPAWN_TARGET

COUNTER3_EXPIRED:
        LD      IX,SPAWN_BLOCK_B0
        LD      C,$0E
SPAWN_TARGET:
        SYSSUK  RANGED           ; UPI random number
        DB      $00              ;  ... Cutoff = 0

        LD      DE,$6880
        BIT     3,A
        JR      NZ,SPAWN_DIRECTION_READY
        LD      D,$28
SPAWN_DIRECTION_READY:
        BIT     4,A
        JR      Z,CHOOSE_TARGET_TYPE
        SET     4,E
CHOOSE_TARGET_TYPE:
        AND     $03
        JR      NZ,TARGET_TYPE_READY
        INC     A
TARGET_TYPE_READY:
        INC     A
        PUSH    BC
        LD      C,A
        ADD     A,E
        LD      E,A
        LD      B,$00
        LD      HL,TARGET_SPEED_TABLE-$02
        ADD     HL,BC
        POP     BC
        LD      B,(HL)
        LD      A,(GAME_FLAGS)
        BIT     GAME_FLAG_MISSILE,A
        JR      Z,FIND_SPAWN_SLOT
        LD      B,$F0
FIND_SPAWN_SLOT:
        LD      A,(IX+VBSTAT)
        BIT     7,A
        JR      Z,TRY_SECOND_SPAWN_SLOT
        BIT     5,A
        RET     NZ

        LD      D,(IX+VBMR)
        EXX
        LD      DE,VECTOR_BLOCK_BYTES
        ADD     IX,DE
        EXX
        JR      INITIALIZE_VECTOR_BLOCK
TRY_SECOND_SPAWN_SLOT:
        LD      A,(IX+VECTOR_BLOCK_BYTES+VBSTAT)
        BIT     7,A
        JR      Z,INITIALIZE_VECTOR_BLOCK
        BIT     5,A
        RET     NZ

        LD      D,(IX+VECTOR_BLOCK_BYTES)
INITIALIZE_VECTOR_BLOCK:
        XOR     A
        BIT     7,(IX+VBSTAT)
        RET     NZ

        PUSH    IX
        POP     HL
        SET     4,D
        LD      (HL),D
        INC     HL
        LD      (HL),E
        INC     HL
        LD      (HL),$01
        INC     HL
        LD      (HL),B
        INC     HL
        LD      (HL),A
        INC     HL
        LD      (HL),A
        INC     HL
        LD      (HL),A
        INC     HL
        LD      (HL),$01
        LD      (IX+VBYH),C
        RET


SEAWOLF_COUNTER5_EXPIRED:
        LD      A,(PLAYER1_SHOT_INDEX)
        LD      B,$04
        CALL    DRAW_ONE_TORPEDO_INDICATOR_FROM_A
        LD      A,(PLAYER1_AIM_X)
        LD      HL,PLAYER1_PROJECTILE_0
        LD      C,$80
        CALL    ALLOCATE_PROJECTILE
        LD      HL,PLAYER1_SHOT_INDEX
        INC     (HL)
        LD      A,(HL)
        XOR     $04
        RET     NZ

        LD      (HL),A
        DEC     HL
        SET     2,(HL)
        LD      A,$03
        JR      QUEUE_COUNTER_UPDATE


SEAWOLF_COUNTER6_EXPIRED:
        LD      A,(PLAYER2_SHOT_INDEX)
        LD      B,$08
        CALL    DRAW_ONE_TORPEDO_INDICATOR_FROM_A
        LD      A,(PLAYER2_AIM_X)
        LD      HL,PLAYER2_PROJECTILE_0
        LD      C,$90
        RRC     B
        CALL    ALLOCATE_PROJECTILE
        LD      HL,PLAYER2_SHOT_INDEX
        INC     (HL)
        LD      A,(HL)
        XOR     $04
        RET     NZ

        LD      (HL),A
        INC     HL
        SET     3,(HL)
        LD      A,$05
QUEUE_COUNTER_UPDATE:
        LD      HL,CNT
        OR      (HL)
        LD      (HL),A
        RET


; The ST1 entry begins on the second byte of LD IX,$0820. The remaining
; three bytes decode as LD HL,$0820, providing the player-two masks.
TRIGGER0_CHANGED:
        LD      HL,$0402
        DB      $DD                  ; IX prefix on the player-one path
TRIGGER1_CHANGED:
        LD      HL,$0820
        LD      A,B
        OR      A
        RET     Z

        LD      A,(GAMSTB)
        BIT     7,A
        RET     NZ

        LD      DE,PLAYER_SHOT_FLAGS
        LD      A,(DE)
        AND     H
        RET     NZ

        LD      A,(DE)
        OR      L
        LD      (DE),A
        RET


ALLOCATE_ONE_PROJECTILE:
        LD      B,$01
ALLOCATE_PROJECTILE:
        CALL    FIND_FREE_VECTOR_BLOCK
        LD      (HL),$38
        INC     HL
        LD      (HL),C
        INC     HL
        LD      BC,$000B
        LD      DE,PROJECTILE_VECTOR_TEMPLATE
        EX      DE,HL
        LDIR
        LD      (IX+VBXH),A
        LD      A,$FE
        LD      (SOUND_COUNTDOWN),A
        RET


SELECT_OBJECT_DRAW_DATA:
        LD      HL,GAME_FLAGS
        BIT     GAME_FLAG_MISSILE,(HL)
        LD      HL,SEAWOLF_DRAW_DATA_TABLE
        JR      Z,INDEX_OBJECT_DRAW_TABLE
        LD      L,$0E                ; Low byte of MISSILE_DRAW_DATA_TABLE
INDEX_OBJECT_DRAW_TABLE:
        LD      D,$00
        LD      B,A
        AND     $07
        LD      E,A
        ADD     HL,DE
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        CP      $01
        JR      NZ,SET_NORMAL_EXPANDER
        LD      A,$0C
        JR      WRITE_EXPANDER_MODE
SET_NORMAL_EXPANDER:
        LD      A,$04
        BIT     4,B
        JR      Z,WRITE_EXPANDER_MODE
        RLCA
WRITE_EXPANDER_MODE:
        OUT     (XPAND),A
        RET

SEAWOLF_COUNTER2_EXPIRED:
        LD      HL,PLAYER2_LOAD_TIMER
        LD      DE,$0860
        JR      SHOW_LOAD_MESSAGE

SEAWOLF_COUNTER1_EXPIRED:
        LD      HL,PLAYER1_LOAD_TIMER
        LD      DE,$041C
SHOW_LOAD_MESSAGE:
        LD      (HL),$12
        LD      HL,TEXT_LOAD
        LD      C,D
        LD      D,$4F
        DI
        SYSTEM  STRDIS           ; UPI string display

        EI
        RET

;-------------------------------------------------------------------------------
; UPI event dispatch tables
;-------------------------------------------------------------------------------

SEAWOLF_DOIT_TABLE:
        RC      SCT6, SEAWOLF_COUNTER6_EXPIRED, $00
        RC      SCT5, SEAWOLF_COUNTER5_EXPIRED, $00
        RC      SCT2, SEAWOLF_COUNTER2_EXPIRED, $00
        RC      SCT1, SEAWOLF_COUNTER1_EXPIRED, $00
        RC      SCT0, SEAWOLF_COUNTER0_EXPIRED, $00
        RC      SF4,  SEAWOLF_FLAG4_CHANGED, $00
        RC      SF3,  SEAWOLF_FLAG3_CHANGED, $00
        RC      SP0,  SEAWOLF_POT0_CHANGED, $00
        RC      SP1,  SEAWOLF_POT1_CHANGED, ENDx

COMMON_DOIT_TABLE:
        RC      SCT7, QUIT_GAME, $00
        RC      SCT4, COUNTER4_EXPIRED, $00
        RC      SCT3, COUNTER3_EXPIRED, $00
        RC      SF7,  PROJECTILE_STATUS_CHANGED, $00
        RC      SF1,  SCORE_CHANGED, $00
        RC      ST0,  TRIGGER0_CHANGED, $00
        RC      ST1,  TRIGGER1_CHANGED, $00
        RC      SSEC, SECOND_ELAPSED, $00
        MC      SKYD, KEY_DOWN, ENDx

;-------------------------------------------------------------------------------
; Music and ROM lookup tables
;-------------------------------------------------------------------------------

; Played after a projectile hits a target.
HIT_MUSIC_SCORE:
        DB    $88
        DB    $EF
        DB    $3F
        DB    $FF
        DB    $00
        DB    $FF
        DB    $FD
        DB    $F5
        DB    $F5
        DB    $E0
        DB    $B0
        DB    $FF
        DB    $3F
        DB    $0C
        DB    $EF
        DB    $B0
        DB    $EE
        DB    $3E
        DB    $0C
        DB    $8F
        DB    $B0
        DB    $88
        DB    $38
        DB    $0C
        DB    $4E
        DB    $B0
        DB    $44
        DB    $34
        DB    $0C
        DB    $48
        DB    $B0
        DB    $00
        DB    $20
        DB    $78
        DB    $20
        DB    $C3
        DB    $F4
        DB    $22

; Played for the 50-point PT boat in Seawolf.
PT_BOAT_MUSIC_SCORE:
        DB    $B0
        DB    $0F
        DB    $20
        DB    $A3
        DB    $06
        DB    $F0
        DB    $18
        DB    $01
        DB    $02
        DB    $F0
        DB    $0C
        DB    $01
        DB    $C0
        DB    $00
        DB    $23
        DB      $C3,$F4,$22

; Index is the low three status bits. Entry 1 is unused by object drawing;
; its bytes double as the IM 2 vector used by the Astrocade interrupt circuit.
MISSILE_DRAW_DATA_TABLE:
        DW      MISSILE_EXPLOSION_DRAW_DATA
IM2_VECTOR_WORD:
        DW      INTERRUPT_HANDLER
        DW      MISSILE_CARGO_DRAW_DATA
        DW      MISSILE_BOMBER_DRAW_DATA
        DW      MISSILE_FIGHTER_DRAW_DATA

TORPEDO_INDICATOR_ADDRESS_TABLE:
        DW      $4F1C,$531C,$4F2E,$532E

MISSILE_PALETTE:
        DB      $A2,$5B,$08,$07      ; Green, red, blue, white

SEAWOLF_PALETTE:
        DB      $07,$55,$7F,$F9      ; White, purple, yellow, blue

;-------------------------------------------------------------------------------
; Text, motion data, sound registers, and object pointer table
;-------------------------------------------------------------------------------

TEXT_LOAD:
        DB      "LOAD"
OBJECT_VECTOR_LEFT:
        DB      $00,$96,$01,$56
OBJECT_VECTOR_RIGHT:
        DB      $00,$8B

SEAWOLF_DRAW_DATA_TABLE:
        DW      SEAWOLF_TORPEDO_DRAW_DATA
        DW      SEAWOLF_MINE_DRAW_DATA
        DW      SEAWOLF_TANKER_DRAW_DATA
        DW      SEAWOLF_BATTLESHIP_DRAW_DATA
        DW      SEAWOLF_PT_BOAT_DRAW_DATA

TARGET_SPEED_TABLE:
        DB      $70,$80,$E0

MISSILE_SOUND_TABLE:
        DB      $20,$55,$25,$7F,$7D,$7E,$7F,$CF
        DB      $20,$55,$25,$32,$4D,$4E,$4F,$AF
        DB      $20,$55,$25,$25,$47,$4F,$9F,$48

; Each object pointer includes a two-byte displacement immediately before its
; pattern header. Some menu-string terminators are reused as displacement data.
SEAWOLF_PT_BOAT_DRAW_DATA:
        DB      $04,$02

PATTERN_SEAWOLF_PT_BOAT:
        DB    $02, $04 ; 2 byte x 4 line pattern size
        DB    $00, $60 ; 00000000,01100000 - . . . . . . . . . * * . . . . .
        DB    $04, $70 ; 00000100,01110000 - . . . . . * . . . * * * . . . .
        DB    $03, $FF ; 00000011,11111111 - . . . . . . * * * * * * * * * *
        DB    $0F, $FE ; 00001111,11111110 - . . . . * * * * * * * * * * * .

TEXT_MISSILE:
        DB      "MISSILE"
SEAWOLF_TANKER_DRAW_DATA:
        DB      $00,$01

; Tanker: 10 points.
PATTERN_SEAWOLF_TANKER:
        DB    $03, $05      ; 3 byte x 5 line pattern size
        DB    $04, $58, $80 ; 00000100,01011000,10000000 - . . . . . * . . . * . * * . . . * . . . . . . .
        DB    $04, $F8, $80 ; 00000100,11111000,10000000 - . . . . . * . . * * * * * . . . * . . . . . . .
        DB    $FC, $F8, $F0 ; 11111100,11111000,11110000 - * * * * * * . . * * * * * . . . * * * * . . . .
        DB    $FF, $FF, $E0 ; 11111111,11111111,11100000 - * * * * * * * * * * * * * * * * * * * . . . . .
        DB    $7F, $FF, $C0 ; 01111111,11111111,11000000 - . * * * * * * * * * * * * * * * * * . . . . . .

TEXT_TIME_PROMPT:
        DB      "TIME"
SEAWOLF_BATTLESHIP_DRAW_DATA:
        DB      $00,$00

; Battleship: 30 points.
PATTERN_SEAWOLF_BATTLESHIP:
        DB    $03, $06      ; 3 byte x 6 line pattern size
        DB    $06, $C0, $00 ; 00000110,11000000,00000000 - . . . . . * * . * * . . . . . . . . . . . . . .
        DB    $06, $D9, $F8 ; 00000110,11011001,11111000 - . . . . . * * . * * . * * . . * * * * * * . . .
        DB    $4F, $FD, $C0 ; 01001111,11111101,11000000 - . * . . * * * * * * * * * * . * * * . . . . . .
        DB    $FF, $FF, $FE ; 11111111,11111111,11111110 - * * * * * * * * * * * * * * * * * * * * * * * .
        DB    $FF, $FF, $FC ; 11111111,11111111,11111100 - * * * * * * * * * * * * * * * * * * * * * * . .
        DB    $7F, $FF, $F8 ; 01111111,11111111,11111000 - . * * * * * * * * * * * * * * * * * * * * . . .

SEAWOLF_MINE_DRAW_DATA:
        DB      $08,$00

PATTERN_SEAWOLF_MINE:
        DB    $01, $0A ; 1 byte x 10 line pattern size
        DB    $2A      ; 00101010 - . . * . * . * .
        DB    $1C      ; 00011100 - . . . * * * . .
        DB    $3E      ; 00111110 - . . * * * * * .
        DB    $1C      ; 00011100 - . . . * * * . .
        DB    $2A      ; 00101010 - . . * . * . * .
        DB    $08      ; 00001000 - . . . . * . . .
        DB    $00      ; 00000000 - . . . . . . . .
        DB    $10      ; 00010000 - . . . * . . . .
        DB    $00      ; 00000000 - . . . . . . . .
        DB    $20      ; 00100000 - . . * . . . . .

; Pattern (Submarine in Seawolf)
PATTERN_SEAWOLF_SUBMARINE:
        DB    $02, $04 ; 2 byte x 4 line pattern size
        DB    $01, $C0 ; 00000001,11000000 - . . . . . . . * * * . . . . . .
        DB    $01, $C0 ; 00000001,11000000 - . . . . . . . * * * . . . . . .
        DB    $FF, $FF ; 11111111,11111111 - * * * * * * * * * * * * * * * *
        DB    $7F, $FF ; 01111111,11111111 - . * * * * * * * * * * * * * * *

; Pattern (Player's Ship in Missile)
PATTERN_MISSILE_LAUNCHER:
        DB    $01, $05 ; 1 byte x 5 line pattern size
        DB    $08      ; 00001000 - . . . . * . . .
        DB    $08      ; 00001000 - . . . . * . . .
        DB    $49      ; 01001001 - . * . . * . . *
        DB    $5D      ; 01011101 - . * . * * * . *
        DB    $7F      ; 01111111 - . * * * * * * *

SEAWOLF_TORPEDO_DRAW_DATA:
        DB      $08,$00

PATTERN_SEAWOLF_TORPEDO:
        DB    $01, $05 ; 1 byte x 5 line pattern size
        DB    $C0      ; 11000000 - **......
        DB    $C0      ; 11000000 - **......
        DB    $C0      ; 11000000 - **......
        DB    $C0      ; 11000000 - **......
        DB    $C0      ; 11000000 - **......

TEXT_SEAWOLF:
        DB      "SEAWOLF",$00

; Four copies are drawn above the submarine as the torpedo/load indicators.
PATTERN_TORPEDO_INDICATOR:
        DB    $02, $04  ; 2 bytes, 4 lines pattern size
        DB    $9F, $FC  ; 10011111,11111100 - * . . * * * * * * * * * * * . .
        DB    $FF, $FE  ; 11111111,11111110 - * * * * * * * * * * * * * * * .
        DB    $9F, $FC  ; 10011111,11111100 - * . . * * * * * * * * * * * . .
SEAWOLF_EXPLOSION_DRAW_DATA:
        DB    $00, $00  ; 00000000,00000000 - . . . . . . . . . . . . . . . .

PATTERN_SEAWOLF_EXPLOSION:
        DB    $02, $05  ; 2 bytes, 5 lines pattern size
        DB    $22, $22  ; 00100010,00100010 - . . * . . . * . . . * . . . * .
        DB    $88, $88  ; 10001000,10001000 - * . . . * . . . * . . . * . . .
        DB    $25, $10  ; 00100101,00010000 - . . * . . * . * . . . * . . . .
        DB    $2D, $C8  ; 00101101,11001000 - . . * . * * . * * * . . * . . .
        DB    $0F, $F0  ; 00001111,11110000 - . . . . * * * * * * * * . . . .

ALT_EXPLOSION_DRAW_DATA:
        DB      $09,$00
PATTERN_ALT_EXPLOSION:
        DB      $01,$0A
        DB      $21,$88,$02,$20,$08,$10,$04,$40,$11,$84
MISSILE_EXPLOSION_DRAW_DATA:
        DB      $03,$00
PATTERN_MISSILE_EXPLOSION:
        DB      $01,$04
        DB      $40,$40,$40,$E0

MISSILE_CARGO_DRAW_DATA:
        DB      $04,$00
PATTERN_MISSILE_CARGO:
        DB    $02, $06 ; 2 bytes, 6 lines pattern size
        DB    $C0, $00 ; 11000000,00000000 - * * . . . . . . . . . . . . . .
        DB    $E0, $70 ; 11100000,01110000 - * * * . . . . . . * * * . . . .
        DB    $FF, $FE ; 11111111,11111110 - * * * * * * * * * * * * * * * .
        DB    $FF, $FF ; 11111111,11111111 - * * * * * * * * * * * * * * * *
        DB    $FF, $FE ; 11111111,11111110 - * * * * * * * * * * * * * * * .
        DB    $07, $80 ; 00000111,10000000 - . . . . . * * * * . . . . . . .

MISSILE_BOMBER_DRAW_DATA:
        DB      $04,$01
PATTERN_MISSILE_BOMBER:
        DB      $02,$05
        DB      $C0,$00
        DB      $E0,$60
        DB      $FF,$F8
        DB      $FF,$FC
        DB      $7F,$F8

MISSILE_FIGHTER_DRAW_DATA:
        DB      $0A,$01
PATTERN_MISSILE_FIGHTER:
        DB    $01, $05 ; 1 byte, 5 lines pattern size
        DB    $80      ; 10000000 - * . . . . . . .
        DB    $CC      ; 11001100 - * * . . * * . .
        DB    $FE      ; 11111110 - * * * * * * * .
        DB    $FF      ; 11111111 - * * * * * * * *
        DB    $7E      ; 01110111 - . * * * * * * .

; Copied into bytes 4-14 of a newly allocated projectile vector block.
PROJECTILE_VECTOR_TEMPLATE:
        DB      $01,$00,$00,$00,$00,$01,$40,$FF,$00,$40,$01

;-------------------------------------------------------------------------------
; Timers and periodic UPI handlers
;-------------------------------------------------------------------------------

UPDATE_RELOAD_TIMERS:
        LD      HL,PLAYER1_RELOAD_TICK
        DEC     (HL)
        JR      NZ,UPDATE_PLAYER2_RELOAD
        LD      (HL),$14
        LD      L,$CF
        BIT     5,(HL)
        JR      Z,CHECK_PLAYER1_LOAD_TIMER
        RES     5,(HL)
        LD      HL,CNT
        SET     6,(HL)
        RET

CHECK_PLAYER1_LOAD_TIMER:
        BIT     3,(HL)
        RET     Z

        LD      L,$D7
        DEC     (HL)
        RET     NZ

        LD      HL,SEMI4S
        SET     4,(HL)
        RET


UPDATE_PLAYER2_RELOAD:
        INC     HL
        DEC     (HL)
        RET     NZ

        LD      (HL),$14
        LD      L,$CF
        BIT     1,(HL)
        JR      Z,CHECK_PLAYER2_LOAD_TIMER
        RES     1,(HL)
        LD      HL,CNT
        SET     5,(HL)
        RET

CHECK_PLAYER2_LOAD_TIMER:
        BIT     2,(HL)
        RET     Z

        LD      L,$D6
        DEC     (HL)
        RET     NZ

        LD      HL,SEMI4S
QUEUE_SEAWOLF_COUNTER3:
        SET     3,(HL)
        RET


UPDATE_SPAWN_TIMERS:
        LD      HL,GAMSTB
        BIT     7,(HL)
        RET     NZ

        LD      L,$CA
        DEC     (HL)
        JR      NZ,UPDATE_SECOND_SPAWN_TIMER
        LD      (HL),$A8
        INC     HL
        DEC     (HL)
        RET     NZ

        LD      (HL),$03
        LD      A,(GAME_FLAGS)
        BIT     GAME_FLAG_MISSILE,A
        JR      Z,QUEUE_COUNTER4
        LD      (HL),$02
QUEUE_COUNTER4:
        LD      L,$DD                ; CNT
        SET     4,(HL)
UPDATE_SECOND_SPAWN_TIMER:
        LD      L,$CC                ; SPAWN_TICK_B
        DEC     (HL)
        RET     NZ

        LD      (HL),$88
        INC     HL
        DEC     (HL)
        RET     NZ

        LD      (HL),$03
        LD      L,$DD
        JR      QUEUE_SEAWOLF_COUNTER3


SEAWOLF_COUNTER0_EXPIRED:
        LD      HL,SPAWN_PHASE
        RLC     (HL)
        LD      IX,TARGET_BLOCK_2
        LD      DE,$3881
        LD      BC,$082E
        JR      NC,INITIALIZE_FIRST_TARGET
        LD      C,$1C
        LD      IX,TARGET_BLOCK_0
INITIALIZE_FIRST_TARGET:
        CALL    INITIALIZE_VECTOR_BLOCK
        JR      NZ,INITIALIZE_SECOND_TARGET
        LD      (IX+VBXH),$05
        BIT     7,(IX+VECTOR_BLOCK_BYTES+VBSTAT)
        JR      Z,INITIALIZE_SECOND_TARGET
        LD      A,(IX+VECTOR_BLOCK_BYTES+VBXH)
        CP      $37
        JR      C,SET_FIRST_TARGET_X
        LD      A,$B5
SET_FIRST_TARGET_X:
        ADD     A,$50
        LD      (IX+VBXH),A
INITIALIZE_SECOND_TARGET:
        EXX
        LD      DE,VECTOR_BLOCK_BYTES
        ADD     IX,DE
        EXX
        CALL    INITIALIZE_VECTOR_BLOCK
        RET     NZ

        LD      A,(IX-$09)
        CP      $37
        JR      C,SET_SECOND_TARGET_X
        LD      A,$B5
SET_SECOND_TARGET_X:
        ADD     A,$50
        LD      (IX+VBXH),A
        RET

QUIT_GAME:
        DI
        SYSTEM  EMUSIC           ;  UPI End playing MUSIC

        SYSTEM  QUIT             ;  UPI QUIT cassette execution

SECOND_ELAPSED:
        LD      HL,GAME_FLAGS
        SET     GAME_FLAG_UPI_ACTIVE,(HL)
        SYSSUK  DISTIM           ;  UPI DISplay TIMe
        DB      $44              ;  ... X = 68
        DB      $50              ;  ... Y = 80
        DB      $8C              ;  ... Options = 140

        RES     GAME_FLAG_UPI_ACTIVE,(HL)
        SYSSUK  DECCTS           ;  UPI DECrement CT'S under
        DB      $80              ;  ... Counters = 128

        LD      HL,GAMSTB
        BIT     7,(HL)
        RET     NZ

        LD      L,$DC
        LD      (HL),$03
        RET


;-------------------------------------------------------------------------------
; Collision detection and scoring
;-------------------------------------------------------------------------------

; Searches four interleaved vector blocks. H and L hold the collision box;
; on a hit, HL points to the matching block and B remains nonzero.
FIND_COLLIDING_OBJECT:
        PUSH    BC
        LD      B,$04
        LD      E,$05
SCAN_COLLISION_CANDIDATE:
        LD      C,(HL)
        INC     HL
        BIT     7,(HL)
        JR      Z,SKIP_INACTIVE_CANDIDATE
        BIT     5,(HL)
        JR      NZ,SKIP_INACTIVE_CANDIDATE
        ADD     HL,DE
        LD      A,(HL)
        BIT     6,C
        JR      Z,CLAMP_X_DISTANCE
        SUB     $88
        NEG
CLAMP_X_DISTANCE:
        SUB     $0B
        JR      NC,CHECK_X_DISTANCE
        XOR     A
CHECK_X_DISTANCE:
        SUB     (IX+VBXH)
        JR      NC,SKIP_TO_NEXT_CANDIDATE_2
        NEG
        EX      (SP),HL
        CP      H
        EX      (SP),HL
        JR      NC,SKIP_TO_NEXT_CANDIDATE_2
        ADD     HL,DE
        LD      A,(HL)
        SUB     (IX+VBYH)
        JR      NC,CHECK_Y_DISTANCE
        NEG
CHECK_Y_DISTANCE:
        EX      (SP),HL
        CP      L
        EX      (SP),HL
        JR      NC,SKIP_TO_NEXT_CANDIDATE
        XOR     A
        SBC     HL,DE
        SBC     HL,DE
        DEC     HL
        POP     AF
        RET

SKIP_INACTIVE_CANDIDATE:
        ADD     HL,DE
SKIP_TO_NEXT_CANDIDATE_2:
        ADD     HL,DE
SKIP_TO_NEXT_CANDIDATE:
        ADD     HL,DE
        DEC     HL
        DJNZ    SCAN_COLLISION_CANDIDATE
        POP     AF
        RET


PROJECTILE_STATUS_CHANGED:
        LD      B,$08
        LD      IX,GAME_PARAMETER_BUFFER
PROCESS_PROJECTILE_LOOP:
        EXX
        LD      DE,VECTOR_BLOCK_BYTES
        ADD     IX,DE
        LD      A,(IX+VBSTAT)
        BIT     5,A
        JR      Z,NEXT_PROJECTILE
        RES     5,(IX+VBSTAT)
        PUSH    AF
        LD      A,$17
        CP      (IX+VBYH)
        JR      NC,CHECK_SEAWOLF_TARGETS
        LD      HL,TARGET_BLOCK_0
        LD      BC,$160A
        CALL    FIND_COLLIDING_OBJECT
        LD      A,B
        POP     BC
        OR      A
        JR      Z,NEXT_PROJECTILE
        LD      E,$07
        ADD     HL,DE
        SET     7,(HL)
        ADD     HL,DE
        DEC     HL
        LD      (HL),B
        JR      START_HIT_MUSIC
CHECK_SEAWOLF_TARGETS:
        LD      HL,VECTOR_POOL
        LD      BC,$1C07
        CALL    FIND_COLLIDING_OBJECT
        LD      A,B
        POP     BC
        OR      A
        JR      Z,NEXT_PROJECTILE
        INC     HL
        LD      C,(HL)
        INC     E
        ADD     HL,DE
        SET     7,(HL)
        ADD     HL,DE
        LD      (HL),B
        CALL    ADD_TARGET_SCORE
START_HIT_MUSIC:
        LD      A,$01
        LD      HL,GAME_FLAGS
        SET     0,(HL)
        LD      HL,HIT_MUSIC_SCORE
        DI
        SYSTEM  BMUSIC           ;  UPI BEGIN PLAYING MUSIC
        EI
NEXT_PROJECTILE:
        EXX
        DJNZ    PROCESS_PROJECTILE_LOOP

SCORE_CHANGED:
        CALL    DISPLAY_PLAYER2_SCORE
        LD      DE,$0408
        LD      HL,PLAYER1_SCORE
        JR      DISPLAY_SCORE
DISPLAY_PLAYER2_SCORE:
        LD      DE,$0888
        LD      HL,PLAYER2_SCORE
DISPLAY_SCORE:
        LD      C,D
        LD      D,$50
        EXX
        LD      HL,GAME_FLAGS
        SET     GAME_FLAG_UPI_ACTIVE,(HL)
        EXX
        LD      B,$C4
        LD      IX,$020D
        SYSTEM  DISNUM           ;  UPI DISPLAY NUMBER
        EXX
        RES     GAME_FLAG_UPI_ACTIVE,(HL)
        RET

; Seawolf target types 2, 3, and 4 award 10, 30, and 50 points.
ADD_TARGET_SCORE:
        LD      HL,PLAYER1_SCORE
        LD      B,(IX+VBSTAT)
        BIT     4,B
        JR      Z,APPLY_SCORE_VALUE
        INC     HL
        INC     HL
APPLY_SCORE_VALUE:
        LD      A,$07
        AND     C
        DEC     A
        DEC     A
        RRC     A
        RRC     A
        RRC     A
        ADD     A,$10
        LD      B,(HL)
        ADD     A,B
        DAA
        LD      (HL),A
        INC     HL
        LD      A,(HL)
        ADC     A,$00
        DAA
        LD      (HL),A
        RET


; Handles a vector object that has reached a boundary or collision condition.
HANDLE_VECTOR_LIMIT:
        LD      A,$07
        LD      DE,$0005
        PUSH    IX
        POP     HL
        AND     (IX+VBSTAT)
        JR      Z,RETIRE_PROJECTILE
        BIT     6,(HL)
        LD      (HL),$0B
        INC     HL
        SET     5,(HL)
        RET     Z
        ADD     HL,DE
        LD      A,$88
        SUB     (HL)
        LD      (HL),A
        RET

RETIRE_PROJECTILE:
        INC     HL
        RES     7,(HL)
        SET     5,(HL)
        ADD     HL,DE
        INC     HL
        RES     7,(HL)
        LD      HL,SEMI4S
        SET     7,(HL)
        RET


;-------------------------------------------------------------------------------
; Per-interrupt vector-object update
;-------------------------------------------------------------------------------

UPDATE_VECTOR_OBJECT:
        DEC     HL
        BIT     7,(HL)
        RET     NZ

        XOR     A
        OR      D
        RET     Z

        INC     DE
        LD      A,(DE)
        BIT     5,A
        JP      NZ,UPDATE_EXPLOSION
        CALL    SELECT_OBJECT_DRAW_DATA
        BIT     4,(IX+VBMR)
        JR      NZ,UPDATE_TARGET_OBJECT
        SYSTEM  VWRITR           ;  UPI Vector WRITe Relative

        BIT     7,(IX+VBXCHK)
        JR      NZ,HANDLE_VECTOR_LIMIT
        PUSH    HL
        LD      HL,OBJECT_VECTOR_LEFT
        LD      A,(IX+VBSTAT)
        AND     $07
        JR      Z,APPLY_OBJECT_VECTOR
        LD      HL,OBJECT_VECTOR_RIGHT
APPLY_OBJECT_VECTOR:
        SYSTEM  VECT             ; UPI vector move coordinate pair

        POP     HL
        BIT     3,(IX+VBYCHK)
        JR      NZ,DEACTIVATE_VECTOR_OBJECT
        BIT     3,(IX+VBXCHK)
        JR      Z,MOVE_VECTOR_RELATIVE
DEACTIVATE_VECTOR_OBJECT:
        RES     7,(IX+VBSTAT)
        RET


UPDATE_TARGET_OBJECT:
        RES     4,(IX+VBMR)
        LD      A,(IX+VBSTAT)
        AND     $07
        CP      $02
        JR      C,MOVE_VECTOR_RELATIVE
        LD      B,A
        PUSH    HL
        LD      HL,GAME_FLAGS
        BIT     0,(HL)
        JR      NZ,FINISH_TARGET_UPDATE
        BIT     GAME_FLAG_MISSILE,(HL)
        JR      NZ,WRITE_MISSILE_SOUND
        LD      A,$04
        CP      B
        JR      NZ,FINISH_TARGET_UPDATE
        PUSH    IX
        SYSSUK  BMUSIC           ;  UPI Begin playing MUSIC
        DW      $4DA0            ; Music stack
        DB      $C0              ;  ... Voices = 192
        DW      PT_BOAT_MUSIC_SCORE            ;  ... Score Address = 8956

        POP     IX
        JR      FINISH_TARGET_UPDATE
WRITE_MISSILE_SOUND:
        LD      HL,MISSILE_SOUND_TABLE-$10
        SYSTEM  EMUSIC           ;  UPI End playing MUSIC

        LD      DE,$0008
INDEX_MISSILE_SOUND:
        ADD     HL,DE
        DJNZ    INDEX_MISSILE_SOUND
        LD      BC,$0818
        OTIR
FINISH_TARGET_UPDATE:
        POP     HL
MOVE_VECTOR_RELATIVE:
        IN      A,(INTST)
        SYSTEM  VWRITR           ;  UPI Vector WRITe Relative

        LD      A,$07
        AND     (IX+VBSTAT)
        RET     NZ

        IN      A,(INTST)
        OR      A
        RET     Z

        SET     7,(IX+VBXCHK)
        RET


UPDATE_EXPLOSION:
        EX      DE,HL
        DEC     HL
        DEC     (HL)
        JR      NZ,DRAW_EXPLOSION_FRAME
        INC     HL
        RES     7,(HL)
        LD      HL,GAME_FLAGS
        RES     0,(HL)
        RET

; The type-1 entry starts one byte into LD IY,ALT_EXPLOSION_DRAW_DATA. The
; remaining bytes decode as LD HL,ALT_EXPLOSION_DRAW_DATA.
DRAW_EXPLOSION_FRAME:
        AND     $07
        CP      $01
        LD      E,(IX+VBXH)
        LD      D,(IX+VBYH)
        JR      Z,USE_ALT_EXPLOSION_DRAW_DATA
        LD      HL,SEAWOLF_EXPLOSION_DRAW_DATA
        DB      $FD                  ; IY prefix on the fall-through path
USE_ALT_EXPLOSION_DRAW_DATA:
        LD      HL,ALT_EXPLOSION_DRAW_DATA
        LD      A,$04
        BIT     4,(IX+VBOAL)
        JR      Z,SET_EXPLOSION_EXPANDER
        RLCA
SET_EXPLOSION_EXPANDER:
        OUT     (XPAND),A
        LD      A,$28
        SYSTEM  WRITR            ;  UPI WRITe RELATIVE
        RET


; Chooses one active object from alternating halves of the vector pool.
SELECT_NEXT_OBJECT:
        LD      B,$0C
        LD      HL,GAME_FLAGS
        BIT     GAME_FLAG_UPI_ACTIVE,(HL)
        INC     HL
        LD      C,(HL)
        RET     NZ

        PUSH    IX
        POP     HL
SCAN_OBJECTS:
        XOR     A
        OR      H
        JR      Z,SELECT_SCAN_START
        PUSH    HL
        LD      DE,TARGET_BLOCK_3
        BIT     0,C
        JR      NZ,TEST_LAST_OBJECT_GROUP
        LD      E,$7F
TEST_LAST_OBJECT_GROUP:
        SBC     HL,DE
        POP     HL
        JR      NZ,ADVANCE_SCAN_POINTER
SELECT_SCAN_START:
        LD      HL,VECTOR_POOL+VBSTAT
        BIT     0,C
        JR      Z,TEST_OBJECT_ACTIVE
        LD      HL,GAME_PARAMETER_BUFFER
ADVANCE_SCAN_POINTER:
        LD      DE,VECTOR_BLOCK_BYTES+1
        ADD     HL,DE
TEST_OBJECT_ACTIVE:
        BIT     7,(HL)
        DEC     HL
        JR      Z,NEXT_SCAN_OBJECT
        BIT     0,C
        PUSH    HL
        POP     IX
        LD      A,(IX+VBYH)
        JR      NZ,TEST_ODD_OBJECT_Y
        CP      $12
        JR      C,STORE_OBJECT_CURSOR
        JR      NEXT_SCAN_OBJECT
TEST_ODD_OBJECT_Y:
        CP      $12
        JR      NC,STORE_OBJECT_CURSOR
NEXT_SCAN_OBJECT:
        DJNZ    SCAN_OBJECTS
        LD      H,B
STORE_OBJECT_CURSOR:
        BIT     0,C
        JR      NZ,STORE_ODD_OBJECT_CURSOR
        LD      (EVEN_OBJECT_CURSOR),HL
        RET


STORE_ODD_OBJECT_CURSOR:
        LD      (ODD_OBJECT_CURSOR),HL
        LD      HL,SOUND_COUNTDOWN
        LD      A,(HL)
        OR      A
        RET     Z

        SUB     $02
        LD      (HL),A
        INC     HL
        BIT     0,(HL)
        RET     NZ

        OUT     (VOLN),A
        RET


MISSILE_DOIT_TABLE:
        RC      SCT6, MISSILE_COUNTER6_EXPIRED, $00
        RC      SCT5, MISSILE_COUNTER5_EXPIRED, $00
        RC      SP0,  MISSILE_POT0_CHANGED, $00
        RC      SP1,  MISSILE_POT1_CHANGED, $00
        RC      SJ0,  MISSILE_JOYSTICK0_CHANGED, $00
        RC      SJ1,  MISSILE_JOYSTICK1_CHANGED, ENDx

; IM 2 entry selected by I=$23 and interrupt feedback byte $10. The vector word
; at $2310 points here.
INTERRUPT_HANDLER:
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        PUSH    IX
        PUSH    IY
        LD      DE,(ODD_OBJECT_CURSOR)
        LD      A,$24
        LD      HL,INTERRUPT_PHASE
        RLC     (HL)
        JR      C,RUN_INTERRUPT_TASKS
        LD      DE,(EVEN_OBJECT_CURSOR)
        LD      A,$A7
RUN_INTERRUPT_TASKS:
        PUSH    DE
        POP     IX
        OUT     (INLIN),A
        CALL    UPDATE_VECTOR_OBJECT
        CALL    UPDATE_RELOAD_TIMERS
        CALL    UPDATE_SPAWN_TIMERS
        CALL    SELECT_NEXT_OBJECT
        LD      HL,VECTOR_POOL+VBTIMB
        BIT     0,C
        JR      NZ,ADVANCE_OBJECT_TIMERS
        CALL    STIMER
        LD      HL,VECTOR_POOL+(8*VECTOR_BLOCK_BYTES)+VBTIMB
ADVANCE_OBJECT_TIMERS:
        LD      DE,VECTOR_BLOCK_BYTES
        LD      B,$08
ADVANCE_NEXT_TIMER:
        INC     (HL)
        ADD     HL,DE
        DJNZ    ADVANCE_NEXT_TIMER
        POP     IY
        POP     IX
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        EI
        RET


; Converts joystick bits 2-3 into a signed vector delta in DE.
DECODE_JOYSTICK_DELTA:
        LD      A,$FC
        LD      DE,$40FF
        BIT     2,B
        RET     NZ

        LD      DE,$C000
        NEG
        BIT     3,B
        RET     NZ

        XOR     A
        LD      D,A
        RET


MISSILE_COUNTER5_EXPIRED:
        LD      HL,PLAYER1_PROJECTILE_0
        LD      A,(PLAYER1_AIM_X)
        LD      C,$80
        CALL    ALLOCATE_ONE_PROJECTILE
        LD      HL,OSW0
        JR      READ_JOYSTICK
MISSILE_COUNTER6_EXPIRED:
        LD      HL,PLAYER2_PROJECTILE_0
        LD      A,(PLAYER2_AIM_X)
        LD      C,$90
        CALL    ALLOCATE_ONE_PROJECTILE
        LD      HL,OSW1
READ_JOYSTICK:
        LD      B,(HL)
UPDATE_MISSILE_VECTOR:
        CALL    DECODE_JOYSTICK_DELTA
        LD      (IX+VBDXL),D
        LD      (IX+VBDXH),E
        RET

MISSILE_JOYSTICK0_CHANGED:
        LD      IX,PLAYER1_PROJECTILE_0
        JR      UPDATE_MISSILE_VECTOR
MISSILE_JOYSTICK1_CHANGED:
        LD      IX,PLAYER2_PROJECTILE_0
        JR      UPDATE_MISSILE_VECTOR

; Finds an inactive block among one player's four interleaved projectile slots.
; On exhaustion it discards this routine's and its caller's return addresses.
FIND_FREE_VECTOR_BLOCK:
        LD      DE,PLAYER_VECTOR_STRIDE
TEST_FREE_VECTOR_BLOCK:
        PUSH    HL
        POP     IX
        BIT     7,(IX+VBSTAT)
        RET     Z

        ADD     HL,DE
        DJNZ    TEST_FREE_VECTOR_BLOCK
        POP     HL
        POP     HL
        RET
