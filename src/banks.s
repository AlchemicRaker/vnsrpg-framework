.include "nes.inc"
.include "mmc3.inc"

.export bank_jump_launchpoint, bank_jump_bank, bank_jump_target

.segment "RAM"
bank_jump_bank: .res 2
bank_jump_target: .res 2

.segment "STATICCODE"
.proc bank_jump_launchpoint
    lda bank_jump_bank
    sta MMC3SELECT
    lda bank_jump_bank+1
    sta MMC3DATA
    jmp (bank_jump_target)
.endproc
