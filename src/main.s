.include "global.inc"

.export main, nmi_handler, irq_handler, next_scene_bank, next_scene_point, scene_nmi, scene_irq
.import sample_ppu, demo_scene_load_point, demo_scene_irq
.export irq_table_address, irq_table_scanline, irq_next_index, irq_next_scanline

.segment "ZEROPAGE"

frame_counter: .res 1
irq_next_address: .res 2

.segment "RAM"
next_scene_bank: .res 2
next_scene_point: .res 2
post_nmi_flag: .res 1
dummy: .res 2

nmi_save_a: .res 1
nmi_save_x: .res 1
nmi_save_y: .res 1

scene_nmi: .res 2

scene_irq: .res 2
irq_next_index: .res 1 ; index of the table coming up/currently
irq_next_scanline: .res 1 ; track the coming up/current scanline

irq_table_address: .res 16 ; 8 addresses
irq_table_scanline: .res 8 ; works with irq_table_address; with with an $FF

irq_save_a: .res 1
irq_save_x: .res 1
irq_save_y: .res 1

.segment "INITBANK2"
.proc bank_switch_far_call_test
    rts 
.endproc

.segment "STATICCODE"
.proc main
    cli

    ldstword .bank(demo_scene_load_point), next_scene_bank
    ldstword demo_scene_load_point, next_scene_point

    jmp main_enter_scene

main_loop_enter:
    ldst #$00, post_nmi_flag
main_loop:
    lda post_nmi_flag
    cmp #$00
    beq main_loop ; loop until post_nmi_flag is set
main_enter_scene:
    lda next_scene_bank
    cmp #$06
    bne main_enter_prg1

main_enter_prg0:
    ; store the current bank on the stack
    ldph bank_prg0_select
    ldst #$06, MMC3SELECT
    
    ; set the new bank into ram and MMC3DATA
    ldst next_scene_bank+1, bank_prg0_select, MMC3DATA

    mjsr (next_scene_point)
    plst bank_prg0_select, MMC3DATA
    jmp main_loop_enter

main_enter_prg1:
    ; store the current bank on the stack
    ldph bank_prg1_select
    ldst #$07, MMC3SELECT
    
    ; set the new bank into ram and MMC3DATA
    ldst next_scene_bank+1, bank_prg1_select, MMC3DATA

    mjsr (next_scene_point)
    plst bank_prg1_select, MMC3DATA
    jmp main_loop_enter

.endproc

.proc nmi_handler ; vblank
    ; nmi_handlers should be in static code, so we don't waste any time bank switching

    ; save registers
    sta nmi_save_a
    stx nmi_save_x
    sty nmi_save_y

    mjsr (scene_nmi)

load_first_irq:
    sta IRQ_DISABLE

    ldstx #$00, irq_next_index

    ldst irq_table_address, irq_next_address
    ldst irq_table_address+1, irq_next_address+1
    
    lda irq_table_scanline ; usually offset by irq_next_index but not for first one
    sta IRQ_LATCH
    sta IRQ_RELOAD
    sta IRQ_ENABLE

    sta irq_next_scanline ; first scanline's value is the next scanline

    ; set the latch for the next hblank
    ; lda irq_table_scanline+1 
    ; sta IRQ_LATCH


    ldst #$01, post_nmi_flag
    ; restore registers
    lda nmi_save_a
    ldx nmi_save_x
    ldy nmi_save_y
    rti
.endproc

;so, update 1 palette color per row
;rest of the row can render
;however, the scroll cannot be restored to the bottom half of a row of tiles
;a separate bank with offset UI tiles can be used to draw the bottom half of the row
;bank switch *before* the hblank it becomes necessary
;back switch back before the next row of tiles, somehow.
.proc irq_handler
.export irq_rts

    sta irq_save_a
    stx irq_save_x
    sty irq_save_y

    sta IRQ_DISABLE

    ; set the next IRQ_LATCH now
    ldx irq_next_index
    inx
    lda irq_table_scanline,X
    sta IRQ_LATCH
    sta IRQ_RELOAD

    jmp (irq_next_address)
    ; jmp irq_handlerj
irq_rts:
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; lda irq_save_a
    ; sta IRQ_ENABLE
    rti

    ; advance the index, load the next scanline
    ; if the scanline isn't $FF, prepare for another handler, otherwise disable IRQ
    lda irq_next_scanline
    ldx irq_next_index
    inx
    clc
    adc irq_table_scanline,X
    bcs irq_handler_end

    ; store the new values
    sta irq_next_scanline
    stx irq_next_index 

    ; irq_next_address = irq_table_address[irq_next_index*2]
    txa
    asl A
    tax
    lda irq_table_address,X
    sta irq_next_address
    lda irq_table_address+1,X
    sta irq_next_address+1

irq_handler_end:
    lda irq_save_a
    ldx irq_save_x
    ldy irq_save_y
    rti
.endproc




.proc irq_handlerj
.import irq_rts
;burn until a specific column is passed
.repeat 93 ;92 for 2 palettes, 
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

    ; sta IRQ_DISABLE
    ; rti
    jmp irq_rts
.endproc


.proc irq_handlerg
;burn until a specific column is passed
crap:
    jmp foo
    jmp crap
foo:
.repeat 95 ;92 for 2 palettes, 
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

