; .include "nes.inc"
; .include "mmc3.inc"
.include "global.inc"

.import set_0_0_scroll
.export sample_ppu

.segment "ZEROPAGE"
; tile_iterator: .res 1

.segment "INITBANK"
.proc sample_ppu
init_start_ppu:
    cli             ; Enable interrupts

    ; lda #$25        
    ; sta frame_counter
    jmp put_sample_tiles_on_screen

put_sample_tiles_on_screen_old:
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

put_sample_tiles_on_screen:
    bit PPUSTATUS
    lda #$20        ; point at beginning of nametable
    sta PPUADDR
    lda #$00
    sta PPUADDR

    clc
    ldy #$00        ; y
@loop_row:
    ldx #$00        ; x
    tya             ; tile to display, offset it each row

@loop_column:
    and #$03        ; clamp tile
    sta PPUDATA     ; output tile

    adc #$01        ; next tile
    inx             ; next column
    cpx #$20
    bne @loop_column

    iny             ;next row
    cpy #$1E
    bne @loop_row

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

    rts
.endproc