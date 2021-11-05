PRTL .set $A0
PRTH .set $A1

DSP  .set  $D012
DSPCR .set $D013

COLOR_NONE  .set 0
FG_BLACK    .set $30
FG_RED      .set $31
FG_GREEN    .set $32
FG_YELLOW   .set $33
FG_BLUE     .set $34
FG_MAGENTA  .set $35
FG_CYAN     .set $36
FG_WHITE    .set $37
FG_BRIGHT_BLACK    .set $90
FG_BRIGHT_RED      .set $91
FG_BRIGHT_GREEN    .set $92
FG_BRIGHT_YELLOW   .set $93
FG_BRIGHT_BLUE     .set $94
FG_BRIGHT_MAGENTA  .set $95
FG_BRIGHT_CYAN     .set $96
FG_BRIGHT_WHITE    .set $97

BG_BLACK    .set $40
BG_RED      .set $41
BG_GREEN    .set $42
BG_YELLOW   .set $43
BG_BLUE     .set $44
BG_MAGENTA  .set $45
BG_CYAN     .set $46
BG_WHITE    .set $47

.macro putchar
    .local putready
putready: bit DSPCR
    bpl putready
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

.macro set_color fg, bg
    .ifblank bg
        lda #fg
        jsr set_fbg_color
    .else
        lda #fg
        ldx #bg
        jsr set_fg_bg_color
    .endif
.endmacro

.macro clearscreen
    print clearscreen_str
.endmacro

.macro getch
    .local getchloop
getchloop:
    jsr rand
    bit KBDCR
    bpl getchloop
    lda KBD
.endmacro
