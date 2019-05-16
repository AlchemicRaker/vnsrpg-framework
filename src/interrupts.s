.include "nes.inc"
.import nmi_handler, mmc3_init, irq_handler

.segment "VECTORS"
.addr nmi_handler, mmc3_init, irq_handler