;  "Seawolf/Missile" (Videocade #2002) 
;  Programmed by Rick Spiece
;  Release in 1977
;  Cartridge for Bally/Astrocade Console
;
;  Version .002 - December 7, 2011
;     - First Public Release
;     - Binary Output matches byte-for-byte with original
;       cartridge release.
;     - Only the original one-day was spent working with
;       this file, but quite a lot was done.  It seems
;       worth sharing.  
;  Version .001 - July 29, 2011
;     - One day was spent disassembling this file 
;           
;
;  To assemble this Z-80 source code using ZMAC:
;  
;  zmac -d -o <outfile> -x <listfile> <filename>
;  
;  For example, assemble this Astrocade Z-80 ROM file:
;     
;  zmac -i -m -o seawolf.bin -x seawolf.lst seawolf.asm


INCLUDE "HVGLIB.H"  ; Home Video Game Library
     
        ORG   FIRSTC        ; FIRST address in Cartridge
                                
        DB    "U"           ; User Cartridge Sentinel

; O.S. Menu Data Structure

; Menu 1, Choice 1 - "Seawolf"
        DW    L2007         ; Link to Menu 1, Choice 2
        DW    L23BF         ; Address of "SEAWOLF" menu text
        DW    L2031         ; Jump here if "SEAWOLF" selected
        
; Menu 1, Choice 2 - "Missile"
L2007:  DW    MENUST        ; Link to Head of On-Board MENU STart
        DW    L2363         ; Address of "MISSILE" menu text
        DW    L200D         ; Jump here if "MISSILE" selected

; Missile Selected from Menu
L200D:  CALL  L204E
        EI      

        SYSTEM  INTPC            ;  UPI INTerPret with Context create

        DO      SETB             ;  UPI SET Byte
        DB      $40              ;  ... Data = 64
        DW      $4EC2            ;  ... Memory Address = 20162

        DO      SETW             ;  UPI SET Word
        DW      L23AF            ;  ... Data Word = 9135
        DW      $4EBF            ;  ... Memory Address = 20159

        DO      COLSET           ;  UPI COLors SET
        DW      L2320            ;  ... Table Address = 8992

        DO      FILL             ;  UPI FILL memory with data
        DW      $4B90            ;  ... Memory Address = 19344
        DW      $00C8            ;  ... Byte Count = 200
        DB      $FF              ;  ... Data = 255

L2025:  DO      SENTRY           ;  UPI SENse TRansition
        DW      ALKEYS           ;  ALl KEYS Keypad Mask

        DO      DOIT             ;  UPI DOIT table, branch to translation 
        DW      L22BA            ;  ... Table Address = 8890

        DO      DOIT             ;  UPI DOIT table, branch to translation 
        DW      L2748            ;  ... Table Address = 10056

        DO      MJUMP            ;  UPI Macro JUMP to interpreter 
        DW      L2025            ;  ... Macro Address = 8229


; Seawolf Selected from Menu
L2031:  CALL    L204E
        LD      A,$20
        OUT     ($15),A
        SYSTEM  INTPC            ;  UPI INTerPret with Context create

        DO      COLSET           ;  UPI COLors SET
        DW      L2324            ;  ... Table Address = 8996

        DO      SETW             ;  UPI SET Word
        DW      L23A5            ;  ... Data Word = 9125
        DW      $4EBF            ;  ... Memory Address = 20159

L2042:  DO      SENTRY           ;  UPI SENse TRansition
        DW      ALKEYS           ;  ALl KEYS Keypad Mask

        DO      DOIT             ;  UPI DOIT table, branch to translation handler
        DW      L22BA            ;  ... Table Address = 8890

        DO      DOIT             ;  UPI DOIT table, branch to translation handler
        DW      L229E            ;  ... Table Address = 8862

        DO      MJUMP            ;  UPI Macro JUMP to interpreter subroutine
        DW      L2042            ;  ... Macro Address = 8258


L204E:  SYSSUK  GETPAR           ;  UPI Get Game Parameter From User
        DW      TIMPMT           ;  Prompt is "TIME"
        DB      $83              ;  ... Digits = 131
        DW      $4F07            ;  ... Parameter Address = 20231

        DI      
        LD      HL,($4F07)
        LD      ($4FED),HL
        POP     HL
        LD      SP,$4EBF
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
        DW      $4EBF            ;  ... Memory Address = 20159
        DW      $0110            ;  ... Byte Count = 272
        DB      $00              ;  ... Data = 0

        DO      FILL             ;  UPI FILL memory with data
        DW      $4FDD            ;  ... Memory Address = 20445
        DW      $0006            ;  ... Byte Count = 6
        DB      $00              ;  ... Data = 0

        DO      SETB             ;  UPI SET Byte
        DB      $01              ;  ... Data = 1
        DW      $4FCB            ;  ... Memory Address = 20427

        DO      SETB             ;  UPI SET Byte
        DB      $02              ;  ... Data = 2
        DW      $4FCD            ;  ... Memory Address = 20429

        DO      SETW             ;  UPI SET Word
        DW      $1B01            ;  ... Data Word = 6913
        DW      $4FDD            ;  ... Memory Address = 20445

        DO      SETW             ;  UPI SET Word
        DW      $AAAA            ;  ... Data Word = 43690
        DW      $4EC3            ;  ... Memory Address = 20163

        DO      SETB             ;  UPI SET Byte
        DB      $01              ;  ... Data = 1
        DW      $4FF8            ;  ... Memory Address = 20472

        DONT    XINTC            ;  UPI eXit INTerpreter with Context

        LD      A,$23
        LD      I,A
        LD      A,$10
        OUT     ($0D),A
        IM      2
        RET     

; Call from Seawolf DOIT Table
; SF3 - Sentry, Flag bit 3 has changed

        LD      B,$04

; Call from Seawolf DOIT Table        
; SF4 - Sentry, Flag bit 4 has changed
; This call from the DOIT table calls right into the middle of 
;         LD      HL,$0806
; The SF4 call sees this as the first statement:  
;         LD      B,$08
; I've not seen this technique used before, but perhaps it is
; used to save a couple of bytes... or I disassembled this area
; wrong.
        LD      HL,$0806
        LD      HL,$4ECF
        LD      A,B
        CPL     
        AND     (HL)
        LD      (HL),A
        LD      E,$00
        LD      C,$08
        EXX     
        LD      B,$04
L20AE:  EXX     
        CALL    L20B9
        INC     E
        EXX     
        DJNZ    L20AE
L20B6:  LD      E,A
        LD      C,$28
L20B9:  LD      HL,$2318
        PUSH    DE
        LD      D,$00
        ADD     HL,DE
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        BIT     2,B
        JR      NZ,L20CC
        LD      A,$44
        ADD     A,E
        LD      E,A
L20CC   LD      HL,L23C7
        LD      A,B
        DI      
        OUT     ($19),A
        LD      A,C
        SYSTEM  WRITP            ;  UPI WRITE With Pattern Size Lookup

        EI      
        POP     DE
        RET     

; Seawolf/Missile DOIT Table 
; SKYD - Sentry, KeY is now Down       
        LD      C,B
        EX      AF,AF'
        LD      HL,$4ED1
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
        JR      L20F3
        LD      HL,$4ED1
        LD      C,$0B
        CALL    L214C
L20F3:  LD      D,$45
        LD      HL,($4ED2)
        LD      A,$04
        CALL    L2131
        LD      ($4ED2),HL
        RET     


; Missile DOIT Table
; SP1 - Sentry, POTentiometer 1 has changed
        LD      HL,$4ECD
        LD      A,B
        CPL     
        AND     $FC
        RRA     
        RRA     
        ADD     A,$52
        CP      $8E
        JR      C,L2112
        LD      A,$8E
L2112:  LD      B,(HL)
        LD      (HL),A
        CP      B
        RET     Z

        LD      D,$45
        LD      E,A
        JR      L2125
; Seawolf/Missile DOIT Table 
; SP1 - Sentry, POTentiometer 1 has changed
        LD      HL,$4ECD
        LD      C,$0C
        CALL    L214C
        LD      D,$4A
L2125:  LD      HL,($4ED4)
        LD      A,$08
        CALL    L2131
        LD      ($4ED4),HL
        RET     


L2131   PUSH    DE
        LD      DE,$0505
        DI      
        OUT     ($19),A
        XOR     A
        LD      B,A
        CP      H
        LD      A,$08
        JR      Z,L2143
        SET     6,H
        SYSTEM  BLANK            ;  UPI BLANK AREA

L2143:  POP     DE
        LD      HL,($4EBF)
        SYSTEM  WRITP            ;  UPI WRITE WITH PATTERN SIZE 

        EI      
        EX      DE,HL
        RET     


L214C:  LD      A,B
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

; Seawolf/Missile DOIT Table 
; SCT4 - Sentry, Counter-Timer 4 has counted down
        LD      IX,$4EDA
        LD      C,$05
        JR      L2167
                
; Seawolf/Missile DOIT Table
; SCT3 - Sentry, Counter-Timer 3 has counted down
        LD      IX,$4EF8
        LD      C,$0E
L2167:  SYSSUK  RANGED           ;  UPI RANGED Random Number
        DB      $00              ;  ... Cutoff = 0

        LD      DE,$6880
        BIT     3,A
        JR      NZ,L2173
        LD      D,$28
L2173:  BIT     4,A
        JR      Z,L2179
        SET     4,E
L2179:  AND     $03
        JR      NZ,L217E
        INC     A
L217E:  INC     A
        PUSH    BC
        LD      C,A
        ADD     A,E
        LD      E,A
        LD      B,$00
        LD      HL,$233A
        ADD     HL,BC
        POP     BC
        LD      B,(HL)
        LD      A,($4EC2)
        BIT     6,A
        JR      Z,L2194
        LD      B,$F0
L2194:  LD      A,(IX+$01)
        BIT     7,A
        JR      Z,L21AA
        BIT     5,A
        RET     NZ

        LD      D,(IX+$00)
        EXX     
        LD      DE,$000F
        ADD     IX,DE
        EXX     
        JR      L21B7
L21AA:  LD      A,(IX+$10)
        BIT     7,A
        JR      Z,L21B7
        BIT     5,A
        RET     NZ

        LD      D,(IX+$0F)
L21B7:  XOR     A
        BIT     7,(IX+$01)
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
        LD      (IX+$0B),C
        RET     


; Seawolf/Missile DOIT Table 
; SCT5 - Sentry, Counter-Timer 5 has counted down
        LD      A,($4ED0)
        LD      B,$04
        CALL    L20B6
        LD      A,($4ED1)
        LD      HL,$4F16
        LD      C,$80
        CALL    L223F
        LD      HL,$4ED0
        INC     (HL)
        LD      A,(HL)
        XOR     $04
        RET     NZ

        LD      (HL),A
        DEC     HL
        SET     2,(HL)
        LD      A,$03
        JR      L221D


; Call from Seawolf DOIT Table
; SCT6 -  Sentry, Counter-Timer 6 has counted down
        LD      A,($4ECE)
        LD      B,$08
        CALL    L20B6
        LD      A,($4ECD)
        LD      HL,$4F25
        LD      C,$90
        RRC     B
        CALL    L223F
        LD      HL,$4ECE
        INC     (HL)
        LD      A,(HL)
        XOR     $04
        RET     NZ

        LD      (HL),A
        INC     HL
        SET     3,(HL)
        LD      A,$05
L221D:  LD      HL,$4FDD
        OR      (HL)
        LD      (HL),A
        RET


; Seawolf/Missile DOIT Table         
; ST0 - Sentry, Trigger 0 for player 1 has changed
        LD      HL,$0402
        LD      IX,$0820

; Call from Seawolf/Missile DOIT Table        
; ST1 - Sentry, Trigger 1 for player 2 has changed
; This call from the DOIT table calls right into the middle of 
;         LD      IX,$0820
; The ST1 call sees this as the first statement:  
;         LD      HL,$0820
; I've not seen this technique used before, but perhaps it is
; used to save a couple of bytes... or I disassembled this area
; wrong.
        LD      A,B
        OR      A
        RET     Z

        LD      A,($4FF8)
        BIT     7,A
        RET     NZ

        LD      DE,$4ECF
        LD      A,(DE)
        AND     H
        RET     NZ

        LD      A,(DE)
        OR      L
        LD      (DE),A
        RET     
        
        
L223D:  LD      B,$01
L223F:  CALL    L27EF
        LD      (HL),$38
        INC     HL
        LD      (HL),C
        INC     HL
        LD      BC,$000B
        LD      DE,$241A
        EX      DE,HL
        LDIR    
        LD      (IX+$06),A
        LD      A,$FE
        LD      ($4EC1),A
        RET     


L2259:  LD      HL,$4EC2
        BIT     6,(HL)
        LD      HL,$2332
        JR      Z,L2265
        LD      L,$0E
L2265:  LD      D,$00
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
        JR      NZ,L2279
        LD      A,$0C
        JR      L2280
L2279:  LD      A,$04
        BIT     4,B
        JR      Z,L2280
        RLCA    
L2280:  OUT     ($19),A
        RET     

; Call from Seawolf DOIT Table 
; SCT2 - Sentry, Counter-Timer 2 has counted down
        LD      HL,$4ED7
        LD      DE,$0860
        JR      L2291

; Call from Seawolf DOIT Table
; SCT1 - Sentry, Counter-Timer 1 has counted down
        LD      HL,$4ED6
        LD      DE,$041C
L2291:  LD      (HL),$12
        LD      HL,L2328
        LD      C,D
        LD      D,$4F
        DI      
SYSTEM  STRDIS           ;  UPI STRing DISplay

        EI      
        RET     

; DOIT Table (for Seawolf)
L229E:  RC    SCT6, $21FA, $00   ; Sentry, Counter-Timer 6 has counted down
        RC    SCT5, $21D7, $00   ; Sentry, Counter-Timer 5 has counted down
        RC    SCT2, $2283, $00   ; Sentry, Counter-Timer 2 has counted down
        RC    SCT1, $228B, $00   ; Sentry, Counter-Timer 1 has counted down
        RC    SCT0, $2496, $00   ; Sentry, Counter-Timer 0 has counted down
        RC    SF4,  $209E, $00   ; Sentry, Flag bit 4 has changed
        RC    SF3,  $209B, $00   ; Sentry, Flag bit 3 has changed
        RC    SP0,  $20EB, $00   ; Sentry, POTentiometer 0 has changed        
        RC    SP1,  $211B, ENDx  ; Sentry, POTentiometer 1 has changed

; DOIT Table (for Missile or Seawolf)
L22BA:  RC    SCT7, $24E4, $00   ; Sentry, Counter-Timer 7 has counted down 
        RC    SCT4, $2159, $00   ; Sentry, Counter-Timer 4 has counted down
        RC    SCT3, $2161, $00   ; Sentry, Counter-Timer 3 has counted down
        RC    SF7,  $254B, $00   ; Sentry, Flag bit 7 has changed
        RC    SF1,  $25AC, $00   ; Sentry, Flag bit 1 has changed 
        RC    ST0,  $2223, $00   ; Sentry, Trigger 0 for player 1 has changed
        RC    ST1,  $2227, $00   ; Sentry, Trigger 1 for player 2 has changed
        RC    SSEC, $24E9, $00   ; Sentry, SEConds timer has counted down
        MC    SKYD, $20D9, ENDx  ; Sentry, KeY is now Down       

; Music Score (Called from $25A2)
L22D6:  DB    $88
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

; Music Score (Called from $2688)
L22FC:  DB    $B0
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
        DB    $C3
        DB    $F4
        DB    $22
        DB    $EB
        DB    $23
        DB    $5B
        DB    $27
        DB    $F3
        DB    $23
        DB    $03
        DB    $24
        DB    $11
        DB    $24
        DB    $1C
        DB    $4F
        DB    $1C
        DB    $53
        DB    $2E
        DB    $4F
        DB    $2E
        DB    $53

; Colors for Missile
L2320:  DB    $A2 ; - Green 
        DB    $5B ; - Red 
        DB    $08 ; - Blue 
        DB    $07 ; - White 

; Colors for Seawolf 
L2324:  DB    $07 ; - White
        DB    $55 ; - Purple-ish 
        DB    $7F ; - Yellow 
        DB    $F9 ; - Blue 

L2328:  DB    "LOAD",0  
        DB    $96
        DB    $01
        DB    $56
        DB    $00
        DB    $8B
        DB    $B6
        DB    $23
        DB    $97
        DB    $23
        DB    $6A
        DB    $23
        DB    $81
        DB    $23
        DB    $57
        DB    $23
        DB    $70
        DB    $80
        DB    $E0
        DB    $20
        DB    $55
        DB    $25
        DB    $7F
        DB    $7D
        DB    $7E
        DB    $7F
        DB    $CF
        DB    $20
        DB    $55
        DB    $25
        DB    $32
        DB    $4D
        DB    $4E
        DB    $4F
        DB    $AF
        DB    $20
        DB    $55
        DB    $25
        DB    $25
        DB    $47
        DB    $4F
        DB    $9F
        DB    $48
        DB    $04
        DB    $02

; Pattern (Small Boat in Seawolf)
        DB    $02, $04 ; 2 byte x 4 line pattern size
        DB    $00, $60 ; 00000000,01100000 - . . . . . . . . . * * . . . . .
        DB    $04, $70 ; 00000100,01110000 - . . . . . * . . . * * * . . . . 
        DB    $03, $FF ; 00000011,11111111 - . . . . . . * * * * * * * * * * 
        DB    $0F, $FE ; 00001111,11111110 - . . . . * * * * * * * * * * * . 

L2363:  DB    "MISSILE",$00
        DB    $01

; Pattern (Large Ship 1 - Without Gun Turrent)
        DB    $03, $05      ; 3 byte x 5 line pattern size
        DB    $04, $58, $80 ; 00000100,01011000,10000000 - . . . . . * . . . * . * * . . . * . . . . . . .
        DB    $04, $F8, $80 ; 00000100,11111000,10000000 - . . . . . * . . * * * * * . . . * . . . . . . .
        DB    $FC, $F8, $F0 ; 11111100,11111000,11110000 - * * * * * * . . * * * * * . . . * * * * . . . .
        DB    $FF, $FF, $E0 ; 11111111,11111111,11100000 - * * * * * * * * * * * * * * * * * * * . . . . .
        DB    $7F, $FF, $C0 ; 01111111,11111111,11000000 - . * * * * * * * * * * * * * * * * * . . . . . .

TIMPMT  DB    "TIME",$00
        DB    $00

; Pattern (Large Ship 2 - With Gun Turrent)
        DB    $03, $06      ; 3 byte x 6 line pattern size
        DB    $06, $C0, $00 ; 00000110,11000000,00000000 - . . . . . * * . * * . . . . . . . . . . . . . .
        DB    $06, $D9, $F8 ; 00000110,11011001,11111000 - . . . . . * * . * * . * * . . * * * * * * . . .
        DB    $4F, $FD, $C0 ; 01001111,11111101,11000000 - . * . . * * * * * * * * * * . * * * . . . . . .
        DB    $FF, $FF, $FE ; 11111111,11111111,11111110 - * * * * * * * * * * * * * * * * * * * * * * * . 
        DB    $FF, $FF, $FC ; 11111111,11111111,11111100 - * * * * * * * * * * * * * * * * * * * * * * . . 
        DB    $7F, $FF, $F8 ; 01111111,11111111,11111000 - . * * * * * * * * * * * * * * * * * * * * . . . 

        DB    $08
        DB    $00
        
; Pattern (Floating Mine in Seawolf)
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
L23A5:  DB    $02, $04 ; 2 byte x 4 line pattern size
        DB    $01, $C0 ; 00000001,11000000 - . . . . . . . * * * . . . . . .
        DB    $01, $C0 ; 00000001,11000000 - . . . . . . . * * * . . . . . .
        DB    $FF, $FF ; 11111111,11111111 - * * * * * * * * * * * * * * * *
        DB    $7F, $FF ; 01111111,11111111 - . * * * * * * * * * * * * * * * 
        
; Pattern (Player's Ship in Missile)
L23AF:  DB    $01, $05 ; 1 byte x 4 line pattern size
        DB    $08      ; 00001000 - . . . . * . . . 
        DB    $08      ; 00001000 - . . . . * . . .
        DB    $49      ; 01001001 - . * . . * . . *
        DB    $5D      ; 01011101 - . * . * * * . *
        DB    $7F      ; 01111111 - . * * * * * * *
        
        DB    $08
        DB    $00

; Pattern (Torpedo Fired by Sub)
        DB    $01, $05 ; 1 byte x 5 line pattern size
        DB    $C0      ; 11000000 - **......
        DB    $C0      ; 11000000 - **......
        DB    $C0      ; 11000000 - **......
        DB    $C0      ; 11000000 - **......
        DB    $C0      ; 11000000 - **......

L23BF:  DB    "SEAWOLF",$00

; Pattern (Torpedo in Seawolf)
L23C7:  DB    $02, $04  ; 2 bytes, 4 lines pattern size
        DB    $9F, $FC  ; 10011111,11111100 - * . . * * * * * * * * * * * . .  
        DB    $FF, $FE  ; 11111111,11111110 - * * * * * * * * * * * * * * * .
        DB    $9F, $FC  ; 10011111,11111100 - * . . * * * * * * * * * * * . .
        DB    $00, $00  ; 00000000,00000000 - . . . . . . . . . . . . . . . .

; Pattern (Explosion in Seawolf and Missile)
        DB    $02, $05  ; 2 bytes, 5 lines pattern size
        DB    $22, $22  ; 00100010,00100010 - . . * . . . * . . . * . . . * .
        DB    $88, $88  ; 10001000,10001000 - * . . . * . . . * . . . * . . .
        DB    $25, $10  ; 00100101,00010000 - . . * . . * . * . . . * . . . .
        DB    $2D, $C8  ; 00101101,11001000 - . . * . * * . * * * . . * . . .  
        DB    $0F, $F0  ; 00001111,11110000 - . . . . * * * * * * * * . . . .  

        DB    $09
        DB    $00
        DB    $01
        DB    $0A
        DB    $21
        DB    $88
        DB    $02
        DB    $20
        DB    $08
        DB    $10
        DB    $04
        DB    $40
        DB    $11
        DB    $84
        DB    $03
        DB    $00
        DB    $01
        DB    $04
        DB    $40
        DB    $40
        DB    $40
        DB    $E0
        DB    $04
        DB    $00
; Pattern (Large Plane, Facing Right)
        DB    $02, $06 ; 2 bytes, 6 lines pattern size
        DB    $C0, $00 ; 11000000,00000000 - * * . . . . . . . . . . . . . .
        DB    $E0, $70 ; 11100000,01110000 - * * * . . . . . . * * * . . . . 
        DB    $FF, $FE ; 11111111,11111110 - * * * * * * * * * * * * * * * .
        DB    $FF, $FF ; 11111111,11111111 - * * * * * * * * * * * * * * * *
        DB    $FF, $FE ; 11111111,11111110 - * * * * * * * * * * * * * * * .
        DB    $07, $80 ; 00000111,10000000 - . . . . . * * * * . . . . . . .

        DB    $04
        DB    $01
        DB    $02
        DB    $05
        DB    $C0
        DB    $00
        DB    $E0
        DB    $60
        DB    $FF
        DB    $F8
        DB    $FF
        DB    $FC
        DB    $7F
        DB    $F8
        DB    $0A
        DB    $01
; Pattern (Small Plane, Facing Right)
        DB    $01, $05 ; 1 byte, 5 lines pattern size
        DB    $80      ; 10000000 - * . . . . . . .
        DB    $CC      ; 11001100 - * * . . * * . .
        DB    $FE      ; 11111110 - * * * * * * * . 
        DB    $FF      ; 11111111 - * * * * * * * *
        DB    $7E      ; 01110111 - . * * * * * * .
 
        DB    $01
        DB    $00
        DB    $00
        DB    $00
        DB    $00
        DB    $01
        DB    $40
        DB    $FF
        DB    $00
        DB    $40
        DB    $01

L2425:  LD      HL,$4ED8
        DEC     (HL)
        JR      NZ,L2448
        LD      (HL),$14
        LD      L,$CF
        BIT     5,(HL)
        JR      Z,L243B
        RES     5,(HL)
        LD      HL,$4FDD
        SET     6,(HL)
        RET     
      
L243B   BIT     3,(HL)
        RET     Z

        LD      L,$D7
        DEC     (HL)
        RET     NZ

        LD      HL,$4FDE
        SET     4,(HL)
        RET     


L2448:  INC     HL
        DEC     (HL)
        RET     NZ

        LD      (HL),$14
        LD      L,$CF
        BIT     1,(HL)
        JR      Z,L245B
        RES     1,(HL)
        LD      HL,$4FDD
        SET     5,(HL)
        RET     

L245B:  BIT     2,(HL)
        RET     Z

        LD      L,$D6
        DEC     (HL)
        RET     NZ

        LD      HL,$4FDE
L2465:  SET     3,(HL)
        RET     


L2468:  LD      HL,$4FF8
        BIT     7,(HL)
        RET     NZ

        LD      L,$CA
        DEC     (HL)
        JR      NZ,L2487
        LD      (HL),$A8
        INC     HL
        DEC     (HL)
        RET     NZ

        LD      (HL),$03
        LD      A,($4EC2)
        BIT     6,A
        JR      Z,L2483
        LD      (HL),$02
L2483:  LD      L,$DD
        SET     4,(HL)
L2487:  LD      L,$CC
        DEC     (HL)
        RET     NZ

        LD      (HL),$88
        INC     HL
        DEC     (HL)
        RET     NZ

        LD      (HL),$03
        LD      L,$DD
        JR      L2465


; Call from Seawolf DOIT Table 
; SCT0 - Sentry, Counter-Timer 0 has counted down
        LD      HL,$4EC4
        RLC     (HL)
        LD      IX,$4FAC
        LD      DE,$3881
        LD      BC,$082E
        JR      NC,$24AD
        LD      C,$1C
        LD      IX,$4F8E
        CALL    L21B7
        JR      NZ,L24CA
        LD      (IX+$06),$05
        BIT     7,(IX+$10)
        JR      Z,L24CA
        LD      A,(IX+$15)
        CP      $37
        JR      C,$24C5
        LD      A,$B5
        ADD     A,$50
        LD      (IX+$06),A
L24CA:  EXX     
        LD      DE,$000F
        ADD     IX,DE
        EXX     
        CALL    L21B7
        RET     NZ

        LD      A,(IX-$09)
        CP      $37
        JR      C,L24DE
        LD      A,$B5
L24DE:  ADD     A,$50
        LD      (IX+$06),A
        RET     

; Seawolf/Missile DOIT Table 
; SCT7 - Sentry, Counter-Timer 7 has counted down 
        DI      
        SYSTEM  EMUSIC           ;  UPI End playing MUSIC

        SYSTEM  QUIT             ;  UPI QUIT cassette execution

; Seawolf/Missile DOIT Table
; SSEC - Sentry, SEConds timer has counted down
        LD      HL,$4EC2
        SET     7,(HL)
        SYSSUK  DISTIM           ;  UPI DISplay TIMe
        DB      $44              ;  ... X = 68
        DB      $50              ;  ... Y = 80
        DB      $8C              ;  ... Options = 140

        RES     7,(HL)
        SYSSUK  DECCTS           ;  UPI DECrement CT'S under 
        DB      $80              ;  ... Counters = 128

        LD      HL,$4FF8
        BIT     7,(HL)
        RET     NZ

        LD      L,$DC
        LD      (HL),$03
        RET     


L2503:  PUSH    BC
        LD      B,$04
        LD      E,$05
L2508:  LD      C,(HL)
        INC     HL
        BIT     7,(HL)
        JR      Z,L2543
        BIT     5,(HL)
        JR      NZ,L2543
        ADD     HL,DE
        LD      A,(HL)
        BIT     6,C
        JR      Z,L251C
        SUB     $88
        NEG     
L251C:  SUB     $0B
        JR      NC,L2521
        XOR     A
L2521:  SUB     (IX+$06)
        JR      NC,L2544
        NEG     
        EX      (SP),HL
        CP      H
        EX      (SP),HL
        JR      NC,L2544
        ADD     HL,DE
        LD      A,(HL)
        SUB     (IX+$0B)
        JR      NC,L2536
        NEG     
L2536:  EX      (SP),HL
        CP      L
        EX      (SP),HL
        JR      NC,L2545
        XOR     A
        SBC     HL,DE
        SBC     HL,DE
        DEC     HL
        POP     AF
        RET     
        
L2543:  ADD     HL,DE
L2544:  ADD     HL,DE
L2545:  ADD     HL,DE
        DEC     HL
        DJNZ    L2508
        POP     AF
        RET     


; Seawolf/Missile DOIT Table
; SF7 - Sentry, Flag bit 7 has changed
        LD      B,$08
        LD      IX,$4F07
L2551:  EXX     
        LD      DE,$000F
        ADD     IX,DE
        LD      A,(IX+$01)
        BIT     5,A
        JR      Z,L25A9
        RES     5,(IX+$01)
        PUSH    AF
        LD      A,$17
        CP      (IX+$0B)
        JR      NC,$2582
        LD      HL,$4F8E
        LD      BC,$160A
        CALL    L2503
        LD      A,B
        POP     BC
        OR      A
        JR      Z,L25A9
        LD      E,$07
        ADD     HL,DE
        SET     7,(HL)
        ADD     HL,DE
        DEC     HL
        LD      (HL),B
        JR      $259B
        LD      HL,$4EDA
        LD      BC,$1C07
        CALL    $2503
        LD      A,B
        POP     BC
        OR      A
        JR      Z,L25A9
        INC     HL
        LD      C,(HL)
        INC     E
        ADD     HL,DE
        SET     7,(HL)
        ADD     HL,DE
        LD      (HL),B
        CALL    L25D3
        LD      A,$01
        LD      HL,$4EC2
        SET     0,(HL)
        LD      HL,L22D6
        DI      
        SYSTEM  BMUSIC           ;  UPI BEGIN PLAYING MUSIC
        EI      
L25A9:  EXX     
        DJNZ    L2551

; Seawolf/Missile DOIT Table
; SF1 - Sentry, Flag bit 1 has changed 
        CALL    L25B7
        LD      DE,$0408
        LD      HL,$4EC9
        JR      L25BD
L25B7:  LD      DE,$0888
        LD      HL,$4ECB
L25BD:  LD      C,D
        LD      D,$50
        EXX     
        LD      HL,$4EC2
        SET     7,(HL)
        EXX     
        LD      B,$C4
        LD      IX,$020D
        SYSTEM  DISNUM           ;  UPI DISPLAY NUMBER
        EXX     
        RES     7,(HL)
        RET     

L25D3   LD      HL,$4EC9
        LD      B,(IX+$01)
        BIT     4,B
        JR      Z,L25DF
        INC     HL
        INC     HL
L25DF:  LD      A,$07
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


; On Collision with Torpedo and Ship in Seawolf?
L25F7:  LD      A,$07
        LD      DE,$0005
        PUSH    IX
        POP     HL
        AND     (IX+$01)
        JR      Z,L2612
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
           
L2612:  INC     HL
        RES     7,(HL)
        SET     5,(HL)
        ADD     HL,DE
        INC     HL
        RES     7,(HL)
        LD      HL,$4FDE
        SET     7,(HL)
        RET     

        
L2621:  DEC     HL
        BIT     7,(HL)
        RET     NZ

        XOR     A
        OR      D
        RET     Z

        INC     DE
        LD      A,(DE)
        BIT     5,A
        JP      NZ,L26B2
        CALL    L2259
        BIT     4,(IX+00H)
        JR      NZ,L2662
        SYSTEM  VWRITR           ;  UPI Vector WRITe Relative

        BIT     7,(IX+$07)
        JR      NZ,L25F7
        PUSH    HL
        LD      HL,$232C
        LD      A,(IX+$01)
        AND     $07
        JR      Z,L264E
        LD      HL,$2330
L264E:  SYSTEM  VECT             ;  UPI VECTor Move Coordinate 

        POP     HL
        BIT     3,(IX+$0C)
        JR      NZ,L265D
        BIT     3,(IX+$07)
        JR      Z,L269F
L265D:  RES     7,(IX+$01)
        RET     
        
        
L2662:  RES     4,(IX+$00)
        LD      A,(IX+$01)
        AND     $07
        CP      $02
        JR      C,L269F
        LD      B,A
        PUSH    HL
        LD      HL,$4EC2
        BIT     0,(HL)
        JR      NZ,L269E
        BIT     6,(HL)
        JR      NZ,L268E
        LD      A,$04
        CP      B
        JR      NZ,L269E
        PUSH    IX
        SYSSUK  BMUSIC           ;  UPI Begin playing MUSIC
        DW      $4DA0            ;  ... Music Stack = 19872
        DB      $C0              ;  ... Voices = 192
        DW      L22FC            ;  ... Score Address = 8956

        POP     IX
        JR      L269E
L268E:  LD      HL,$232F
        SYSTEM  EMUSIC           ;  UPI End playing MUSIC

        LD      DE,$0008
L2696:  ADD     HL,DE
        DJNZ    L2696
        LD      BC,$0818
        OTIR    
L269E:  POP     HL
L269F:  IN      A,($08)
        SYSTEM  VWRITR           ;  UPI Vector WRITe Relative

        LD      A,$07
        AND     (IX+$01)
        RET     NZ

        IN      A,($08)
        OR      A
        RET     Z

        SET     7,(IX+$07)
        RET     


L26B2:  EX      DE,HL
        DEC     HL
        DEC     (HL)
        JR      NZ,L26C0
        INC     HL
        RES     7,(HL)
        LD      HL,$4EC2
        RES     0,(HL)
        RET     

L26C0:  AND     $07
        CP      $01
        LD      E,(IX+$06)
        LD      D,(IX+$0B)
        JR      Z,$26D0
; Some weird (byte-saving?) coding here.  The code is different
; depending on where the Z80 jumps to.  Hopefully I'm disassembling this
; correctly... 
; If Zero then, then jump to $26D0:
; 26d0 21dd23    ld      hl,23ddh
; If not not zero run through code as normal.
        LD      HL,$23CF
        LD      IY,$23DD
        LD      A,$04
        BIT     4,(IX+$0D)
        JR      Z,L26DC
        RLCA    
L26DC:  OUT     ($19),A
        LD      A,$28
        SYSTEM  WRITR            ;  UPI WRITe RELATIVE
        RET     


L26E3:  LD      B,$0C            
        LD      HL,$4EC2
        BIT     7,(HL)
        INC     HL
        LD      C,(HL)
        RET     NZ

        PUSH    IX
        POP     HL
L26F0:  XOR     A
        OR      H
        JR      Z,L2703
        PUSH    HL
        LD      DE,$4FBB
        BIT     0,C
        JR      NZ,L26FE
        LD      E,$7F
L26FE:  SBC     HL,DE
        POP     HL
        JR      NZ,L270D
L2703:  LD      HL,$4EDB
        BIT     0,C
        JR      Z,L2711
        LD      HL,$4F07
L270D:  LD      DE,$0010
        ADD     HL,DE
L2711:  BIT     7,(HL)
        DEC     HL
        JR      Z,L272A
        BIT     0,C
        PUSH    HL
        POP     IX
        LD      A,(IX+$0B)
        JR      NZ,L2726
        CP      $12
        JR      C,L272D
        JR      L272A
L2726:  CP      $12
        JR      NC,L272D
L272A:  DJNZ    L26F0
        LD      H,B
L272D:  BIT     0,C
        JR      NZ,L2735
        LD      ($4EC5),HL
        RET     

        
L2735:  LD      ($4EC7),HL
        LD      HL,$4EC1
        LD      A,(HL)
        OR      A
        RET     Z

        SUB     $02
        LD      (HL),A
        INC     HL
        BIT     0,(HL)
        RET     NZ

        OUT     ($17),A
        RET     


; DOIT Table (Missile)
L2748:  RC    SCT6, $27CA, $00   ; Sentry, Counter-Timer 6 has counted down
        RC    SCT5, $27BA, $00   ; Sentry, Counter-Timer 5 has counted down
        RC    SP0,  $20DB, $00   ; Sentry, POTentiometer 0 has changed
        RC    SP1,  $2101, $00   ; Sentry, POTentiometer 1 has changed
        RC    SJ0,  $27E3, $00   ; Sentry, Joystick 0 for player 1 has changed
        RC    SJ1,  $27E9, ENDx  ; Sentry, Joystick 1 for player 2 has changed

L275B:  PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        PUSH    IX
        PUSH    IY
        LD      DE,($4EC7)
        LD      A,$24
        LD      HL,$4EC3
        RLC     (HL)
        JR      C,L2776
        LD      DE,($4EC5)
        LD      A,$A7
L2776:  PUSH    DE
        POP     IX
        OUT     ($0F),A
        CALL    L2621
        CALL    L2425
        CALL    L2468
        CALL    L26E3
        LD      HL,$4EDC
        BIT     0,C
        JR      NZ,L2794
        CALL    STIMER
        LD      HL,$4F54
L2794:  LD      DE,$000F
        LD      B,$08
L2799:  INC     (HL)
        ADD     HL,DE
        DJNZ    L2799
        POP     IY
        POP     IX
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        EI      
        RET

        
L27A7:  LD      A,$FC
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

        
; Missile DOIT Table        
; SCT5 - Sentry, Counter-Timer 5 has counted down
        LD      HL,$4F16
        LD      A,($4ED1)
        LD      C,$80
        CALL    L223D
        LD      HL,$4FE4
        JR      L27D8
; Missile DOIT Table
; SCT6 - Sentry, Counter-Timer 6 has counted down
        LD      HL,$4F25
        LD      A,($4ECD)
        LD      C,$90
        CALL    L223D
        LD      HL,$4FE5
L27D8:  LD      B,(HL)
L27D9:  CALL    L27A7
        LD      (IX+$03),D
        LD      (IX+$04),E
        RET     

; Missile DOIT Table
; SJ0 - Sentry, Joystick 0 for player 1 has changed
        LD      IX,$4F16
        JR      L27D9
; Missile DOIT Table
; SJ1 - Sentry, Joystick 1 for player 2 has changed
        LD      IX,$4F25
        JR      L27D9
L27EF:  LD      DE,$001E
L27F2:  PUSH    HL
        POP     IX
        BIT     7,(IX+$01)
        RET     Z

        ADD     HL,DE
        DJNZ    L27F2
        POP     HL
        POP     HL
        RET     
