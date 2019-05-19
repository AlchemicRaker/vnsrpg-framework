.include "global.inc"

.export demo_scene_load_point


.segment "INITBANK"
; Load should happen during a vblank
demo_scene_load_point:
    ; disable NMI while loading

    bit PPUSTATUS
    
    ldst #>NT_2000, PPUADDR ; point at beginning of nametable
    ldst #<NT_2000, PPUADDR ; point at beginning of nametable

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

    ; enable NMI
    ldst #PPUCTRL_NMI | PPUCTRL_OBJ_1000, PPUCTRL

    ldst #BG_ON, PPUMASK

    ldst #>$0000, PPUSCROLL
    ldst #<$0000, PPUSCROLL

    ldstword .bank(demo_scene_main_point), next_scene_bank
    ldstword demo_scene_main_point, next_scene_point

    rts

.segment "INITBANK2"
demo_scene_main_point:
    rts