.segment "MAIN"

DASH .set $2d
PIPE .set $7c
NEWLINE .set $0d

SCRATCH .set $20

.macro putch ch
    lda #ch
    putchar
.endmacro

ESCAPE .set $FF1A

    .import initrand, rand, printhexnolead, putcharn, doprint, hexdigits

    .include "lib.inc"

    jsr initrand
mainloop:
    jsr init_galaxy
    jsr print_galaxy
    jmp ESCAPE
    

init_galaxy:
    lda #0
    sta klingons
    sta bases
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
@k3: lda #$60
    sta galaxy,x
    lda #3
    sed
    clc
    adc klingons
    cld
    sta klingons
    jmp @compute_bases
@try_95:
    lda RANDH
    cmp #$f3
    bcc @try_80
    bne @k2
    lda RANDL
    cmp #$33
    bcc @try_80
@k2: lda #$40
    sta galaxy,x
    lda #2
    sed
    clc
    adc klingons
    sta klingons
    cld
    jmp @compute_bases
@try_80:
    lda RANDH
    cmp #$cc
    bcc @k0
    bne @k1
    lda RANDL
    cmp #$cc
    bcc @k1
    bne @k0
@k1: lda #$20
    sta galaxy, x
    lda #1
    sed
    clc
    adc klingons
    cld
    sta klingons
    jmp @compute_bases
@k0: lda #0
    sta galaxy, x
@compute_bases:
    jsr rand
    jsr rand
    lda RANDH
    cmp #$f5
    bcc @compute_stars
    bne @base
    lda RANDL
    cmp #$c2
    bcc @compute_stars
@base:
    lda #$10
    clc
    adc galaxy,x
    sta galaxy,x
    lda #1
    sed
    clc
    adc bases
    cld
    sta bases
    
@compute_stars:
    jsr rand
    jsr rand
    lda RANDL
    and #$07
    clc
    adc #1
    clc
    adc galaxy,x
    sta galaxy,x

    dex
    beq init_done
    jmp @next_cell
init_done:
    rts

print_galaxy_cell:
    sta SCRATCH
    lsr
    lsr
    lsr
    lsr
    lsr
    and #7
    tay
    lda hexdigits,y
    putchar
    lda SCRATCH
    lsr
    lsr
    lsr
    lsr
    and #1
    tay
    lda hexdigits,y
    putchar
    lda SCRATCH
    and #$0f
    tay
    lda hexdigits,y
    putchar
    rts

print_galaxy:
    lda #$0a
    putchar
    ldx #0
printloop: lda galaxy,x
    jsr print_galaxy_cell
    lda #32
    putchar
    txa
    and #7
    cmp #7
    bne noret
    lda #$0a
    putchar
noret: inx
    cpx #64
    bne printloop
    print klingons_str
    lda klingons
    jsr printhexnolead
    putch NEWLINE
    print starbases_str
    lda bases
    jsr printhexnolead
    putch NEWLINE
    rts
    
end:
    .byte 0
    
galaxy: .res 64,0
klingons: .byte 0
bases: .byte 0
    
srs: .byte "    Short Range Scanner",0
lrs: .byte "Long Range Scanner", 0
energy_str: .byte "Energy:",0
shields_str: .byte "Shields:", 0
torpedoes_str: .byte "Torpedoes:", 0
engine_str: .byte "Engine:",0
impulse_str: .byte "Impulse",0
warp_str: .byte "Warp   ",0
klingons_str: .byte "Klingons: ",0
starbases_str: .byte "Star Bases: ", 0
