
;temp variables becasue 6502 only has 3 registers
   uppage = $FD
;for relocatable code, address to jump to instead of JSR absolute + RTS
    knownRtsMonitor = $FF58

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

   .org  $C700
  ;code is relocatable
  ; but set to $c700 for
  ; readability

;ID bytes for booting and drive detection
idbytes:
    cpx  #$20    ;ID bytes for ProDOS and the
    ldy  #$00    ; Apple Autostart ROM
    cpx  #$03    ;
    ldx  #$3C    ;this one for older II's
    bne  boot
jumpbank:
    sta  $bffb,x ; this is called to switch between rom banks
boot:
    ldy  #0         ; boot it
    sty  buflo      ; zero out block numbers and buffer address
    sty  blklo
    sty  blkhi
    iny
    sty  command

    jsr  knownRtsMonitor   ; call known RTS to get high byte to call address from stack
    tsx
    lda  $0100,x
    sta  bufhi      ; address of beginning of rom 
    
    asl  a
    asl  a
    asl  a
    asl  a
    sta  unit       ; store unit number so Arduino knows what to load
    ora  #$88        ; add $88 to it so we can address from page $BF ($BFF8-$BFFB)
                     ; this works around 6502 phantom read
    tax

    lda  #$FA        ; set register A control mode to 2
    sta  $BFFB,x     ; write to 82C55 mode register (mode 2 reg A, mode 0 reg B)

    ldy  #<msg
writemsg:
    lda  (buflo),y
    beq  waitkey
    sta	 $6D0-<msg,y
    iny
    bne  writemsg

                    ; y is approximately $ff here
waitkey:
    lda  #$40       ; wait a little
    jsr  $fca8      ; do the wait
    lda  $c000      ; do we have a key
    bpl  nokey
    sta  $c010
    cmp  #13+128    ; see if its an enter key
    bne  nokey
    lda  #1         ; change ROM bank address line 1
    bne  jumpbank 
nokey:
    dey
    bne  waitkey

pushadr:
    lda  #$08       ; push return address on stack
    sta  bufhi
    pha
    tya             ; y = 0 from waitkey
    pha

start:
    lda  #$60
    sta  uppage
    jsr  uppage      ; call known RTS to get high byte to call address from stack
    tsx
    lda  $0100,x
    asl  a
    asl  a
    asl  a
    asl  a
    ora  #$88        ; add $88 to it so we can address from page $BF ($BFF8-$BFFB)
                     ; this works around 6502 phantom read
    tax

    lda  #$FA        ; set register A control mode to 2
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
    dey              ; y = 0 to y = $ff
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
    ldx  unit
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

msg:   aschi   "DAN ][ PRESS RTN"
endmsg:
.byte    0

; These bytes need to be at the top of the 256 byte firmware as ProDOS
; uses these to find the entry point and drive capabilities

.repeat	251-<endmsg
.byte 0
.endrepeat

.byte   $00,$00  ;0000 blocks = check status
.byte   $BF      ;status,read,write,format,2 volumes,removable
.byte  <start    ;low byte of entry

; this starts at $c700, page 2

page2:
;ID bytes for booting and drive detection
    cpx  #$20    ;ID bytes for ProDOS and the
    ldy  #$00    ; Apple Autostart ROM
    cpx  #$03    ;
    ldx  #$3C    ; this one for older II's
    bne  badpage ; why are we booting to this page?
jumpbank2:
    sta  $bffb,x ; this is called to switch between rom banks

badpage:
    ldy	 #<card1msg
writecard1msg:
    lda	 (buflo),y
    beq  getcard1key
    sta	 $750-<card1msg,y
    iny
    bne  writecard1msg

getcard1key:
    lda  $c000
    bpl  getcard1key
    sta  $c010
    cmp  #'!'+128
    bne  notex1
    sta  $750+20
    lda  #$ff
    bne  storevol1
notex1:
    cmp  #'0'+128
    bcc  getcard1key
    cmp  #'9'+128+1
    bcs  getcard1key
    sta  $750+20
    and  #$0f
storevol1:
    sta  blklo

    ldy	 #<card2msg
writecard2msg:
    lda	 (buflo),y
    beq  getcard2key
    sta	 $7D0-<card2msg,y
    iny
    bne  writecard2msg
insidejump:
    beq  jumpbank2    ; should never fall through here from previous instruction
    
getcard2key:
    lda  $c000
    bpl  getcard2key
    sta  $c010
    cmp  #'0'+128
    bcc  getcard2key
    cmp  #'9'+128+1
    bcs  getcard2key
    sta  $7D0+20
    and  #$0f
    sta  blkhi

    lda  #4          ; set command=4
    sta  command

    ldy	 #$ff        ; lets send the command bytes directly to the Arduino
    lda  #$ac        ; send this byte first as a magic byte
    bne  pcomsend
pcombyte:
    lda  command,y   ; get byte
pcomsend:
    sta  $BFF8,x     ; push it to the Arduino
pcombyte2:
    lda  $BFFA,x     ; get port C
    bpl  pcombyte2    ; wait until its received (OBFA is high)
    iny
    cpy  #$06
    bne  pcombyte     ; send next byte

pwaitresult:
    lda  $BFFA,x     ; wait until there's a byte available
    and  #$20  
    beq  pwaitresult
    
    lda  $BFF8,x     ; get the byte
    lda  #0
    beq  insidejump  ; try to reboot
card1msg:   aschi   "CARD 1 (0-9,!):"
end1msg:
.byte    0
card2msg:   aschi   "CARD 2 (0-9):"
end2msg:
.byte    0

.repeat	255-<end2msg
.byte 0
.endrepeat


