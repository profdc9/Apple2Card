

;  zero page locations used
  loclo = $fe
  lochi = $ff 
  lowdev = $fc
  highdev = $fd

; monitor subroutines
  home = $fc58
  outch = $fded
  rdkey = $fd0c
  dowait = $fca8
  monitor = $ff59

   .org  $2000
; origin for ProDOS system block
  lastdev = $bf30
  drivertb = $bf10
  countdev = $bf31
  listdev = $bf32

  blankdevlo = drivertb
  blankdevhi = drivertb+1


.macro aschi str
.repeat .strlen (str), c
.byte .strat (str, c) | $80
.endrep
.endmacro

start:
    jmp  start1
confbt:
    .byte 0
slotbt:
    .byte 0
interactive:
    .byte 0
devrtlo:
    .byte 0
devrthi:
    .byte 0
driverofs:
    .byte 0
start1:
    lda  confbt
    bne  addvols

    inc  interactive

    jsr  home   ; clear the screen

    ldy  #<startmsg
    sty  loclo
    ldy  #>startmsg
    sty  lochi
    jsr  outmsg

    ldy  #<getconf
    sty  loclo
    ldy  #>getconf
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
    cmp  #'3'+128+1
    bcs  getkey
    jsr  outch    ; output the digit
    and  #$07
    sta  confbt

addvols:
    lda  interactive
    beq  addvols1
    ldy  #<addvolsmsg
    sty  loclo
    ldy  #>addvolsmsg
    sty  lochi
    jsr  outmsg

addvols1:
    lda  slotbt
    bne  haveslot
    lda  lastdev
    sta  slotbt

haveslot:
    lda  slotbt
    and  #$f0
    lsr  a
    lsr  a
    lsr  a
    sta  driverofs
    tax
    lda  drivertb,x
    sta  devrtlo
    lda  drivertb+1,x
    sta  devrthi

    lda  confbt
    cmp  #1
    bne  notconf1
    ldx  #1
    ldy  #8
    jsr  confrange
notconf1:
    lda  confbt
    cmp  #2
    bne  notconf2
    ldx  #9
    ldy  #16
    jsr  confrange
notconf2:
    lda  confbt
    cmp  #3
    bne  notconf3
    ldx  #1
    ldy  #8
    jsr  confrange
    ldx  #9
    ldy  #16
    jsr  confrange
notconf3:
quitearly:
    lda  interactive
    beq  justquit
    ldy  #<endmsg
    sty  loclo
    ldy  #>endmsg
    sty  lochi
    jsr  outmsg
endkey:
    jsr  rdkey
    cmp  #$8d
    bne  endkey
justquit:
    inc  $3f4      ; invalidate power up byte
    jsr  $bf00     ; quit to PRODOS
.byte  $65
.byte  <parmquit
.byte  >parmquit

parmquit:
.byte  4
.byte  0
.byte  0
.byte  0
.byte  0
.byte  0
.byte  0

confrange:
  stx  lowdev
  sty  highdev
addev:
  lda  countdev    ; active devices already full
  cmp  #13
  bcs  quitconf
  txa
  cmp  highdev
  bcs  quitconf    ; reached maximum device to scan
  asl  a
  tay
  lda  drivertb,y  ; check to see if the slot has no device
  cmp  blankdevlo
  bne  nextslot
  lda  drivertb+1,y
  cmp  blankdevhi
  bne  nextslot
addslot:
  lda  devrtlo
  sta  drivertb,y
  lda  devrthi
  sta  drivertb+1,y
  inc  countdev
  ldy  countdev
  txa
  asl  a
  asl  a
  asl  a
  asl  a
  ora  #$0b
  sta  listdev,y
  lda  interactive
  beq  nextslot
  lda  #'S'+128
  jsr  outch
  txa
  and  #$07
  ora  #128+48
  jsr  outch 
  lda  #'D'+128
  jsr  outch
  txa
  and  #$08
  lsr  a
  lsr  a
  lsr  a
  clc
  adc  #128+49
  jsr  outch
  lda  #' '+128
  jsr  outch
nextslot:
  inx
  jmp  addev
quitconf:
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
    aschi   "DAN ][ CONFIGURE VOLUMES"
.byte    $8d
.byte    0

endmsg:
.byte    $8d
    aschi   "PRESS RETURN"
.byte    $8d
.byte    0

addvolsmsg:
.byte    $8d
    aschi   "ADDING VOLUMES..."
.byte    $8d
.byte    0

getconf:
 .byte   $8d
    aschi   "1 = CONFIGURE SLOT 1 VOLUMES"
.byte    $8d
    aschi   "2 = CONFIGURE SLOT 2 VOLUMES"
.byte    $8d
    aschi   "3 = CONFIGURE SLOT 1 & 2 VOLUMES"
.byte    $8d
    aschi   "ESC ABORT"
.byte    $8d
    aschi   "SELECTION: "
.byte    0


