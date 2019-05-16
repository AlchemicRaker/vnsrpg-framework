
.ifndef MMC3_INC
.define MMC3_INC 1

MMC3SELECT = $8002
MMC3SEL_PRG0 = $6
MMC3SEL_PRG1 = $7
MMC3SEL_STATIC = %01000000
MMC3SEL_CHR_INVERSION = %10000000

MMC3DATA = $8001

MMC3_PRG_RAM = $6000
MMC3_PRG0 = $8000
MMC3_PRG1 = $A000

.import bank_jump_launchpoint, bank_jump_bank, bank_jump_target

.macro fjmp target
    lda #<.bank(target)
    sta MMC3SELECT
    lda #>.bank(target)
    sta MMC3DATA
    jmp target
.endmacro

.macro bjmp target
    lda #<.bank(target)
    sta bank_jump_bank
    lda #>.bank(target)
    sta bank_jump_bank+1
    lda #<target
    sta bank_jump_target
    lda #>target
    sta bank_jump_target+1
    jmp bank_jump_launchpoint
.endmacro

.endif