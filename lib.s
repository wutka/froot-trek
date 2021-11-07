.segment "LIB"

semicolon .set $3b

RANDL .set      $A2
RANDH .set      $A3
RANDBIT .set    $A4

KBDCR .set $d011
KBD .set $d010

.include "lib.inc"

doprint:
   lda (PRTL),Y
    beq P2
    putchar
    clc
    inc PRTL
    bcc doprint
    inc PRTH
    bne doprint
P2: rts

putcharn:
    putchar
    dex
    bne putcharn
    rts

printhex:
    tax
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    lda hexdigits,y
    putchar
    txa
    and #$0f
    tay
    lda hexdigits,y
    putchar
    rts

printhexnolead:
    tax
    lsr a
    lsr a
    lsr a
    lsr a
    tay
    bne notzero
    lda #32
    putchar
    jmp seconddigit

notzero:
    lda hexdigits,y
    putchar

seconddigit:
    txa
    and #$0f
    tay
    lda hexdigits,y
    putchar
    rts

initrand:
    ldx #$65
    stx RANDL
    ldx #$02
    stx RANDH
    rts

rand:
    lda RANDL
    and #$02
    sta RANDBIT

    lda RANDH
    and #$02

    eor RANDBIT
    clc
    beq iszero
    sec   ; bit 1 ^ bit 9 = 1

iszero:
    ror RANDH
    ror RANDL
    rts

.export doprint, printhex, printhexnolead, putcharn
.export initrand, rand, hexdigits

hexdigits: .byte "01234567890ABCDEF"
