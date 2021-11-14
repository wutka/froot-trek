.segment "MAIN"

DASH .set $2d
PIPE .set $7c
NEWLINE .set $0d

SCRATCH .set $20
SECT_STARS    .set $21
SECT_KLINGONS .set $22
SECT_BASES    .set $23

COURSE .set 24
SPEED   .set 25

RND99 .set 26
EDGEHIT .set 27
NEWSEC .set 28
SECX   .set 29
SECY   .set 30

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
    print course_str
    getch
    cmp #30
    beq goback1
    bcc invalid_course
    cmp #38
    bcs invalid_course
    clc
    sbc #31
    sta COURSE
    jmp warporimpulse

invalid_course:
    print course_help
    jmp setcourse

goback1:
    jmp commandloop

warporimpulse:
    print warp_or_impulse_str
    cmp #$57
    beq warpprompt
    cmp #$49
    bne setcourse
    jmp impulseprompt

warpprompt:
    print warp_str
    getch
    cmp #30
    beq goback1
    cmp #37
    bcs warpprompt

    clc
    sbc #30
    sta SPEED

    lda damage+dam_warp
    beq @warp_ok
    print warp_damaged
    jmp impulseprompt
    
@warp_ok:
    lda enterprise_data+loc
    tax
    lda galaxy,x
    lsr
    lsr
    lsr
    lsr
    lsr
    beq @noklingons
    jsr compute_attack
    lda destroyed
    beq @noklingons
    jmp ent_destroyed

@noklingons:
    ldx #0
    stx EDGEHIT
    ldy COURSE
    lda course_x_diff,y
    cmp #0
    bmi @subx
    beq @compute_y
    lda enterprise_data+loc
    and #07
    clc
    adc SPEED
    cmp #7
    bcc @xok
    lda #7
    inc EDGEHIT
    jmp @xok

@subx:
    lda enterprise_data+loc
    and #07
    clc
    sbc SPEED
    bcc @xok
    inc EDGEHIT
    lda #0
@xok:
    tax

@compute_y:
    lda course_y_diff, y
    cmp #0
    bmi @suby
    bpl @addy
    ldy #0
    jmp @yok

@addy:
    lda enterprise_data+loc
    lsr
    lsr
    lsr
    clc
    adc SPEED
    cmp #7
    bcc @yok
    lda #7
    inc EDGEHIT
    jmp @yok

@suby:
    lda enterprise_data+loc
    lsr
    lsr
    lsr
    clc
    sbc SPEED
    bcc @yok
    lda #0
    inc EDGEHIT

@yok:
    stx SCRATCH
    asl
    asl
    asl
    clc
    adc SCRATCH
    sta enterprise_data+loc
    lda EDGEHIT
    beq @nohit
    print edge
@nohit:
    jsr init_sector
    jmp commandloop

goback2:
    jmp commandloop

impulseprompt:
    print impulse_str
    getch
    cmp #30
    beq goback2
    cmp #37
    bcs impulseprompt

    clc
    sbc #30
    sta SPEED

    lda enterprise_data+loc
    tax
    lda sector,x
    lsr
    lsr
    lsr
    lsr
    lsr
    beq @noklingons
    jsr compute_attack
    lda destroyed
    beq @noklingons
    jmp ent_destroyed

@noklingons:
    ldx #0
    stx EDGEHIT
    stx NEWSEC
    ldy COURSE
    lda course_x_diff,y
    cmp #0
    bmi @subx
    beq @compute_y
    lda enterprise_data+sectloc
    and #07
    clc
    adc SPEED
    cmp #7
    bcc @xok
    inc NEWSEC
    clc
    sbc #8
    sta SECX
    lda enterprise_data+loc
    and #7
    clc
    adc #1
    sta SCRATCH
    cmp #7
    bcc @nogalxhit
    inc EDGEHIT
    lda #7
    sta SCRATCH
@nogalxhit:
    lda enterprise_data+loc
    and #$70
    ora SCRATCH
    sta enterprise_data+loc
    lda SECX
    jmp @xok

@subx:
    lda enterprise_data+loc
    and #$0f
    clc
    sbc SPEED
    bcc @xok
    inc NEWSEC
    clc
    adc #8
    sta SECX
    lda enterprise_data+loc
    and #7
    clc
    sbc #1
    sta SCRATCH
    bcc @nogalxhit2
    inc EDGEHIT
    lda #0
    sta SCRATCH
@nogalxhit2:
    lda enterprise_data+loc
    and #$70
    ora SCRATCH
    sta enterprise_data+loc
    lda SECX
    jmp @xok
@xok:
    tax

@compute_y:
    lda course_y_diff, y
    cmp #0
    bmi @suby
    bpl @addy
    ldy #0
    jmp @yok

@addy:
    lda enterprise_data+sectloc
    lsr
    lsr
    lsr
    clc
    adc SPEED
    cmp #7
    bcc @yok
    inc NEWSEC
    clc
    sbc #8
    sta SECY
    lda enterprise_data+loc
    lsr
    lsr
    lsr
    clc
    adc #1
    sta SCRATCH
    cmp #7
    bcc @nogalyhit
    inc EDGEHIT
    lda #7
    sta SCRATCH
@nogalyhit:
    lda enterprise_data+loc
    and #$07
    asl SCRATCH
    asl SCRATCH
    asl SCRATCH
    ora SCRATCH
    sta enterprise_data+loc
    lda SECY
    jmp @yok

@suby:
    lda enterprise_data+loc
    lsr
    lsr
    lsr
    clc
    sbc SPEED
    bcc @yok
    lda #0
    inc NEWSEC
    clc
    adc #8
    sta SECY
    lda enterprise_data+loc
    lsr
    lsr
    lsr
    clc
    sbc #1
    sta SCRATCH
    bne @nogalyhit2
    inc EDGEHIT
    lda #0
    sta SCRATCH

@nogalyhit2:
    lda enterprise_data+loc
    and #$07
    asl SCRATCH
    asl SCRATCH
    asl SCRATCH
    ora SCRATCH
    sta enterprise_data+loc
    lda SECY

@yok:
    stx SCRATCH
    asl
    asl
    asl
    clc
    adc SCRATCH
    sta enterprise_data+sectloc
    lda EDGEHIT
    beq @nohit
    print iedge
@nohit:
    lda NEWSEC
    beq @nonewsector
    print newsector
    jsr init_sector
@nonewsector:
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


compute_attack:
    tay
    jsr check_docked
    beq @no_dock
    print base_protect
    rts

@no_dock:
@attackloop:
    jsr rand99
    lda RND99
    bne @klinghit
    print klingon_miss
    jmp @nextklingon

@klinghit:
    print klingon_hit1
    jsr printhexnolead
    print klingon_hit2
    lda enterprise_data+shields_L
    clc
    sbc RND99
    sta enterprise_data+shields_L
    lda enterprise_data+shields_H
    sbc #$0 ; See if there was a borrow
    bcs blown_up
@nextklingon:
    dey
    bne @attackloop
    rts

blown_up:
    lda #1
    sta destroyed
    rts

ent_destroyed:
    print dead
    lda klingons
    jsr printhexnolead
    print dead2
    jmp mainloop
    

;    jsr print_sector

    jmp ESCAPE
    
rand99:
    jsr rand
    sta RND99
    and #$0f
    cmp #$09
    bcs rand99
    lda RND99
    and #$f0
    cmp #$90
    bcs rand99
    rts


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
    sta destroyed
    lda #$30
    sta enterprise_data+energy_H
    lda #$10
    sta enterprise_data+torpedoes
    jsr rand
    lda RANDL
    and #$3f
    sta enterprise_data+loc
    lda #$00
    ldx #$07
@init_damloop:
    sta damage,x
    dex
    bpl @init_damloop
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

check_docked:
    lda enterprise_data+sectloc
    and #7
    tax
    beq @checkright
    lda enterprise_data+sectloc
    clc
    sbc #1
    tax
    lda sector, x
    cmp #sect_base
    bne @checkright
    lda #1
    rts
@checkright:
    lda enterprise_data+sectloc
    and #7
    cmp #7
    beq @nobase
    clc
    adc #1
    tax
    lda sector, x
    cmp #sect_base
    bne @nobase
    lda #1
    rts
@nobase:
    lda #0
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
damage      .set enterprise_data+7


klingon_data .set damage+8
kloc        .set 0
kshields_L  .set 1
kshields_H  .set 2

sector      .set klingon_data + 9  ; skip 3 bytes * 3 klingons

sect_ent   .set 1
sect_kling .set 2
sect_base  .set 3
sect_star  .set 4

destroyed  .set sector+64

sect_image:
nothing:    .byte "   ",0
ent_ship:   .byte "-_=",0
kling_ship: .byte "o-z",0
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

course_str: .byte $0a,"COURSE (1-8):", $00
warp_str:   .byte $0a,"WARP FACTOR (0-7):", $00
impulse_str:   .byte $0a,"IMPULSE LEVEL (0-7):", $00
warp_or_impulse_str: .byte $0a,"(W)ARP OR (I)MPULSE DRIVE?",0
course_help: .byte $0a
        .byte "    3",$0a
        .byte "  4 | 2", $0a
        .byte "5---X---1", $0a
        .byte "  6 | 8", $0a
        .byte "    7", $0a, 0

course_x_diff: .byte 1, 1, 0, 255, 255, 255, 0, 1
course_y_diff: .byte 0, 255, 255, 255, 0, 1, 1, 1

dam_warp   .set 0
dam_srs    .set 1
dam_lrs    .set 2
dam_phaser .set 3
dam_photon .set 4
dam_dam    .set 5
dam_shield .set 6
dam_comp   .set 7

damage0: .byte "WARP ENGINES",0
damage1: .byte "S.R. SENSORS",0
damage2: .byte "L.R. SENSORS",0
damage3: .byte "PHASER CNTRL",0
damage4: .byte "PHOTON TUBES",0
damage5: .byte "DAMAGE CNTRL",0
damage6: .byte "SHIELD CNTRL",0
damage7: .byte "COMPUTER",0

damage_names:
    .word dam_warp, dam_srs, dam_lrs, dam_phaser
    .word dam_photon, dam_dam, dam_shield, dam_comp

warp_damaged: .byte $0a
    .byte "WARP ENGINES ARE DAMAGED, USE IMPULSE DRIVE",$0a,0
base_protect: .byte $0a
    .byte "STAR BASE SHIELDS PROTECT THE ENTERPRISE",$0a,0
    
dead: .byte $0a
    .byte "THE ENTERPRISE HAS BEEN DESTROYED.",$0a
    .byte "THE FEDERATION WILL BE CONQUERED.",$0a
    .byte "THERE ARE STILL ",0
dead2: .byte " KLINGON BATTLE CRUISERS.",$0a,$0a,$0a
    .byte "YOU GET ANOTHER CHANCE....",$0a,0

edge: .byte $0a
    .byte "THE WARP ENGINES SAFELY SHUTDOWN AS YOU",$0a
    .byte "ENCOUNTER THE EDGE OF THE GALAXY.",$0a,0

iedge: .byte $0a
    .byte "THE IMPULSE ENGINES SAFELY SHUTDOWN AS",$0a
    .byte "YOU ENCOUNTER THE EDGE OF THE GALAXY.",$0a,0

newsector: .byte $0
    .byte "YOU HAVE ENTERED A NEW SECTOR.",$0a,0

klingon_hit1: .byte $0a
    .byte "KLINGON CRUISER HITS YOU WITH ",$0
klingon_hit2: .byte " STROMS",$0a,0
klingon_miss: .byte $0a
    .byte "KLINGON BLAST MISSES YOU",$0a,0
