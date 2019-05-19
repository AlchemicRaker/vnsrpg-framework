.include "global.inc"

.export main, nmi_handler, irq_handler
.import sample_ppu, demo_scene_load_point

.segment "ZEROPAGE"

frame_counter: .res 1

.segment "RAM"
next_scene_bank: .res 2
next_scene_point: .res 2
post_nmi_flag: .res 1
dummy: .res 2

nmi_save_a: .res 1
nmi_save_x: .res 1
nmi_save_y: .res 1

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
    ; save registers
    sta nmi_save_a
    stx nmi_save_x
    sty nmi_save_y
    ; jsr to scene nmi handler/table

    sta IRQ_DISABLE
    lda #$3F      ; scanline 68 (halfway through row 9)
    sta IRQ_LATCH
    sta IRQ_RELOAD
    sta IRQ_ENABLE
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
;burn until a specific column is passed
.repeat 95 ;92 for 2 palettes, 
    nop
.endrepeat
    
    ; prep registers and writes
    bit PPUSTATUS

    ldx #$20 ; new palette color

    ldyppuaddr1 $00, $40, $0 ; prep restore 1

    ldst #$3F, PPUADDR ; write 1

    ldst #$00, PPUMASK ; disable rendering

    lda #$02 ; palette color index

    ; critical update time

    sta PPUADDR
    stx PPUDATA
    ; ldx #$24      ;try to jam a second one in?
    ; stx PPUDATA   ;taste the rainbow!
    sty PPUADDR     ; restore 1
    ldyppuaddr2 $00, $40, $0
    sty PPUADDR     ; restore 2
    ; critical time done

    lda #BG_ON
    sta PPUMASK

    sta IRQ_DISABLE
    rti
.endproc
