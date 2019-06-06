.include "global.inc"

.export demo_text_scene_load_point
.import scene_irq, scene_nmi, font, begin_chr0

.import irq_next_scanline, irq_rts, irq_table_address
.importzp irq_table_scanline, irq_next_index


.segment "RAM"


.segment "INITBANK"
; Load should happen during a vblank
demo_text_scene_load_point:
    ; disable NMI while loading

    bit PPUSTATUS
    
    ldst #>NT_2000, PPUADDR ; point at beginning of nametable
    ldst #<NT_2000, PPUADDR ; point at beginning of nametable

    clc
    ldy #$00        ; y
@loop_row:
    ldx #$00        ; x

    ; tile to display
    lda # .lobyte( (font - begin_chr0)/16 + 0 )

@loop_column:
    sta PPUDATA     ; output tile

    inx             ; next column
    cpx #$20
    bne @loop_column

    iny             ;next row
    cpy #$1E
    bne @loop_row

load_image:
    ; load a sequence of tiles into an x,y,w,h area (up to 256 tiles)

    ; demo: draw 96 characters, 16 wide, 6 tall

    ; start on tile 0
    ldy # .lobyte( (font - begin_chr0)/16 + 0 )

    ; 6 rows
.repeat 6, row
.scope
    ; reset the PPUADDR
    ; top-left is $07, $01
    ldst #>(NT_2000+($20 * (row+$01))+$07), PPUADDR ; point at beginning of row in nametable
    ldst #<(NT_2000+($20 * (row+$01))+$07), PPUADDR ; point at beginning of row in nametable
    ldx #$00
loop_column:
    ; lda # .lobyte( (font - begin_chr0)/16 )
    sty PPUDATA
    
    iny              ; next tile to load
    inx              ; x++
    cpx #$10         ; draw 10 tiles
    bne loop_column
.endscope
.endrepeat


set_sample_palette:
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR

    lda #$3F
    sta PPUDATA
    lda #$30
    sta PPUDATA
    lda #$24
    sta PPUDATA
    lda #$24
    sta PPUDATA

    ; enable NMI
    ldst #PPUCTRL_NMI | PPUCTRL_OBJ_1000, PPUCTRL

    ldst #BG_ON, PPUMASK

    ldst #>$0000, PPUSCROLL
    ldst #<$0000, PPUSCROLL

    ldstword .bank(demo_text_scene_main_point), next_scene_bank
    ldstword demo_text_scene_main_point, next_scene_point

    ldstword demo_text_scene_nmi, scene_nmi

    ; build an empty irq table
    ldst #$FF, irq_table_scanline

    rts



.segment "INITBANK"
demo_text_scene_main_point:
    ; just a static text demo
    rts

.segment "STATICCODE"

.proc demo_text_scene_nmi
    rts
.endproc
