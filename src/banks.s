.include "global.inc"

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

.macro bank_call_launchpoint bank_select, mmc3_value
    ; store the current bank on the stack
    ldph bank_select
    ldst #mmc3_value | MMC3SELECT_DEFAULTS, MMC3SELECT
    
    ; set the new bank into ram
    ; select the new bank in MMC3DATA
    ldst bank_jump_bank+1, bank_select, MMC3DATA          

    mjsr (bank_jump_target)

    ldst #mmc3_value | MMC3SELECT_DEFAULTS, MMC3SELECT
    ; pop the previous bank from the stack
    ; put it into RAM and MMC3DATA
    plst bank_select, MMC3DATA
    rts
.endmacro

.proc bank_call_launchpoint_prg0
    bank_call_launchpoint bank_prg0_select, $06
.endproc


.proc bank_call_launchpoint_prg1
    bank_call_launchpoint bank_prg1_select, $07
.endproc