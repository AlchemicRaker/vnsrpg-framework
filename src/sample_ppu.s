.include "nes.inc"
.include "mmc3.inc"

.import set_0_0_scroll
.export sample_ppu

.segment "INITBANK"
.proc sample_ppu
init_start_ppu:
    cli             ; Enable interrupts

    ; lda #$25        
    ; sta frame_counter

put_sample_tiles_on_screen:
    bit PPUSTATUS
    lda #$20        ; point at beginning of nametable
    sta PPUADDR
    lda #$00
    sta PPUADDR

    lda #$00 ; tile number
    sta PPUDATA     ; nametable 0
    lda #$01        ; tile number
    sta PPUDATA     ; nametable 1

    lda #$20        ; point at second row of nametable
    sta PPUADDR
    lda #$20
    sta PPUADDR

    lda #$02        ; tile number
    sta PPUDATA     ; nametable 0
    lda #$03        ; tile number
    sta PPUDATA     ; nametable 1

set_sample_palette:
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

    jmp set_0_0_scroll ; TODO: return from far call
.endproc