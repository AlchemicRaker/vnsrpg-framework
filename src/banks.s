; .include "nes.inc"
; .include "mmc3.inc"
.include "global.inc"

; .export bank_jump_launchpoint, bank_jump_bank, bank_jump_target, bank_prg0_select, bank_prg1_select, bank_call_launchpoint_prg0, bank_call_launchpoint_prg1

.segment "RAM"
bank_jump_bank: .res 2
bank_jump_target: .res 2
bank_prg0_select: .res 1
bank_prg1_select: .res 1

.segment "STATICCODE"

.proc bank_jump_launchpoint
    ldst bank_jump_bank, MMC3SELECT
    ldst bank_jump_bank+1, MMC3DATA
    jmp (bank_jump_target)
.endproc

bank_call_launchpoint_table:
; .repeat 6
;     .word $0000
; .endrepeat
;     .addr bank_call_launchpoint_prg0
;     .addr bank_call_launchpoint_prg1

.proc bank_call_launchpoint_prg0
    ; store the current bank on the stack
    lda bank_prg0_select
    pha
    ldst #$06, MMC3SELECT
    
    ; set the new bank into ram
    ; select the new bank in MMC3DATA
    ldst bank_jump_bank+1, bank_prg0_select, MMC3DATA          

    ; manual jsr, with an indirect target
    lda #>(resolve-1)
    pha
    lda #<(resolve-1)
    pha
    jmp (bank_jump_target)

resolve:
    ldst #$06, MMC3SELECT
    ; pop the previous bank from the stack
    pla
    sta bank_prg0_select    ; write previous bank into ram
    sta MMC3DATA            ; select previous bank in MMC3DATA
    rts
.endproc


.proc bank_call_launchpoint_prg1
    ; store the current bank on the stack
    lda bank_prg1_select
    pha
    ldst #$07, MMC3SELECT
    
    ; set the new bank into ram
    ; select the new bank in MMC3DATA
    ldst bank_jump_bank+1, bank_prg1_select, MMC3DATA          

    ; manual jsr, with an indirect target
    lda #>(resolve-1)
    pha
    lda #<(resolve-1)
    pha
    jmp (bank_jump_target)

resolve:
    ldst #$07, MMC3SELECT
    ; pop the previous bank from the stack
    pla
    sta bank_prg1_select    ; write previous bank into ram
    sta MMC3DATA            ; select previous bank in MMC3DATA
    rts
.endproc