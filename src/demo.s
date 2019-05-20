.include "global.inc"

.export demo_scene_load_point, demo_scene_irq
.import scene_irq, scene_nmi

.import irq_table_scanline, irq_next_index, irq_next_scanline, irq_table_address, irq_rts


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

    ldstword demo_scene_nmi, scene_nmi
    ; ldstword demo_scene_irq, scene_irq

    ; build an irq table
    ldstword demo_scene_irq, irq_table_address
    ldst #$3F, irq_table_scanline
    ldst #$FF, irq_table_scanline+1 ;stub the end with FF


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
    lda #$16
    sta PPUDATA
    lda #$12
    sta PPUDATA
    lda #$1a
    sta PPUDATA

    ldst #>$0000, PPUADDR
    ldst #<$0000, PPUADDR

    rts
.endproc

.proc demo_scene_irq
;burn until a specific column is passed

    ; prep registers and writes
foo1:
    jmp foo2
    jmp foo1
foo2:
.repeat 77
    nop
.endrepeat
    bit PPUSTATUS
    
    ldx #$20 ; new palette color
    ldy #$11 ; prep restore 1 (this is terrible, but looks good during the row only!)
    ; ldyppuaddr1 $00, $41, $0

    ldst #$3F, PPUADDR ; palette index write 1

    ldst #$00, PPUMASK ; rendering off

    lda #$02

    ; critical update time
    sta PPUADDR     ; write 2
    stx PPUDATA     ; write palette
    sty PPUADDR     ; restore 1
    lda #$00
    ; ldappuaddr2 $00, $41, $0
    sta PPUADDR     ; restore 2

    ; critical time done
    lda #BG_ON
    sta PPUMASK

    ; sta IRQ_DISABLE
; rti
    jmp irq_rts
.endproc