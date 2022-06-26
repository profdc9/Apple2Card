

;  zero page locations used
  movelo = $f8
  movehi = $f9
  romlo = $fa  ; rom hi
  romhi = $fb
  ioffset = $fc ; io space offset
  slotnum = $fd  ; slot number
  loclo = $fe  ; location lo
  lochi = $ff  ; location hi

  ; monitor subroutines
  home = $fc58
  outch = $fded
  rdkey = $fd0c
  dowait = $fca8

   .org  $2000
  ; origin for ProDOS system file

.macro aschi str
.repeat .strlen (str), c
.byte .strat (str, c) | $80
.endrep
.endmacro

start:
    jsr  home   ; clear the screen
    ldy  #<startmsg
    sty  loclo
    ldy  #>startmsg
    sty  lochi
    jsr  outmsg
getkey:
    jsr  rdkey     ; read a key
    cmp  #27+128
    bne  getkey1
    jmp  quitearly
getkey1:
    cmp  #'1'+128
    bcc  getkey
    cmp  #'7'+128+1
    bcs  getkey
    jsr  outch    ; output the digit
    and  #$07
    sta  slotnum
   
    pha                        ; store rom bank location
    ora  #$C0
    sta  romhi
    lda  #0
    sta  romlo
    pla                        ; store offset into io addresses
    asl  a
    asl  a
    asl  a
    asl  a
    ora  #$88
    sta  ioffset

    ldy  #<flashingnow           ; let them know flashing is beginning
    sty  loclo
    ldy  #>flashingnow
    sty  lochi
    jsr  outmsg

    ldx  ioffset
    lda  #$f8
    sta  $bffb,x                  ; store port B output, port C output in the control register

startflash:
    lda  #<romcontents            ; start copying at end of file
    sta  movelo
    lda  #>romcontents
    sta  movehi

    lda  #0                       ; start at this point in actual ROM
    sta  loclo
    sta  lochi

move64:
    lda  romlengthlo 
    cmp  #1
    bne  unlck
    lda  romlengthhi
    bne  unlck
    jsr  lock28c256
    jmp  writepg
unlck:
    jsr  unlock28c256
writepg:
    jsr  flashpg
    ldy  #0
writedat:
    lda  (movelo),y
    sta  (romlo),y
    iny
    cpy  #$40
    bne  writedat

    lda  movelo
    clc  
    adc  #$40
    sta  movelo
    lda  movehi
    adc  #$00
    sta  movehi

    lda  romlo
    clc
    adc  #$40
    sta  romlo

    lda  loclo
    clc  
    adc  #$40
    sta  loclo
    lda  lochi
    adc  #$00
    sta  lochi

    lda  #'.'+128
    jsr  outch     ; write out a period
    lda  #$f0
    jsr  dowait     ; wait for the write to finish

    lda  romlengthlo
    sec
    sbc  #1
    sta  romlengthlo
    lda  romlengthhi
    sbc  #0
    sta  romlengthhi

    lda  romlengthlo
    bne  move64
    lda  romlengthhi
    bne  move64

    lda  #0
    sta  lochi
    jsr  flashpg
	
complete:
    ldy  #<flashingcomplete
    sty  loclo
    ldy  #>flashingcomplete
    sty  lochi
    jsr  outmsg
waitenter:
    ldx  ioffset
    lda  #$fa
    sta  $bffb,x                 ; port B input, port C output in the control register
waitenter1:
    jsr  rdkey
    cmp  #13+128
    bne  waitenter1

    inc  $3f4      ; invalidate power up byte
    jsr  $bf00     ; quit to PRODOS
.byte  $65
.byte  <parmquit
.byte  >parmquit

quitearly:
    ldy  #<noflash
    sty  loclo
    ldy  #>noflash
    sty  lochi
    jsr  outmsg
    jmp  waitenter

parmquit:
.byte  4
.byte  0
.byte  0
.byte  0
.byte  0
.byte  0
.byte  0

flashpg:
    ldx  ioffset
    lda  lochi
    and  #$07
    sta  $bffa,x    ; store low 3 bits of bank in Pc0-PC2
    lda  lochi
    and  #$78
    lsr   a
    lsr   a
    lsr   a
    sta  $bff9,x    ; store upper 4 bits of bank in PB0-PB3
    rts

unlock28c256:
    lda  lochi
    pha
    lda  romlo
    pha
    lda  #0
    sta  romlo

    ldy  #$55         ; send $aa to $5555
    lda  #$55
    sta  lochi
    jsr  flashpg
    lda  #$AA
    sta  (romlo),y

    ldy  #$AA         ; send $55 to $2aaa
    lda  #$2A
    sta  lochi
    jsr  flashpg
    lda  #$55
    sta  (romlo),y

    ldy  #$55         ; send $80 to $5555
    lda  #$55
    sta  lochi
    jsr  flashpg
    lda  #$80
    sta  (romlo),y

    ldy  #$55         ; send $AA to $5555
    lda  #$55
    sta  lochi
    jsr  flashpg
    lda  #$AA
    sta  (romlo),y

    ldy  #$AA         ; send $55 to $2AAA
    lda  #$2A
    sta  lochi
    jsr  flashpg
    lda  #$55
    sta  (romlo),y

    ldy  #$55         ; send $20 to $5555
    lda  #$55
    sta  lochi
    jsr  flashpg
    lda  #$20
    sta  (romlo),y
    
    pla
    sta  romlo
    pla
    sta  lochi
    rts

lock28c256:
    lda  lochi
    pha
    lda  romlo
    pha
    lda  #0
    sta  romlo

    ldy  #$55         ; send $aa to $5555
    lda  #$55
    sta  lochi
    jsr  flashpg
    lda  #$AA
    sta  (romlo),y

    ldy  #$AA         ; send $55 to $2aaa
    lda  #$2A
    sta  lochi
    jsr  flashpg
    lda  #$55
    sta  (romlo),y

    ldy  #$55         ; send $A0 to $5555
    lda  #$55
    sta  lochi
    jsr  flashpg
    lda  #$A0
    sta  (romlo),y

    pla
    sta  romlo
    pla
    sta  lochi
    rts

outmsg:
    ldy  #0
outmsg1:
    lda  (loclo),y
    beq  outend
    jsr  outch
    iny
    bne  outmsg1
outend:
    rts

startmsg:
    aschi   "FLASH UTILITY"    
.byte    $8d
    aschi   "SHORT ALL JUMPERS JP2,JP3,JP4,JP6,"
.byte    $8d
    aschi   "JP7,JP8,JP9,JP10 TO FLASH."
.byte    $8d
    aschi   "ONLY SHORT JP2 FOR NORMAL USE."
.byte    $8d
    aschi   "ENTER SLOT NUMBER: (1-7,ESC QUIT) "
.byte    0

flashingnow:
.byte    $8d
    aschi   "FLASHING NOW!"
.byte    $8d
.byte    0

flashingcomplete:
.byte    $8d
    aschi   "FLASHING COMPLETE PRESS ENTER"
.byte    $8d
.byte    0

noflash:
.byte    $8d
    aschi   "DID NOT FLASH PRESS ENTER"
.byte    $8d
.byte    0

romlengthlo:
.byte    $08     ; length of rom in 64 byte increments (8 X 64 = 512 bytes)
romlengthhi:
.byte    $00    

romcontents:
                 ; rom contents get appended to this file

