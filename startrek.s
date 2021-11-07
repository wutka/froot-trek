.segment "MAIN"

DASH .set $2d
PIPE .set $7c
NEWLINE .set $0d

.macro putch ch
    lda #ch
    putchar
.endmacro

ESCAPE .set $FF1A

    .import initrand, rand, printhexnolead, putcharn, doprint

    .include "lib.inc"

    jsr initrand
mainloop:
    jsr init_galaxy
    jmp ESCAPE
    

init_galaxy:
    ldx #63
@next_cell:
    jsr rand
    jsr rand
    lda RANDH
    cmp #$fa
    bcc @try_95
    bne @k3
    lda RANDL
    cmp #$e1
    bcc @try_95
@k3: lda #3
    sta galaxy,x
    jmp @compute_bases
@try_95:
    lda RANDH
    cmp #$f3
    bcc @try_80
    bne @k2
    lda RANDL
    cmp #$33
    bcc @try_80
@k2: lda #2
    sta galaxy,x
    jmp @compute_bases
@try_80:
    lda RANDH
    cmp #$cc
    bcc @k0
    bne @k1
    lda RANDL
    clc
    cmp #$cc
    bcc @k1
    bne @k0
@k1: lda #1
    sta galaxy, x
    jmp @compute_bases
@k0: lda #0
    sta galaxy, x
@compute_bases:
    dex
    bpl @next_cell
    rts

galaxy: .res 64,0
    
srs: .byte "    Short Range Scanner",0
lrs: .byte "Long Range Scanner", 0
energy_str: .byte "Energy:",0
shields_str: .byte "Shields:", 0
torpedoes_str: .byte "Torpedoes:", 0
engine_str: .byte "Engine:",0
impulse_str: .byte "Impulse",0
warp_str: .byte "Warp   ",0
