.include "nes.inc"
.include "mmc3.inc"

.export main, nmi_handler, irq_handler
.import sample_ppu

.segment "ZEROPAGE"

frame_counter: .res 1

.segment "STATICCODE"
.proc main
.export set_0_0_scroll

    fjmp sample_ppu

set_0_0_scroll:
    lda #$00
    sta PPUADDR
    sta PPUADDR

main_loop:
    jmp main_loop

.endproc

.proc nmi_handler
    ; lda #$3F
    ; sta PPUADDR
    ; lda #$00
    ; sta PPUADDR
    ; lda #$0F
    ; sta PPUDATA
    ; lda #$16
    ; sta PPUDATA
    ; lda #$12
    ; sta PPUDATA
    ; lda #$1a
    ; sta PPUDATA

set_scroll:
    lda #$00
    sta PPUADDR
    sta PPUADDR

    ; lda frame_counter
    ; sta PPUDATA
    ; inc frame_counter ; party mode
    rti
.endproc

.proc irq_handler
    rti
.endproc
