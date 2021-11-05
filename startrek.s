.segment "MAIN"

DASH .set $2d
PIPE .set $7c
NEWLINE .set $0d

.macro putch ch
    lda #ch
    putchar
.endmacro

ESCAPE .set $FF1A

    .import initrand, printhexnolead, putcharn, gotoxy, doprint
    .import clearscreen_str

    .include "lib.inc"

    jsr initrand
mainloop:
    jsr drawscreen

    jmp ESCAPE
    

drawscreen:
    clearscreen
    ldx #$01
    ldy #$01
    jsr gotoxy
    print srs
    ldx #$51
    ldy #$01
    jsr gotoxy
    print lrs
    putch NEWLINE
    
    lda #DASH
    ldx #33
    jsr putcharn
    ldx #$44
    ldy #$02
    jsr gotoxy
    lda #DASH
    ldx #30
    jsr putcharn
    putch NEWLINE

    jmp ESCAPE

srs: .byte "    Short Range Scanner",0
lrs: .byte "Long Range Scanner", 0
energy_str: .byte "Energy:",0
shields_str: .byte "Shields:", 0
torpedoes_str: .byte "Torpedoes:", 0
engine_str: .byte "Engine:",0
impulse_str: .byte "Impulse",0
warp_str: .byte "Warp   ",0
