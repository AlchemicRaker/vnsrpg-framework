.include "global.inc"

.export main, nmi_handler, irq_handler, next_scene_bank, next_scene_point, scene_nmi, scene_irq
.import sample_ppu, demo_scene_load_point, demo_scene_irq
.export irq_next_scanline, irq_table_address
.exportzp irq_table_scanline, irq_next_index

.segment "ZEROPAGE"

frame_counter: .res 1
irq_next_address: .res 2
irq_table_scanline: .res 8 ; works with irq_table_address; with with an $FF
irq_next_index: .res 1 ; index of the table coming up/currently

.segment "RAM"
irq_table_address: .res 16 ; 8 addresses
next_scene_bank: .res 2
next_scene_point: .res 2
post_nmi_flag: .res 1
dummy: .res 2

nmi_save_a: .res 1
nmi_save_x: .res 1
nmi_save_y: .res 1

scene_nmi: .res 2

scene_irq: .res 2
irq_next_scanline: .res 1 ; track the coming up/current scanline


irq_save_a: .res 1
irq_save_x: .res 1
irq_save_y: .res 1

main_loop_ram: .res 1
main_loop_address: .res 2

.segment "INITBANK2"
.proc bank_switch_far_call_test
    rts 
.endproc

.segment "STATICCODE"
.proc main
    cli

    ldstword .bank(demo_scene_load_point), next_scene_bank
    ldstword demo_scene_load_point, next_scene_point

    ;put the main loop into RAM

    ldst #$4C, main_loop_ram ; copy the JMP command into place 
    
    jmp main_enter_scene

main_loop_enter:
    ldstword main_loop_ram, main_loop_address ; modify the JMP command

main_loop:
    .repeat 1
    nop
    .endrepeat
    jmp main_loop_ram
    
main_loop_def:
    jmp main_loop_def
    ; jmp (main_address)
    ; lda post_nmi_flag
    ; cmp #$00
    ; beq main_loop ; loop until post_nmi_flag is set

.export main_enter_scene
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

    ; sta irq_next_scanline ; first scanline's value is the next scanline

    ; set the latch for the next hblank
    ; lda irq_table_scanline+1 
    ; sta IRQ_LATCH


    ; ldst #$01, post_nmi_flag
.import main_enter_scene
    ldstword main_enter_scene, main_loop_address

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
    stx irq_next_index

    lda irq_table_scanline,X
    sta IRQ_LATCH
    sta IRQ_RELOAD
    sta IRQ_ENABLE

    jmp (irq_next_address)

irq_rts:
    lda irq_next_index
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
