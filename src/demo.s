.include "global.inc"

.export demo_scene_load_point
.import scene_irq, scene_nmi

.import irq_next_scanline, irq_rts, irq_table_address
.importzp irq_table_scanline, irq_next_index


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
    adc #$00

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

    ldstword demo_scene_nmi, scene_nmi
    ; ldstword demo_scene_irq, scene_irq

    ; build an irq table
    ldstword demo_scene_irq1, irq_table_address
    ldst #$3E, irq_table_scanline               ;-1 for first irq timinig

    ldstword demo_scene_irq2, irq_table_address+2
    ldst #$3F, irq_table_scanline+1

    ldstword demo_scene_irq3, irq_table_address+4
    ldst #$3F, irq_table_scanline+2

    ldstword demo_scene_irq4, irq_table_address+6
    ldst #$1F, irq_table_scanline+3

    ldst #$FF, irq_table_scanline+4 ;stub the end with FF


    rts

.segment "INITBANK2"
demo_scene_main_point:
    rts


.segment "STATICCODE"

.proc demo_scene_nmi
    ; reset the palette

    bit PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR
    lda #$0F
    sta PPUDATA
    lda #$26
    sta PPUDATA
    lda #$12
    sta PPUDATA
    lda #$1a
    sta PPUDATA

    ; necessary??
    ldst #>$0000, PPUADDR
    ldst #<$0000, PPUADDR
    ; ldst #($F8), PPUSCROLL
    ; ldst #$00, PPUSCROLL

    rts
.endproc

.macro color_change_irq palette_index, new_color, y_value
.scope
;burn until a specific column is passed

    ; this adds a 3-cycle delay
; foo1:
;     jmp foo2
;     jmp foo1
; foo2:
.repeat 69 ; lots of 2-cycle delays
    nop
.endrepeat
    bit PPUSTATUS


    .repeat 6 ;equivalent to setting PPUSCROLL twice
    nop
    .endrepeat
    ; ldst #$10, PPUSCROLL
    ; ldst #$08, PPUSCROLL
    
    ldx #new_color ; new palette color
    ldyppuaddr1 $00, y_value, $0

    ldst #$3F, PPUADDR ; palette index write 1

    ldst #$00, PPUMASK ; rendering off

    lda #palette_index

    ; critical update time
    sta PPUADDR     ; write 2
    stx PPUDATA     ; write palette
    stx PPUDATA     ; write palette
    sty PPUADDR     ; restore 1
    ldappuaddr2 $00 , y_value, $0
    sta PPUADDR     ; restore 2

    ; critical time done
    lda #BG_ON
    sta PPUMASK
    jmp irq_rts
.endscope
.endmacro

.proc demo_scene_irq1
    color_change_irq $02, $2C, $40
.endproc

.proc demo_scene_irq2
    color_change_irq $01, $13, $80
.endproc

.proc demo_scene_irq3
    color_change_irq $01, $20, $C0
.endproc

.proc demo_scene_irq4
    color_change_irq $02, $06, $E0
.endproc