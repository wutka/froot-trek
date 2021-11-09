.segment "MAIN"

DASH .set $2d
PIPE .set $7c
NEWLINE .set $0d

SCRATCH .set $20
SECT_STARS    .set $21
SECT_KLINGONS .set $22
SECT_BASES    .set $23

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
    jsr init_enterprise
    jsr init_sector

commandloop:
    print command
    getch
    and #$7f
    cmp #$30  ; 0
    bne @check1
    jmp setcourse
@check1:
    cmp #$31
    bne @check2
    jmp srs
@check2:
    cmp #$32
    bne @check3
    jmp lrs
@check3:
    cmp #$33
    bne @check4
    jmp firephasers
@check4:
    cmp #$34
    bne @check5
    jmp firetorps
@check5:
    cmp #$35
    bne @check6
    jmp shieldcontrol
@check6:
    cmp #$36
    bne @check7
    jmp damagecontrol
@check7:
    cmp #$37
    bne @check8
    jmp librarycomputer
@check8:
    cmp #$38
    bne showhelp
    jmp endcontest

showhelp:
    print help
    jmp commandloop

setcourse:
    jmp commandloop

srs:
    jmp commandloop

lrs:
    jmp commandloop

firephasers:
    jmp commandloop

firetorps:
    jmp commandloop

shieldcontrol:
    jmp commandloop

damagecontrol:
    jmp commandloop

librarycomputer:
    jmp commandloop

endcontest:
    jmp ESCAPE


;    jsr print_sector

    jmp ESCAPE
    

init_galaxy:
    lda #0
    sta klingons  ; reset klingon count
    sta bases     ; reset starbase count
    ldx #63       ; 8x8 galaxy, 64 dells
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

init_enterprise:
    lda #$00
    sta enterprise_data+energy_L
    sta enterprise_data+shields_L
    sta enterprise_data+shields_H
    lda #$30
    sta enterprise_data+energy_H
    lda #$10
    sta enterprise_data+torpedoes
    jsr rand
    lda RANDL
    and #$3f
    sta enterprise_data+loc
    rts

init_sector:
    ldx #63
    lda #0
@sectorclear:
    sta sector,x
    dex
    bpl @sectorclear

    lda enterprise_data+loc
    tax
    lda galaxy,x
    tax
    lsr
    lsr
    lsr
    lsr
    and #1
    sta SECT_BASES
    txa
    lsr
    lsr
    lsr
    lsr
    lsr
    and #3
    sta SECT_KLINGONS

    txa
    and #7
    sta SECT_STARS
    tax
@starloop:
    jsr rand
    lda RANDL
    and #63
    tax
    lda sector,x
    bne @starloop
    lda #sect_star
    sta sector,x
    dec SECT_STARS
    bne @starloop

    lda SECT_KLINGONS
    beq @check_for_base

    tax
    lda enterprise_data+shields_H
    cmp #$02
    bcs @klingloop
    bne @danger
    cmp #$00
    beq @klingloop
@danger:
    print combat

@klingloop:
    jsr rand
    lda RANDL
    and #63
    tax
    lda sector,x
    bne @klingloop
    lda #sect_kling
    sta sector,x
    dec SECT_KLINGONS
    bne @klingloop

@check_for_base:
    lda SECT_BASES
    beq @basedone

@baseloop:
    jsr rand
    lda RANDL
    and #63
    tax
    lda sector,x
    bne @baseloop
    lda #sect_base
    sta sector,x
    dec SECT_BASES
    bne @baseloop

@basedone:
@entloop:
    jsr rand
    lda RANDL
    and #63
    tax
    lda sector,x
    bne @entloop
    txa
    sta enterprise_data+sectloc
    lda #sect_ent
    sta sector,x

    rts

print_sector:
    ldx #0
sectrow:
    lda sector,x
    asl
    asl
    clc
    adc #<sect_image
    sta PRTL
    lda #0
    adc #>sect_image
    sta PRTH
    ldy #0
    jsr doprint
    txa
    and #7
    cmp #7
    bne nocr
    putch NEWLINE

nocr:
    inx
    cpx #64
    bne sectrow
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

end:
    .byte 0
    

galaxy      .set $400
klingons    .set galaxy+64
bases       .set klingons +1
stardates   .set bases+1
enterprise_data          .set stardates+1
loc         .set 0
energy_L    .set 1
energy_H    .set 2
shields_L   .set 3
shields_H   .set 4
torpedoes   .set 5
sectloc     .set 6

klingon_data .set enterprise_data+7
kloc        .set 0
kshields_L  .set 1
kshields_H  .set 2

sector      .set klingon_data + 9  ; skip 3 bytes * 3 klingons

sect_ent   .set 1
sect_kling .set 2
sect_base  .set 3
sect_star  .set 4

sect_image:
nothing:    .byte "   ",0
ent_ship:   .byte "-_=",0
kling_ship: .byte "<o>",0
starbase:   .byte ">I<",0
star:       .byte " * ",0


destroy1: .byte "YOU MUST DESTROY ",0
destroy2: .byte " KLINGONS IN ",0
destroy3: .byte " STARDATES WITH ",0
destroy4: .byte " STARBASES", $0a, 0
combat: .byte "COMBAT AREA      CONDITION RED",$0a
        .byte "   SHIELDS DANGEROUSLY LOW",$0a,0
command: .byte "COMMAND:",0
help:   .byte $0a
        .byte "  0 = SET COURSE", $0a
        .byte "  1 = SHORT RANGE SENSOR SCAN", $0a
        .byte "  2 = LONG RANGE SENSOR SCAN", $0a
        .byte "  3 = FIRE PHASERS", $0a
        .byte "  4 = FIRE PHOTON TORPEDOES",$0a
        .byte "  5 = SHIELD CONTROL", $0a
        .byte "  6 = DAMAGE CONTROL REPORT", $0a
        .byte "  7 = CALL ON LIBRARY COMPUTER", $0a
        .byte "  8 = END THE CONTEST", $0a, $0a, 0
