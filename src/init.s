.include "nes.inc"
.include "mmc3.inc"

.export mmc3_init
.import main

.segment "MMC3_INIT"
.proc mmc3_init
    sei                 ; Disable interrupts
    ; Using a far jump preps the 16KB static bank
    ; And also tucks the init code into a bank
    fjmp reset_handler
.endproc

.segment "INITBANK"
.proc reset_handler
init_clear_ppu_state:
    ldx #$00
    stx PPUCTRL     ; Disable NMI and VRAM increment to 32??
    stx PPUMASK     ; Disable rendering
init_dmc_state:
    stx $4010       ; Disable DMC IRQ
init_stack:
    dex             ; x--, = $FF
    txs             ; stack pointer = $01FF

    bit PPUSTATUS   ; Acknowledge stray vblank NMI across reset_handler
    bit SNDCHN      ; Acknowledge DMC IRQ
init_apu:
    lda #$40
    sta P2          ; Disable APU Frame IRQ
    lda #$0F
    sta SNDCHN      ; Disable DMC playback, initialize other channels

vwait1:
    bit PPUSTATUS
    bpl vwait1

init_clear_ram:
    cld
    ldx #$00
    ; TODO: clear OAM
    txa

vwait2:
    bit PPUSTATUS
    bpl vwait2
    
    lda #VBLANK_NMI
    sta PPUCTRL

    lda #BG_ON
    sta PPUMASK

    jmp main

.endproc