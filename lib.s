.segment "LIB"

.include "lib.inc"

doprint:
    lda (PRTL),Y
    beq P2
    putchar
    inc PRTL
    bne doprint
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

printhex4nolead:
    lda PRTH
    cmp #0
    beq @nofirst
    jsr printhexnolead
    cmp #$10
    bcc @nofirst
    lda PRTL
    jsr printhex
    rts

@nofirst:
    lda PRTL
    jsr printhexnolead
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
.export initrand, rand, hexdigits, printhex4nolead

hexdigits: .byte "0123456789ABCDEF"
