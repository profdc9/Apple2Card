; Sample Bootloader Code
; by DL Marks
; not done yet

INSTRUC = $F0
LOWBT   = $F1
HIGHBT  = $F2
RTSBYT  = $F3
OFFSET  = $F4
VOLDRIVE0 = $F5
VOLDRIVE1 = $F6
BLKBUF = $1000

COMMAND = $42
UNIT    = $43
BUFLO   = $44
BUFHI   = $45
BLKLO   = $46
BLKHI   = $47

HOME =   $FC58
PRHEX =  $FDE3
PRBYTE = $FDDA
RDKEY =  $FD0C

         .ORG $2000
		 
START:
         LDX #$70
         LDA #$20        ; store JSR at $F0
         STA INSTRUC
         LDA #$60        ; store RTS at $F3
         STA RTSBYT
         STX UNIT        ; store in unit number
         TXA             ; put unit in A register
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

         JSR HOME        ; clear screen
         JSR GETVOL      ; get volume number
         LDA VOLDRIVE0
         JSR PRBYTE
         LDA VOLDRIVE1
         JSR PRBYTE
         JSR RDKEY
         JSR RDKEY
         JMP REBOOT

BUFLOC:
         LDA #<BLKBUF    ; store buffer location    
         STA BUFLO
         LDA #>BLKBUF
         STA BUFHI
         RTS

READB:
         LDA #$01        ; read block
         STA COMMAND     ; store at $42
         JSR BUFLOC      ; store buffer location
         LDA #$04        ; which block (in this example $0004)
         STA BLKLO
         LDA #$00
         STA BLKHI
         JSR INSTRUC
         RTS

SETVOL:
         LDA #$06        ; set volume (alternate code)
         STA COMMAND
         JSR BUFLOC      ; dummy buffer location
         LDA VOLDRIVE0
         STA BLKLO
         LDA VOLDRIVE1
         STA BLKHI
         JSR INSTRUC
         RTS

GETVOL:
         LDA #$05        ; read block
         STA COMMAND     ; store at $42
         JSR BUFLOC      ; store buffer location
         JSR INSTRUC
         LDA BLKBUF
         STA VOLDRIVE0
         LDA BLKBUF+1
         STA VOLDRIVE1
         RTS

REBOOT:
         LDA #$00        ; store zero byte at $F1
         STA LOWBT
         JMP (LOWBT)     ; jump back and reboot       
