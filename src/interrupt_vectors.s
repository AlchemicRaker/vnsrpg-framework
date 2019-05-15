.include "nes.inc"
.include "mmc3.inc"

.import nmi_handler, reset_handler, irq_handler

.segment "MMC3_INIT"
.proc mmc3_init         ; make the 16KB static PRG, and load banks 0 and 1
    sei
    lda MMC3SEL_STATIC | MMC3SEL_PRG0
    sta MMC3SELECT
    lda #$0
    sta MMC3DATA
    lda MMC3SEL_STATIC | MMC3SEL_PRG1
    sta MMC3SELECT
    lda #$1
    sta MMC3DATA
    jmp reset_handler
.endproc

.segment "VECTORS"
.addr nmi_handler, mmc3_init, irq_handler