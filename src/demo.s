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
    adc #$02

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

    ldstword demo_scene_irq1b, irq_table_address+2
    ldst #$05, irq_table_scanline+1

    ldstword demo_scene_irq1c, irq_table_address+4
    ldst #$03, irq_table_scanline+2

    ldstword demo_scene_irq2, irq_table_address+6
    ldst #($3F - $0A), irq_table_scanline+3

    ldstword demo_scene_irq3, irq_table_address+8
    ldst #$3F, irq_table_scanline+4

    ldstword demo_scene_irq4, irq_table_address+10
    ldst #$1F, irq_table_scanline+5

    ldst #$FF, irq_table_scanline+6 ;stub the end with FF

    ldst #$00, demo_animation

    rts

.segment "RAM"

demo_animation: .res 1
demo_diff: .res 1

.segment "INITBANK2"
demo_scene_main_point:

    ; build an irq table
    ldstword demo_scene_irq1, irq_table_address
    ldst #$3E, irq_table_scanline               ;-1 for first irq timinig

    inc demo_animation
    lda demo_animation
    cmp #$30
    bne no_reset
    lda #$00
    sta demo_animation
no_reset:
    

    cmp #$18
    bmi leave_it
    lda #$30
    clc
    sbc demo_animation
leave_it:
    sta demo_diff


    ldstword demo_scene_irq1b, irq_table_address+2
    lda #$20
    clc
    sbc demo_diff
    sta irq_table_scanline+1

    ldstword demo_scene_irq1c, irq_table_address+4
    lda #$03
    sta irq_table_scanline+2

    ldstword demo_scene_irq2, irq_table_address+6
    lda #($3F - $02 - $03 - $20) ;subtract 2 for 2 irqs, $3 for known gap, and anim for other gap
    clc
    adc demo_diff
    ; lda #($3F - $08 - $02)
    sta irq_table_scanline+3    

    ; ldstword demo_scene_irq1b, irq_table_address+2
    ; ldst #$05, irq_table_scanline+1

    ; ldstword demo_scene_irq1c, irq_table_address+4
    ; ldst #$03, irq_table_scanline+2

    ; ldstword demo_scene_irq2, irq_table_address+6
    ; ldst #($3F - $0A), irq_table_scanline+3

    ldstword demo_scene_irq3, irq_table_address+8
    ldst #$3F, irq_table_scanline+4

    ldstword demo_scene_irq4, irq_table_address+10
    ldst #$1F, irq_table_scanline+5

    ldst #$FF, irq_table_scanline+6 ;stub the end with FF

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

.macro color_change_irq y_value, palette_index, new_color, new_color_2
.scope
;burn until a specific column is passed

    ; this adds a 3-cycle delay
; foo1:
;     jmp foo2
;     jmp foo1
; foo2:
.repeat 68 ; lots of 2-cycle delays
    nop
.endrepeat
    bit PPUSTATUS

.ifblank new_color_2
foo1:
    jmp foo2
    jmp foo1
foo2:
    .repeat 4 ;equivalent to setting PPUSCROLL twice
    nop
    .endrepeat
.else
    .repeat 6 ;equivalent to setting PPUSCROLL twice
    nop
    .endrepeat
.endif
    
    ldx #new_color ; new palette color
.ifblank new_color_2
    ldyppuaddr1 $00, y_value, $0
.else
    ldyppuaddr1 $10, y_value, $0
.endif

    ldst #$3F, PPUADDR ; palette index write 1

    ldst #$00, PPUMASK ; rendering off

    lda #palette_index

    ; critical update time
    sta PPUADDR     ; write 2
    stx PPUDATA     ; write palette
.ifnblank new_color_2
    ldx #new_color_2
    stx PPUDATA     ; write palette
.endif
    sty PPUADDR     ; restore 1
.ifblank new_color_2
    ldappuaddr2 $00 , y_value, $0
.else
    ldappuaddr2 $10 , y_value, $0
.endif
    sta PPUADDR     ; restore 2

    ; critical time done
    lda #BG_ON
    sta PPUMASK

.ifnblank new_color_2
    ldst #$00, PPUSCROLL
    ldst #$00, PPUSCROLL
.endif

    ; fix scroll for the next scanline?
    jmp irq_rts
.endscope
.endmacro

.macro nametable_change_irq nametable
    ldst #PPUCTRL_NMI | PPUCTRL_OBJ_1000 | nametable, PPUCTRL
    jmp irq_rts
.endmacro

.proc demo_scene_irq1
    color_change_irq $40, $01, $2C
.endproc

.proc demo_scene_irq1b
    nametable_change_irq $01
.endproc

.proc demo_scene_irq1c
    nametable_change_irq $00
.endproc

.proc demo_scene_irq2
    color_change_irq $80, $01, $13
.endproc

.proc demo_scene_irq3
    color_change_irq $C0, $02, $20, $21
.endproc

.proc demo_scene_irq4
    color_change_irq $E0, $02, $06, $07
.endproc