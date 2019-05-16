
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

.macro fjmp target
    ldst #<.bank(target), MMC3SELECT
    ldst #>.bank(target), MMC3DATA
    jmp target
.endmacro

.macro bjmp target
    ldst #<.bank(target), bank_jump_bank
    ldst #>.bank(target), bank_jump_bank+1
    ldst #<target, bank_jump_target
    ldst #>target, bank_jump_target+1
    jmp bank_jump_launchpoint
.endmacro

.macro fjsr target
    ; ldst #<.bank(target), bank_jump_bank
    ldst #>.bank(target), bank_jump_bank+1
    ldst #<target, bank_jump_target
    ldst #>target, bank_jump_target+1

    lda #<.bank(target)
    cmp #$06
    bne branch_prg1
branch_prg0:
    jsr bank_call_launchpoint_prg0
    jmp finally
branch_prg1:
    jsr bank_call_launchpoint_prg1
finally:
.endmacro

.endif