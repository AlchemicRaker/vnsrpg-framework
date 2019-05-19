.include "global.inc"

.export main, nmi_handler, irq_handler
.import sample_ppu

.segment "ZEROPAGE"

frame_counter: .res 1

.segment "RAM"
dummy: .res 2

.segment "INITBANK2"
.proc bank_switch_far_call_test
    rts 
.endproc

.segment "STATICCODE"
.proc main
    fjsr sample_ppu
    ldst #PPUCTRL_NMI | PPUCTRL_OBJ_1000, PPUCTRL

    ldst #BG_ON, PPUMASK

set_0_0_scroll:
    ldppuaddr $0000

    fjsr bank_switch_far_call_test

    cli

main_loop:
    jmp main_loop

.endproc

.proc nmi_handler ; vblank
    sta IRQ_DISABLE
    lda #$40
    sta IRQ_LATCH
    sta IRQ_RELOAD
    sta IRQ_ENABLE
    ; reset the palette

    bit PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR
    lda #$0F
    sta PPUDATA
    lda #$16
    sta PPUDATA
    lda #$12
    sta PPUDATA
    lda #$1a
    sta PPUDATA


    lda #$00
    sta PPUADDR
    lda #$00
    sta PPUADDR

    rti
.endproc

.proc irq_handler
;burn until a specific column is passed
.repeat 96 ;92 for 2 palettes, 
    nop
.endrepeat
    
    ; prep registers and writes
    bit PPUSTATUS

    ldx #$20 ; new palette color
    ldy #$11 ; ppuaddr restore 1

    lda #$3F
    sta PPUADDR

    lda #$00
    sta PPUMASK

    lda #$02

    ; critical update time

    sta PPUADDR
    stx PPUDATA
    ; ldx #$24      ;try to jam a second one in?
    ; stx PPUDATA   ;taste the rainbow!
    sty PPUADDR
    lda #$00 ; ppuaddr restore 2
    sta PPUADDR
    ; critical time done

    lda #BG_ON
    sta PPUMASK

    sta IRQ_DISABLE
    rti
.endproc

.proc irq_handler_blah ; hblank
    
    lda #$00
    sta PPUMASK;-- dummy

    bit PPUSTATUS
    ;load a new palette
    lda #$3F
    sta PPUADDR;-- dummy
    lda #$00
    sta PPUADDR;-- dummy
    lda #$0F
    sta PPUDATA;-- dummy
    lda #$17
    sta PPUDATA;-- dummy
    lda #$13
    sta PPUDATA;-- dummy
    lda #$1b
    sta PPUDATA;-- dummy

    ;do something with the addr
    lda #$00
    sta PPUADDR;-- dummy
    lda #$00 ;or maybe F2
    sta PPUADDR;-- dummy


    lda #BG_ON
    sta PPUMASK;-- dummy

    sta IRQ_DISABLE
    ; sta IRQ_ENABLE
    rti
.endproc
