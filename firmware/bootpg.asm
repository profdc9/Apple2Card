; Sample Bootloader Code
; by DL Marks
; not done yet

INSTRUC = $F0
LOWBT   = $F1
HIGHBT  = $F2
RTSBYT  = $F3
VOLDRIVE0 = $F5
VOLDRIVE1 = $F6
GVOLDRIVE0 = $F7
GVOLDRIVE1 = $F8
LENGTH = $F9
BLKBUF = $1000

COMMAND = $42
UNIT    = $43
BUFLO   = $44
BUFHI   = $45
BLKLO   = $46
BLKHI   = $47

CH = $24
CV = $25

HOME =   $FC58
PRHEX =  $FDE3
PRBYTE = $FDDA
RDKEY =  $FD0C
COUT  =  $FDED
VTAB =   $FC22
SETVID = $FE93
SETKBD = $FE89

         .ORG $800

START:
         NOP
         LDA #$20
         STA INSTRUC
         LDA #$60        ; store RTS at $F3
         STA RTSBYT
         LDA UNIT        ; put unit in A register
         LSR A           ; shift to lower nibble
         LSR A
         LSR A
         LSR A
         AND #$07        ; just in case we booted from drive 2 ?
         ORA #$C0        ; make high nibble $C0
         STA HIGHBT      ; store high byte in memory location
         LDY #$00        ; store zero in low byte
         STY LOWBT
         DEY             ; make zero a $FF
         LDA (LOWBT),Y   ; get low byte of address
         STA LOWBT       ; place at low byte

         JSR SETVID      ; set to IN#0/PR#0 just in case
         JSR SETKBD
         JSR HOME        ; clear screen
         JSR GETVOL      ; get volume number

READUNIT:
         LDA #0          ; use screen row to store drive number (cheezy)
         STA CV
UNITLOOP:
         JSR VTAB

         LDA CV          ; set both drives to location
         STA VOLDRIVE0
         STA VOLDRIVE1
         JSR SETVOL

         LDA #0          ; start at column 0
         STA CH
         LDA CV          ; print hex digit for row
         JSR PRHEX
         INC CH          ; skip space
         JSR READB       ; read a block from drive 0
         JSR DISPNAME    ; display name

         LDA #20         ; start at column 20
         STA CH
         LDA CV
         JSR PRHEX
         INC CH
         LDA UNIT
         ORA #$80
         STA UNIT        ; set high bit to get drive 1
         JSR READB       ; read block
         JSR DISPNAME
         LDA UNIT        ; clear high bit
         AND #$7F
         STA UNIT

         INC CV          ; go to next row/volume
         LDA CV
         CMP #$10
         BCC UNITLOOP

VANITY:  
         LDA #0
         STA CH
         LDA #18
         STA CV
         JSR VTAB
         LDX #(VOLSEL-MSGS)
         JSR DISPMSG

DISPCUR: 
         JSR CARDMS0
         LDA #10
         STA CH
         LDA GVOLDRIVE0
         JSR DVHEX

         LDA #20
         STA CH
         JSR CARDMS1
         LDA #30
         STA CH 
         LDA GVOLDRIVE1
         JSR DVHEX

GETVL:
         LDA #10
         STA CH
         JSR GETHEX
         STA VOLDRIVE0
         JSR DVHEX
         LDA #30
         STA CH
         JSR GETHEX
         STA VOLDRIVE1
         JSR DVHEX

         JSR SETVOLW
         JMP REBOOT

ABORT:
         LDA GVOLDRIVE0
         STA VOLDRIVE0
         LDA GVOLDRIVE1
         STA VOLDRIVE1
         JSR SETVOL
         PLA
         PLA
         JMP REBOOT

GETHEX:  
         JSR RDKEY
         CMP #27+128
         BEQ ABORT
         CMP #'!'+128   ; is !
         BEQ SPCASE
         CMP #'a'+128
         BCC NOLOWER
         SEC
         SBC #$20 
NOLOWER:
         CMP #'A'+128
         BCC NOLET
         CMP #'F'+128+1
         BCC ISLET
NOLET:   CMP #'0'+128
         BCC GETHEX
         CMP #'9'+128+1
         BCS GETHEX
         AND #$0F
         RTS
ISLET:
         SEC
         SBC #7
         AND #$0F
         RTS
SPCASE:
         LDA #$FF
         RTS

DVHEX:   CMP #$FF
         BEQ DSPEC
         JMP PRHEX
DSPEC: 
         LDA #'!'+128
         JMP COUT

DISPNAME:
         LDX #0
         BCS NOHEADER    ; didn't read a sector
         LDA BLKBUF+5    ; if greater than $80 not a valid ASCII
         BMI NOHEADER
         LDA BLKBUF+4    ; look at volume directory header byte
         AND #$F0
         CMP #$F0
         BNE NOHEADER
         LDA BLKBUF+4
         AND #$0F
         BEQ NOHEADER
         STA LENGTH
DISPL:
         LDA BLKBUF+5,X
         ORA #$80
         JSR COUT
         INX
         CPX LENGTH
         BNE DISPL
         RTS
NOHEADER:
         JMP DISPMSG

.MACRO   ASCHI STR
.REPEAT  .STRLEN (STR), C
.BYTE    .STRAT (STR, C) | $80
.ENDREP
.ENDMACRO

MSGS:

NOHDR:     
         ASCHI   "<NO VOLUME>"
NOHDRE:
.BYTE 0

CARDMSG:     
         ASCHI   "CARD 1:"
CARDMSGE:
.BYTE 0

VOLSEL:     
         ASCHI   "DAN ][ VOLUME SELECTOR"
		 .BYTE   13+128
VOLSELE:
.BYTE 0

CARDMS1: LDA #'2'+128
         STA CARDMSG+5
CARDMS0:
         LDX #(CARDMSG-MSGS)
         JMP DISPMSG

DISPMSG: LDA MSGS,X
         BEQ RTSL
         JSR COUT
         INX
         BNE DISPMSG

BUFLOC:
         LDA #<BLKBUF    ; store buffer location    
         STA BUFLO
         LDA #>BLKBUF
         STA BUFHI
RTSL:    RTS

READB:
         LDA #$01        ; read block
         STA COMMAND     ; store at $42
         JSR BUFLOC      ; store buffer location
         LDA #$02        ; which block (in this example $0002)
         STA BLKLO
         LDA #$00
         STA BLKHI
         JMP INSTRUC

SETVOLW: LDA #$07        ; set volume but write to EEPROM
         BNE SETVOLC
SETVOL:
         LDA #$06        ; set volume dont write to EEPROM
SETVOLC:
         STA COMMAND
         JSR BUFLOC      ; dummy buffer location
         LDA VOLDRIVE0
         STA BLKLO
         LDA VOLDRIVE1
         STA BLKHI
         JMP INSTRUC

GETVOL:
         LDA #$05        ; read block
         STA COMMAND     ; store at $42
         JSR BUFLOC      ; store buffer location
         JSR INSTRUC
         LDA BLKBUF
         STA GVOLDRIVE0
         LDA BLKBUF+1
         STA GVOLDRIVE1
         RTS

REBOOT:
         LDA #$00        ; store zero byte at $F1
         STA LOWBT
         JMP (LOWBT)     ; jump back and reboot       
