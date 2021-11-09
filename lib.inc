PRTL .set $A0
PRTH .set $A1

DSP  .set  $D012
DSPCR .set $D013

RANDL .set      $A2
RANDH .set      $A3
RANDBIT .set    $A4

KBDCR .set $d011
KBD .set $d010

.macro putchar
    .local putready
putready: bit DSP
    bmi putready
    ora #$80
    sta DSP
.endmacro

.macro print addr
    lda #<addr
    sta PRTL
    lda #>addr
    sta PRTH
    ldy #0
    jsr doprint
.endmacro

.macro getch
    .local getchloop
getchloop:
    jsr rand
    bit KBDCR
    bpl getchloop
    lda KBD
.endmacro
