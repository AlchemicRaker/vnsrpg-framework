; .include "mmc3.inc"

.ifndef GLOBAL_INC
.define GLOBAL_INC

; banks.s
.global bank_jump_launchpoint, bank_jump_bank, bank_jump_target
.global bank_prg0_select, bank_prg1_select
.global bank_call_launchpoint_prg0, bank_call_launchpoint_prg1


MMC3SELECT = $8002
MMC3SELECT_PRG0 = $6
MMC3SELECT_PRG1 = $7
MMC3SELECT_STATIC = %01000000
MMC3SELECT_CHR_INVERSION = %10000000

MMC3DATA = $8001

MMC3_PRG_RAM = $6000
MMC3_PRG0 = $8000
MMC3_PRG1 = $A000

IRQ_LATCH = $C000   ; schedule a scanline
IRQ_RELOAD = $C001  ; force irq on next scanline
IRQ_DISABLE = $E000 ; disable & acknowledge
IRQ_ENABLE = $E001  ; enable


PPUCTRL = $2000
PPUCTRL_OBJ_1000 = $08
PPUCTRL_NMI = $80

PPUSTATUS = $2002
OAMADDR = $2003
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007

PPUMASK = $2001
BG_CLIP = $08
BG_ON = $0A
OBJ_CLIP = $10
OBJ_ON = $14

INPUT_A      = %10000000
INPUT_B      = %01000000
INPUT_SELECT = %00100000
INPUT_START  = %00010000
INPUT_UP     = %00001000
INPUT_DOWN   = %00000100
INPUT_LEFT   = %00000010
INPUT_RIGHT  = %00000001


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
    bne @branch_prg1
@branch_prg0:
    jsr bank_call_launchpoint_prg0
    jmp @finally
@branch_prg1:
    jsr bank_call_launchpoint_prg1
@finally:
.endmacro

.macro ldst load_ref, store_ref, store_ref2
    lda load_ref
    sta store_ref
.ifnblank store_ref2
    sta store_ref2
.endif
.endmacro

.macro ldstx load_ref, store_ref, store_ref2
    ldx load_ref
    stx store_ref
.ifnblank store_ref2
    stx store_ref2
.endif
.endmacro

.macro ldsty load_ref, store_ref, store_ref2
    ldy load_ref
    sty store_ref
.ifnblank store_ref2
    sty store_ref2
.endif
.endmacro

.endif