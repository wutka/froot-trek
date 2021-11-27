.segment "MAIN"

DASH .set $2d
PIPE .set $7c
NEWLINE .set $0d
COMMA .set $2c
SPACE .set $20

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

NUMINPUTL .set 31
NUMINPUTH .set 32
NUMINPUTCOUNT .set 33
NUMINPUTDIGIT .set 34

CMP1L .set 35
CMP1H .set 36
CMP2L .set 37
CMP2H .set 38

.macro putch ch
    lda #ch
    putchar
.endmacro

ESCAPE .set $FF1A

    .import initrand, rand, printhexnolead, putcharn, doprint, hexdigits
    .import printhex,printhex4nolead

    .include "lib.inc"

    jsr initrand    ; initialize the rando number generator
mainloop:
    putch NEWLINE
    jsr init_galaxy
    jsr init_enterprise
    jsr init_sector

commandloop:
    jsr print_location
    print energy_hdr
    lda enterprise_data+energy_H
    sta PRTH
    lda enterprise_data+energy_L
    sta PRTL
    jsr printhex4nolead
    print shields_hdr
    lda enterprise_data+shields_H
    sta PRTH
    lda enterprise_data+shields_L
    sta PRTL
    jsr printhex4nolead
    print torps_hdr
    lda enterprise_data+torpedoes
    jsr printhexnolead
    putch NEWLINE

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
    clc
    cmp #$30 ; 0?
    beq goback1
    bcc invalid_course  ; if < 0, invalid
    cmp #$38
    bcs invalid_course  ; if > 8, invalid
    sec
    sbc #$31 ; convert ASCII 1-8 to 0-7
    sta COURSE
    jmp warporimpulse

invalid_course:
    print course_help
    jmp setcourse

goback1:
    jmp commandloop

warporimpulse:
    print warp_or_impulse_str
    getch
    cmp #$57    ; W
    beq warpprompt
    cmp #$77    ; w
    beq warpprompt
    cmp #$49    ; I
    beq @goimpulse
    cmp #$69    ; i
    bne setcourse
@goimpulse:
    jmp impulseprompt

warpprompt:
    print warp_str
    getch
    cmp #$30        ; compare char to ascii 0
    beq goback1     ; if = 0, go back to command prompt
    bcc warpprompt  ; if < 0, prompt again for warp
    cmp #$38        ; compare char to ascii 7
    bcs warpprompt  ; if > 7, prompt again for warp

    sec
    sbc #$30     ; convert ASCII to number 1-7
    sta SPEED

    lda damage+dam_warp  ; see if warp drive is damaged
    beq @warp_ok
    print warp_damaged
    jmp impulseprompt
    
@warp_ok:
    lda enterprise_data+loc ; Get the current enterprise loc
    tax
    lda galaxy,x    ; look at this section of galaxy
    lsr             ; shift right 5 positions to get # of klingons
    lsr
    lsr
    lsr
    lsr
    beq @noklingons     ; if no klingons, no attack
    jsr compute_attack  ; compute klingon attack
    lda destroyed       ; see if attack destroyed the Enterprise
    beq @noklingons     ; otherwise, do the move
    jmp ent_destroyed   

@noklingons:
    ldx #0              ; clear edge-of-the-galaxy flag
    stx EDGEHIT
    ldy COURSE          ; get the current course
    lda course_x_diff,y ; see how this course affects the x coord
    bmi @subx           ; if it negative, subtract
    beq @compute_y      ; if it is zero, just compute y
    lda enterprise_data+loc
    and #07             ; mask out the y
    clc
    adc SPEED           ; add the speed to x
    cmp #7              ; see if we have hit the edge of the galaxy
    bcc @xok
    lda #7              ; set x to rightmost edge
    inc EDGEHIT         ; flag that the edge was hit
    jmp @xok

@subx:
    lda enterprise_data+loc
    and #07             ; mask out the y
    sec
    sbc SPEED           ; subtract the speed from x
    bcs @xok            ; see if we hit the edge of the galaxy
    inc EDGEHIT         ; flag that the edge was hit
    lda #0              ; set x to leftmost edge
@xok:
    tax                 ; copy x coord to x register

@compute_y:
    lda course_y_diff, y    ; how does this course affect y?
    bmi @suby           ; if negative, subtract from y
    bne @addy           ; if non-zero, add to y
    lda enterprise_data+loc ; get the current loc
    lsr                 ; shift right to put y in a
    lsr
    lsr
    jmp @yok            ; otherwise, no change to y

@addy:
    lda enterprise_data+loc ; get the current loc
    lsr                 ; shift right 3 to get the y component
    lsr
    lsr
    clc
    adc SPEED           ; add the warp speed to y
    cmp #7              ; see if we hit the edge of the galaxy
    bcc @yok
    lda #7              ; if so, set y to highest valid y
    inc EDGEHIT         ; flag that we hit the edge
    jmp @yok

@suby:
    lda enterprise_data+loc ; get the current loc
    lsr                 ; shift right 3 to get the y
    lsr
    lsr
    sec
    sbc SPEED           ; subtract the speed
    bcs @yok            ; check to see if we hit the edge
    lda #0              ; set y to lowest valid y
    inc EDGEHIT         ; flag that we hit the edge

@yok:
    stx SCRATCH         ; save off x
    asl                 ; shift y coord over 3
    asl
    asl
    clc
    adc SCRATCH         ; add x coord into the loc
    sta enterprise_data+loc ; save the location
    lda EDGEHIT         ; did we hit the edge of the galaxy?
    beq @nohit
    print edge          ; tell the player we did
@nohit:
    jsr init_sector     ; randomly place the stuff in the sector
goback2:
    jmp commandloop

impulseprompt:
    print impulse_str
    getch
    cmp #$30            ; look for ascii 0
    beq goback2         ; if 0, prompt for command again
    bcc impulseprompt   ; if < 0, prompt again for impulse
    cmp #$38            ; look for ascii 7
    bcs impulseprompt   ; if > 7, prompt again for impulse

    sec
    sbc #$30             ; convert speed to numeric 1-7
    sta SPEED

    lda enterprise_data+loc  ; get the current enterprise loc
    tax
    lda galaxy,x        ; look at the current sector
    lsr                 ; shift right 5 to get the number of klingons
    lsr
    lsr
    lsr
    lsr
    beq @noklingons
    jsr compute_attack  ; if there are klingons, compute the attack
    lda destroyed       ; see if the enterprise was destroyed
    beq @noklingons
    jmp ent_destroyed

@noklingons:
    lda enterprise_data+sectloc
    tax
    lda #0
    sta sector,x        ; clear out the old enterprise location
    ldx #0
    stx EDGEHIT         ; clear the edge-of-galaxy flag
    stx NEWSEC          ; clear the edge-of-sector flag
    ldy COURSE          ; get the course
    lda course_x_diff,y ; see how the course affects x
    bmi @subx           ; if it subtracts, do that
    bne @addx      ; if it doesn't affect it, go to the y
    lda enterprise_data+sectloc
    and #07
    tax
    jmp @compute_y
@addx:
    lda enterprise_data+sectloc
    and #07             ; get the x part of the sector location
    clc
    adc SPEED           ; add the impulse amount
    cmp #8              ; see if we hit the edge of the sector
    bcc @xok            
    inc NEWSEC          ; flag the edge of sector
    sec
    sbc #8              ; subtract 8 from the sector x, so that if x was 10
                        ; it would be 2 in the next sector to the right
    sta SECX            ; save the sector x
    lda enterprise_data+loc ; get the galaxy loc
    and #7              ; get the x part of the galaxy loc
    clc
    adc #1              ; add 1 to galaxy x
    sta SCRATCH         ; save it
    cmp #8              ; see if this would hit the galaxy edge
    bcc @nogalxhit
    inc EDGEHIT         ; if so, flag the galaxy edge hit
    lda #7              ; set the x to maximum x of 7
    sta SCRATCH
@nogalxhit:
    lda enterprise_data+loc ; get the galaxy pos
    and #$38            ; clear off the x component
    ora SCRATCH         ; add in the x
    sta enterprise_data+loc ; save the galaxy pos
    lda SECX            ; fetch the saved x
    jmp @xok

@subx:
    lda enterprise_data+sectloc ; get galaxy loc
    and #$07            ; get x part of galaxy loc
    sec
    sbc SPEED           ; subtract impulse speed
    bcs @xok            ; make sure we didn't hit the edge of the sector
    inc NEWSEC          ; flag that we did hit the edge
    clc
    adc #8              ; adjust x so it is the x in the next sector over
                        ; e.g. if x = -5, then it is 3 in the sector to the left
    and #7
    sta SECX            ; save off the x
    lda enterprise_data+loc  ; get the galaxy loc
    and #7              ; mask off the x part
    sec
    sbc #1              ; subtract 1 from galaxy x
    sta SCRATCH         ; save it
    bcs @nogalxhit2     ; see if we hit the galaxy edge
    inc EDGEHIT         ; flag that we did
    lda #0              ; set x to minimum x
    sta SCRATCH         ; save it
@nogalxhit2:
    lda enterprise_data+loc ; get the galaxy loc
    and #$38            ; mask off x bits
    ora SCRATCH         ; add in x bits
    sta enterprise_data+loc ; save galaxy loc
    lda SECX            ; retrieve the saved sector x
@xok:
    tax                 ; copy sector x to x register

@compute_y:
    lda course_y_diff, y ; see how the course affects y
    bmi @suby           ; if it subtracts, do the subtract
    bne @addy           ; if non-zero, do the add
    lda enterprise_data+sectloc ; get galaxy loc
    lsr                 ; shift right 3 to put y in a
    lsr
    lsr
    jmp @yok

@addy:
    lda enterprise_data+sectloc ; get galaxy loc
    lsr                 ; shift right 3 to get y part
    lsr
    lsr
    clc
    adc SPEED           ; add speed to y component
    cmp #7
    bcc @yok            ; see if we hit the edge of the sector
    inc NEWSEC          ; flag that we hit the edgs of the sector
    sec
    sbc #8              ; compute what y would be in next sector
    and #7
    sta SECY            ; save the sector y
    lda enterprise_data+loc ; get the galaxy loc
    lsr                 ; get the y part of the galaxy lox
    lsr
    lsr
    clc
    adc #1              ; add 1 to the galaxy loc y
    sta SCRATCH         ; save it
    cmp #7
    bcc @nogalyhit      ; see if we hit the edge of the galaxy
    inc EDGEHIT         ; flag that we did
    lda #7              ; set y to max y
    sta SCRATCH         ; save it
@nogalyhit:
    lda enterprise_data+loc ; get the galaxy loc
    and #$07            ; clear off the y part
    asl SCRATCH         ; shift the y loc into position
    asl SCRATCH
    asl SCRATCH
    ora SCRATCH         ; add it into the loc
    sta enterprise_data+loc ; save the loc
    lda SECY            ; retrieve the sector y
    jmp @yok

@suby:
    lda enterprise_data+sectloc ; get the sector loc
    lsr                 ; shift right 3 to get y part
    lsr
    lsr
    sec
    sbc SPEED           ; subtract speed from y
    bcs @yok            ; see if we hit the edge of the sector
    inc NEWSEC          ; flag that we did
    clc
    adc #8              ; see what x would be in next sector over
    and #7
    sta SECY            ; save x part
    lda enterprise_data+loc ; get galaxy loc
    lsr                 ; shift right 3 to get y part
    lsr
    lsr
    sec
    sbc #1              ; subtract one to move to next sector
    sta SCRATCH         ; save the sector y
    bcs @nogalyhit2     ; make sure we didn't hit the edge of the galaxy
    inc EDGEHIT         ; flag that we hit the edge of the galaxy
    lda #0              ; set galaxy y to minimum
    sta SCRATCH

@nogalyhit2:
    lda enterprise_data+loc ; get the galaxy loc
    and #$07            ; mask out the y part
    asl SCRATCH         ; shift galaxy y into position
    asl SCRATCH
    asl SCRATCH
    ora SCRATCH         ; add it into loc
    sta enterprise_data+loc ; save loc
    lda SECY            ; fetch sector y

@yok:
    stx SCRATCH         ; save off sector x
    asl                 ; shift sector y into position
    asl
    asl
    ora SCRATCH         ; add x into sector loc
    sta enterprise_data+sectloc  ; save sector loc
    tax
    lda #sect_ent
    sta sector,x
    lda EDGEHIT         ; did we hit the edge of the galaxy?
    beq @nohit
    print iedge         ; tell the player
@nohit:
    lda NEWSEC          ; are we in a new sector?
    beq @nonewsector
    print newsector     ; tell the player
    jsr init_sector     ; initialize the new sector
@nonewsector:
    jmp commandloop

srs:
    putch NEWLINE
    jsr print_sector
    jmp commandloop

lrs:
    print lrs_header
    print row_sep

    lda enterprise_data+loc
    and #$38             ; mask out y
    bne print_first_row
    print blank_row
    jmp print_middle_row
print_first_row:
    lda enterprise_data+loc
    sec
    sbc #8
    jsr print_row

print_middle_row:
    print row_sep
    lda enterprise_data+loc
    jsr print_row

    print row_sep

    lda enterprise_data+loc
    and #$38
    cmp #$38
    bne print_third_row
    print blank_row
    print row_sep
    jmp commandloop

print_third_row:
    lda enterprise_data+loc
    clc
    adc #8
    jsr print_row
    print row_sep
    jmp commandloop
    
print_row:
    tax
    and #7
    bne print_first_cell
    print blank_cell
    jmp print_second_cell
print_first_cell:
    print cell_header
    txa
    sec
    sbc #1
    tay
    lda galaxy,y
    jsr print_galaxy_cell
    putch SPACE

print_second_cell:
    txa
    tay
    print cell_header
    lda galaxy,y
    jsr print_galaxy_cell
    putch SPACE

    txa
    and #7
    cmp #7
    bne print_third_cell
    print blank_cell
    jmp print_cell_end

print_third_cell:
    print cell_header
    txa
    clc
    adc #1
    tay
    lda galaxy,y
    jsr print_galaxy_cell
    putch SPACE

print_cell_end:
    print cell_line_end
    rts

print_location:
    print coords
    lda enterprise_data+sectloc
    and #7
    jsr printhexnolead
    putch COMMA
    lda enterprise_data+sectloc
    lsr
    lsr
    lsr
    jsr printhexnolead
    print coords2
    lda enterprise_data+loc
    and #7
    jsr printhexnolead
    putch COMMA
    lda enterprise_data+loc
    lsr
    lsr
    lsr
    jsr printhexnolead
    putch NEWLINE
    rts



firephasers:
    print phasers_prompt
    jsr num_input

    lda enterprise_data+energy_L
    sta CMP1L
    lda enterprise_data+energy_H
    sta CMP1H

    lda NUMINPUTL
    sta CMP2L
    lda NUMINPUTH
    sta CMP2H

    jsr compare_bcd4
    beq @phasok
    bcs @phasok

    print notenergyphasers
    jmp commandloop

@phasok:
    lda enterprise_data+energy_L
    sed
    sec
    sbc NUMINPUTL
    sta enterprise_data+energy_L
    lda enterprise_data+energy_H
    sbc NUMINPUTH
    sta enterprise_data+energy_H

    print firing
    lda NUMINPUTH
    sta PRTH
    lda NUMINPUTL
    sta PRTL
    jsr printhex4nolead
    print unitsofphasers

    ldx enterprise_data+loc
    lda galaxy,x
    lsr             ; get number of klingons
    lsr
    lsr
    lsr
    lsr

    cmp #3
    beq @divphaserby3
    cmp #2
    beq @divphaserby2
    jmp @computephaserdamage

@divphaserby3:
    

    jmp commandloop

firetorps:
    jmp commandloop

shieldcontrol:
    print shields_prompt
    jsr num_input

    lda enterprise_data+energy_L
    sta CMP1L
    lda enterprise_data+energy_H
    sta CMP1H

    lda NUMINPUTL
    sta CMP2L
    lda NUMINPUTH
    sta CMP2H

    jsr compare_bcd4
    beq @xferok
    bcs @xferok

    print notenergyshields
    jmp commandloop

@xferok:
    lda enterprise_data+energy_L
    sed
    sec
    sbc NUMINPUTL
    sta enterprise_data+energy_L
    lda enterprise_data+energy_H
    sbc NUMINPUTH
    sta enterprise_data+energy_H

    print xferring
    lda NUMINPUTH
    sta PRTH
    lda NUMINPUTL
    sta PRTL
    jsr printhex4nolead
    print unitstoshields

    lda enterprise_data+shields_L
    clc
    adc NUMINPUTL
    sta enterprise_data+shields_L
    lda enterprise_data+shields_H
    adc NUMINPUTH
    sta enterprise_data+shields_H
    cld
    cmp #$10
    beq @check_second_digit
    bcs @shield_overflow
    jmp commandloop

@check_second_digit:
    lda enterprise_data+shields_L
    cmp #00
    bne @shield_overflow
    jmp commandloop

@shield_overflow:
    print toomuchenergy
    lda #00
    sta enterprise_data+shields_L
    lda #$10
    sta enterprise_data+shields_H
    jmp commandloop

damagecontrol:
    jmp commandloop

librarycomputer:
    jmp commandloop

endcontest:
    jmp ESCAPE


compute_attack:
    sta SCRATCH         ; save off the accumulator
    jsr check_docked    ; see if the enterprise is docked
    beq @no_dock
    print base_protect  ; if so, the base shields protect the enterprise
    rts

@no_dock:
@attackloop:
    jsr rand99              ; compute a random damage amoung
    lda RND99               ; get the damage amount
    bne @klinghit           ; if non-zero there was a hit
    print klingon_miss      ; otherwise, no hit
    jmp @nextklingon        ; try the next klingon

@klinghit:
    print klingon_hit1      ; the klingon hit
    lda RND99               ; fetch that damage amount again
    jsr printhexnolead      ; print it
    print klingon_hit2
    lda enterprise_data+shields_L   ; get the lower part of shields amount
    sec
    sbc RND99               ; subtract damage from it
    sta enterprise_data+shields_L   ; save it
    lda enterprise_data+shields_H   ; get upper part of shields amount
    sbc #$0                         ; subtract the carry if there was one
    bcc blown_up            ; if there is still a carry, the shields are
                            ; below 0 and the Enterprise has blown up
@nextklingon:
    dec SCRATCH             ; try the next klingon
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
    
; Generate a random number between 0 and 99, just keep generating if
; something has a hex digit
rand99: 
    jsr rand    ; generate rando number
    lda RANDL
    sta RND99   ; save it
    and #$0f    ; check right digit
    cmp #$0a    ; is it 0a or higher?
    bcs rand99  ; if so, generate again
    lda RND99
    and #$f0    ; check the left digit
    cmp #$a0    ; is it a0 or higher?
    bcs rand99  ; if so, generate again
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

    dex         ; decrement galaxy position
    bmi @init_done  ; if < 0, the init is done
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
    print destroy1  ; Tell the player how many klingons there are
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
    lda #$00        ; Shields start at 0
    sta enterprise_data+shields_L
    sta enterprise_data+shields_H
    sta enterprise_data+energy_L
    sta destroyed
    lda #$30    ; Energy starts at 3000 (BCD)
    sta enterprise_data+energy_H
    lda #$10    ; 10 (BCD) torpedoes
    sta enterprise_data+torpedoes
    jsr rand    ; put the Enterprise in a random cell
    lda RANDL
    and #$3f
    sta enterprise_data+loc
    jsr rand
    lda RANDL
    and #$3f
    sta enterprise_data+sectloc
    lda #$00
    ldx #$07
@init_damloop:
    sta damage,x    ; clear all the damage flags
    dex
    bpl @init_damloop
    rts

init_sector:
    ldx #63
    lda #0
@sectorclear:
    sta sector,x    ; clear each element in the sector
    dex
    bpl @sectorclear

    lda enterprise_data+loc ; get current location of the Enterprise
    tax
    lda galaxy,x
    tax             ; save a copy of the location counts
    lsr             ; shift over 4 to get base count (either 0 or 1 base)
    lsr
    lsr
    lsr
    and #1
    sta SECT_BASES
    txa             ; get the location counts again
    lsr             ; shift over 5 to get klingon count
    lsr
    lsr
    lsr
    lsr
    and #3
    sta SECT_KLINGONS

    txa             ; lower 3 bits are star count
    and #7
    sta SECT_STARS
    tax

@entloop:
    ldx enterprise_data+sectloc
    lda #sect_ent
    sta sector,x

@starloop:
    jsr rand        ; place stars in random locations
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

    tax             ; If klingons in sector and shields <= 200
                    ; print a warning
    print combat
    lda enterprise_data+shields_H
    cmp #$01
    bcs @klingloop
    bne @danger
    cmp #$00
    bne @klingloop
@danger:
    print shieldslow

@klingloop:
    jsr rand
    lda RANDL
    and #63
    tax
    lda sector,x    ; If spot occupied (non-zero) pick another spot
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
    lda sector,x    ; if spot occuped, pick another
    bne @baseloop
    lda #sect_base
    sta sector,x
    dec SECT_BASES
    bne @baseloop

@basedone:
    rts

; See if the enterprise is docked
check_docked:
    lda enterprise_data+sectloc  ; get sector loc of Enterprise
    and #7          ; look at x coord
    tax
    beq @checkright ; if x = 0, only check to the right
    lda enterprise_data+sectloc
    sec
    sbc #1          ; look at the spot to the left
    tax
    lda sector, x
    cmp #sect_base  ; is there a base there
    bne @checkright
    lda #1          ; return 1 indicating there is a base
    rts
@checkright:
    lda enterprise_data+sectloc ; get sector loc of Enterprise
    and #7          ; look at x coord
    cmp #7          ; is this the far right
    beq @nobase     ; if it is the far right, Enterprise isn't docked
    clc
    adc #1          ; look one to the right
    tax
    lda sector, x
    cmp #sect_base  ; if it is a base, Enterprise is docked
    bne @nobase
    lda #1          ; 1 means docked
    rts
@nobase:
    lda #0          ; 0 means not docked
    rts


print_sector:
    ldx #0
sectrow:
    lda sector,x    ; get the next sector
    asl             ; multiply value by 4
    asl
    clc
    adc #<sect_image ; add it to sector image pointer
    sta PRTL
    lda #0
    adc #>sect_image
    sta PRTH
    ldy #0
    jsr doprint     ; print the image for the item at this location
    txa
    and #7
    cmp #7          ; if this was the rightmost image, print a carriage return
    bne nocr
    putch NEWLINE

nocr:
    inx
    cpx #64         ; see if we are done
    bne sectrow
    rts

    
print_galaxy_cell:
    sta SCRATCH     ; save a copy of the cell
    lsr             ; shift 5 to get klingon count
    lsr
    lsr
    lsr
    lsr
    and #7
    tay
    lda hexdigits,y
    putchar
    lda SCRATCH     ; get the cell copy
    lsr             ; shift 4 to get base count
    lsr
    lsr
    lsr
    and #1
    tay
    lda hexdigits,y
    putchar
    lda SCRATCH
    and #$0f        ; get star count
    tay
    lda hexdigits,y
    putchar
    rts

num_input:
    lda #0
    sta NUMINPUTL
    sta NUMINPUTH
    sta NUMINPUTCOUNT

read_digit:
    getch               ; read a digit
    cmp #13
    bne @check_nl
    jmp @hit_return

@check_nl:
    cmp #10
    bne @check_bs

@hit_return:
    lda NUMINPUTCOUNT
    beq num_input
    rts

@check_bs:
    cmp #08             ; check for backspace
    bne checkdigits
    lda NUMINPUTCOUNT   ; see if we are already at the beginning
    beq read_digit
    putchar             ; print the backspace
    putch SPACE
    putch 8
    ; right-shift the number, undoing last digit
    lda NUMINPUTH       ; shift low digit left
    asl
    asl
    asl
    asl
    sta SCRATCH
    lda NUMINPUTL       ; shift high digit right
    lsr
    lsr
    lsr
    lsr
    ora SCRATCH         ; combine H low digit with L high digit
    sta NUMINPUTL
    lda NUMINPUTH       ; get the high digits again
    lsr                 ; shift upper digit to low
    lsr
    lsr
    lsr
    sta NUMINPUTH       
    dec NUMINPUTCOUNT   ; decrement the digit input count
    jmp read_digit     ; read the digit again

checkdigits:
    cmp #$30            ; is the char < ASCII 0?
    bcc read_digit
    cmp #$3a            ; is the char > ASCII 9?
    bcs read_digit
    putchar             ; print the backspace
    and #$7f
    sec
    sbc #$30            ; convert ASCII digit to 0-9
    sta NUMINPUTDIGIT   ; save the digit
    lda NUMINPUTH       ; shift high digits left
    asl
    asl
    asl
    asl
    sta SCRATCH
    lda NUMINPUTL       ; move high digit in low byte to the right
    lsr
    lsr
    lsr
    lsr
    ora SCRATCH         ; combine old high digit from low byte
                        ; with old low digit in high byte
    sta NUMINPUTH
    lda NUMINPUTL       ; shift the low digit left
    asl
    asl
    asl
    asl
    ora NUMINPUTDIGIT   ; add in the new digit in lowest position
    sta NUMINPUTL
    inc NUMINPUTCOUNT   ; increment the digit count
    lda NUMINPUTCOUNT
    cmp #4              ; if we have read 4 digits, quit
    beq @done
    jmp read_digit
@done:
    rts

compare_bcd4:
    lda CMP1H
    cmp CMP2H
    beq @compare_second
    rts

@compare_second:
    lda CMP1L
    cmp CMP2L
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
nothing:    .byte " . ",0
ent_ship:   .byte "-_=",0
kling_ship: .byte "o-z",0
starbase:   .byte ">I<",0
star:       .byte " * ",0


destroy1: .byte "YOU MUST DESTROY ",0
destroy2: .byte " KLINGONS",$0a,"IN ",0
destroy3: .byte " STARDATES WITH ",0
destroy4: .byte " STARBASES", $0a, 0
combat:    .byte $0a,"COMBAT AREA      CONDITION RED",$0a,0
shieldslow:        .byte "   SHIELDS DANGEROUSLY LOW",$0a,0
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

course_x_diff: .byte 1, 1,   0,   255, 255, 255, 0, 1
course_y_diff: .byte 0, 255, 255, 255, 0,   1,   1, 1

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

newsector: .byte $a
    .byte "YOU HAVE ENTERED A NEW SECTOR.",$0a,0

klingon_hit1: .byte $0a
    .byte "KLINGON CRUISER HITS YOU WITH ",$0
klingon_hit2: .byte " STROMS",$0a,0
klingon_miss: .byte $0a
    .byte "KLINGON BLAST MISSES YOU",$0a,0

lrs_header: .byte "  LONG RANGE SCAN",$0a,0
row_sep:    .byte "+-----+-----+-----+",$0a,0
blank_row:  .byte "| --- | --- | --- |",$0a,0
blank_cell: .byte "| --- ",0
cell_header: .byte "| ",0
cell_line_end: .byte "|",$0a,0

coords: .byte $0a,"YOU ARE AT LOCATION ",0
coords2: .byte " IN SECTOR ",0
energy_hdr: .byte "ENERGY: ",0
shields_hdr: .byte " SHIELDS: ",0
torps_hdr: .byte " TORPEDOES: ",0

shields_prompt: .byte $0a,"AMOUNT TO TRANSFER TO SHIELDS?",0
notenergyshields: .byte $0a,"NOT ENOUGH ENERGY AVAILABLE TO TRANSFER",$0a
                  .byte "THAT AMOUNT TO SHIELDS.",$0a,0
toomuchenergy: .byte $0a, "ENERGY TRANSFER EXCEEDS MAX SHIELD RATING",$0a
               .byte "OF 1000. ADDITIONAL ENERGY IS DISSIPATED.",$0a, 0
xferring: .byte $0a,"TRANSFERRING ",0
unitstoshields: .byte " UNITS TO SHIELDS.",$0a,0

phasers_prompt: .byte $0a,"AMOUNT OF PHASER ENERGY TO FIRE?",0
notenergyphasers: .byte $0a,"NOT ENOUGH ENERGY AVAILABLE TO TRANSFER",$0a
                  .byte "THAT AMOUNT TO PHASERS.",$0a,0
firing: .byte $0a,"FIRING ",0
unitsofphasers: .byte " UNITS OF PHASERS.",$0a,0

tens:  .byte 0, 10, 20
div3: .byte 0, 0, 0, 1, 1, 1, 2, 2, 2, 3
      .byte 3, 3, 4, 4, 4, 5, 5, 5, 6, 6
      .byte 6, 7, 7, 7, 8, 8, 8, 9, 9, 9
rem3: .byte 0, 1, 2, 0, 1, 2, 0, 1, 2, 0
      .byte 1, 2, 0, 1, 2, 0, 1, 2, 0, 1
      .byte 2, 0, 1, 2, 0, 1, 2, 0, 1, 2
