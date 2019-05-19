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
    ldst #>$0000, PPUADDR
    ldst #<$0000, PPUADDR

    fjsr bank_switch_far_call_test

    cli

main_loop:
    jmp main_loop

.endproc

.proc nmi_handler ; vblank
    sta IRQ_DISABLE
    lda #$3F      ; scanline 68 (halfway through row 9)
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

    ldst #>$0000, PPUADDR
    ldst #<$0000, PPUADDR

    rti
.endproc

;so, update 1 palette color per row
;rest of the row can render
;however, the scroll cannot be restored to the bottom half of a row of tiles
;a separate bank with offset UI tiles can be used to draw the bottom half of the row
;bank switch *before* the hblank it becomes necessary
;back switch back before the next row of tiles, somehow.

.proc irq_handler
;burn until a specific column is passed
.repeat 96 ;92 for 2 palettes, 
    nop
.endrepeat
    
    ; prep registers and writes
    bit PPUSTATUS

    ldx #$20 ; new palette color

    ldyppuaddr1 $00, $40, $0 ; prep restore 1

    ldst #$3F, PPUADDR ; write 1

    ldst #$00, PPUMASK ; disable rendering

    lda #$02 ; palette color index

    ; critical update time

    sta PPUADDR
    stx PPUDATA
    ; ldx #$24      ;try to jam a second one in?
    ; stx PPUDATA   ;taste the rainbow!
    sty PPUADDR     ; restore 1
    ldyppuaddr2 $00, $40, $0
    sty PPUADDR     ; restore 2
    ; critical time done

    lda #BG_ON
    sta PPUMASK

    sta IRQ_DISABLE
    rti
.endproc
