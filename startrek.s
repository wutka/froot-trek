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
    putch NEWLINE
    jsr init_galaxy
    jsr print_galaxy ; temporary
    jmp ESCAPE
    

init_galaxy:
    lda #0
    sta klingons  ; reset klingon count
    sta bases     ; reset starbase count
    ldx #64       ; 8x8 galaxy, 64 dells
@next_cell:
    jsr rand      ; compute random number for klingon count
    jsr rand
    lda RANDH
    cmp #$fa      ; 0xfae1 is approximately 0.98 in range 0-1
    bcc @try_95   ; if less, see if it is > 0.95
    bne @k3
    lda RANDL     ; if high byte was 0xfa, see if low byte >= 0xe1
    cmp #$e1
    bcc @try_95
@k3: lda #$60     ; set bits 5 and 6 in galaxy cell for cell klingon count
    sta galaxy,x
    lda #3        ; add 3 to total klingon count
    sed           ; use BCD for klingon count since it will be printed
    clc
    adc klingons
    cld
    sta klingons
    jmp @compute_bases
@try_95:
    lda RANDH     ; 0xf333 is approximately 0.95 in range 0-1
    cmp #$f3
    bcc @try_80
    bne @k2
    lda RANDL
    cmp #$33
    bcc @try_80   ; if less, see if it is > 0.80
@k2: lda #$40     ; set bit 6 in galaxy cell for cell klingon count
    sta galaxy,x
    lda #2        ; add 2 to total klingon count
    sed           ; use BCD for klingon count since it will be printed
    clc
    adc klingons
    sta klingons
    cld
    jmp @compute_bases
@try_80:
    lda RANDH     ; 0xcccc is approximately 0.80 in range 0-1
    cmp #$cc
    bcc @k0
    bne @k1
    lda RANDL
    cmp #$cc
    bcc @k1
    bne @k0       ; if less, there are no klingons here
@k1: lda #$20     ; set bit 5 in galaxg cell for cell klingon count
    sta galaxy, x
    lda #1        ; add 1 to total klingon count
    sed           ; use BCD for klingon count since it will be printed
    clc
    adc klingons
    cld
    sta klingons
    jmp @compute_bases
@k0: lda #0       ; no klingons in this cell
    sta galaxy, x
@compute_bases:
    jsr rand
    jsr rand
    lda RANDH
    cmp #$f5      ; 0xf5c2 is approximately 0.96 in the range 0-1
    bcc @compute_stars ; if less, no base here, compute stars
    bne @base
    lda RANDL
    cmp #$c2
    bcc @compute_stars
@base:
    lda #$10      ; set bit 4 in cell indicating a starbase is present
    clc
    adc galaxy,x
    sta galaxy,x
    lda #1        ; add 1 to total starbase count
    sed           ; use BCD for starbase count since it will be printed
    clc
    adc bases
    cld
    sta bases
    
@compute_stars:
    jsr rand
    jsr rand
    lda RANDL
    and #$07      ; use last byte for star count, in range 1-8
    clc           ; star count is lower 4 bits of galaxy cell
    adc #1
    clc
    adc galaxy,x
    sta galaxy,x

    dex
    bmi @init_done
    jmp @next_cell
@init_done:
    lda #$30      ; initialize stardate count to 30
    sta stardates

; make sure there is at least one starbase
    lda bases
    bne @baseok
    lda galaxy+21 ; place it at a fixed location
    ora #$10
    sta galaxy+21
    inc bases
@baseok:
    print destroy1
    lda klingons
    jsr printhexnolead
    print destroy2
    lda stardates
    jsr printhexnolead
    print destroy3
    lda bases
    jsr printhexnolead
    print destroy4
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
    putch NEWLINE
    rts
    
end:
    .byte 0
    
galaxy: .res 64,0
klingons: .byte 0
bases: .byte 0
stardates: .byte 0

destroy1: .byte "YOU MUST DESTROY ",0
destroy2: .byte " KLINGONS IN ",0
destroy3: .byte " STARDATES WITH ",0
destroy4: .byte " STARBASES", $0a, 0
