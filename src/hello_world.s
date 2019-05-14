.include "nes.inc"

.segment "STATICCODE"
.proc reset_handler
	
	sei				; clear all interrupts
	ldx #$00
	stx PPUCTRL		; Disable NMI and VRAM increment to 32??
	stx PPUMASK		; Disable rendering
	stx $4010		; Disable DMC IRQ??
	dex				; x--, = $FF
	txs				; stack pointer = $01FF
	bit PPUSTATUS	; Acknowledge stray vblank NMI across reset_handler
	bit SNDCHN		; Acknowledge DMC IRQ
	lda #$40
	sta P2			; Disable APU Frame IRQ
	lda #$0F
	sta SNDCHN		; Disable DMC playback, initialize other channels

vwait1:
	bit PPUSTATUS
	bpl vwait1

	cld

	ldx #0
	txa

vwait2:
	bit PPUSTATUS
	bpl vwait2
	;jmp main

init_color:
	; set background palette during vblank

mainloop:
	jmp mainloop

.endproc

.proc nmi_handler
        rti
.endproc

.proc irq_handler
        rti
.endproc

.segment "NMIVECTOR"
.addr nmi_handler

.segment "RESETVECTOR"
.addr reset_handler

.segment "IRQVECTOR"
.addr irq_handler
