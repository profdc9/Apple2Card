
;temp variables becasue 6502 only has 3 registers
	uppage = $FE
	regoffset = $FF   

;ProDOS defines
  command = $42   ;ProDOS command
  unit  = $43  ;7=drive 6-4=slot 3-0=not used
  buflo = $44  ;low address of buffer
  bufhi = $45  ;hi address of buffer
  blklo = $46  ;low block
  blkhi = $47  ;hi block
  ioerr = $27  ;I/O error code
  nodev = $28  ;no device connected
  wperr = $2B  ;write protect error

;for relocatable code, address to jump to instead of JSR absolute + RTS
    knownRts   = $FF58

   .org  $C700
  ;code is relocatable
  ; but set to $c700 for
  ; readability

;ID bytes for booting and drive detection
    cpx  #$20    ;ID bytes for ProDOS and the
    ldy  #$00    ; Apple Autostart ROM
    cpx  #$03    ;
    cpx  #$3C    ;this one for older II's

    sty  buflo      ;zero out block numbers and buffer address
    sty  blklo
    sty  blkhi
    iny
    sty  command

    jsr  knownRts   ; call known RTS to get high byte to call address from stack
    tsx
    lda  $0100,x
    sta  bufhi      ; address of beginning of rom 
    
    asl  a
    asl  a
    asl  a
    asl  a
    sta  unit       ; store unit number so Arduino knows what to load
    
    ldy	 #<msg
writemsg:
    lda	 (buflo),y
    sta	 $7D0-<msg,y
    beq  pushadr
    iny
    bne  writemsg

pushadr:
    lda  #$08       ; push return address on stack
    sta  bufhi
    pha
    lda  #$00
    pha

start:
    jsr  knownRts   ; call known RTS to get high byte to call address from stack
    tsx
    lda  $0100,x
    asl  a
    asl  a
    asl  a
    asl  a
    ora  #$88        ; add $88 to it so we can address from page $BF ($BFF8-$BFFB)
                     ; this works around 6502 phantom read
    tax

    lda  $BFFB,x     ; set register A control mode to 2
    ora  #$c0    
    sta  $BFFB,x     ; write to 82C55 mode register (mode 2 reg A, mode 0 reg B)

    ldy	 #$ff        ; lets send the command bytes directly to the Arduino
    lda  #$ac        ; send this byte first as a magic byte
    bne  comsend
combyte:
    lda  command,y   ; get byte
comsend:
    sta  $BFF8,x     ; push it to the Arduino
combyte2:
    lda  $BFFA,x     ; get port C
    bpl  combyte2    ; wait until its received (OBFA is high)
    iny
    cpy  #$06
    bne  combyte     ; send next byte

waitresult:
    lda  $BFFA,x     ; wait until there's a byte available
    and  #$20  
    beq  waitresult
    
    lda  $BFF8,x     ; get the byte
    beq  noerror     ; yay, no errors!  can process the result
    sec              ; pass the error back to ProDOS
    rts
            
noerror:
    sta  uppage      ; keep track if we are in upper page (store 0 in uppage)
    tay              ; (store 0 in y)
    lda  command
    bne  notstatus   ; not a status command
    
    ldx  #$FF        ; report $FFFF blocks 
    ldy  #$FF   
    clc
    rts
    
notstatus:
    cmp  #$01     
    bne  notread     ; not a read command
readbytes:
    lda  $BFFA,x     ; wait until there's a byte available
    and  #$20
    beq  readbytes
    lda  $BFF8,x     ; get the byte
    sta  (buflo),y   ; store in the buffer
    iny            
    bne  readbytes   ; get next byte to 256 bytes
    ldy  uppage
    bne  exit512     ; already read upper page
    inc  bufhi
    inc  uppage
    bne  readbytes
exit512:
    dec  bufhi       ; quit with no error
quitok:
    lda  #$00
    clc
    rts                   
     
notread:              
    cmp  #$02         ; assume its an allowed format if not these others
    bne  quitok 
writebytes:
    lda  (buflo),y    ; write a byte to the Arduino
    sta  $BFF8,x      
waitwrite:
    lda  $BFFA,x      ; wait until its received
    bpl  waitwrite    
    iny
    bne  writebytes
    ldy  uppage
    bne  exit512     ; already wrote upper page
    inc  bufhi
    inc  uppage
    bne  writebytes
    
;macro for string with high-bit set
.macro aschi str
.repeat .strlen (str), c
.byte .strat (str, c) | $80
.endrep
.endmacro

msg:   aschi   "SD INTERFACE BY DL MARKS"
end:
.byte    0

; These bytes need to be at the top of the 256 byte firmware as ProDOS
; uses these to find the entry point and drive capabilities

.repeat	251-<end
.byte 0
.endrepeat

.byte   $00,$00  ;0000 blocks = check status
.byte   $A7      ;bit 0=read 1=status
.byte  <start    ;low byte of entry
