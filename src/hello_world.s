.include "nes.inc"

.segment "ZEROPAGE"

frame_counter: .res 1

.segment "STATICCODE"
.proc reset_handler

init_interrupts:
	sei
init_clear_ppu_state:
	ldx #$00
	stx PPUCTRL		; Disable NMI and VRAM increment to 32??
	stx PPUMASK		; Disable rendering
init_dmc_state:
	stx $4010		; Disable DMC IRQ
init_stack:
	dex				; x--, = $FF
	txs				; stack pointer = $01FF

	bit PPUSTATUS	; Acknowledge stray vblank NMI across reset_handler
	bit SNDCHN		; Acknowledge DMC IRQ
init_apu:
	lda #$40
	sta P2			; Disable APU Frame IRQ
	lda #$0F
	sta SNDCHN		; Disable DMC playback, initialize other channels

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
	; jmp main_loop
	
	lda #VBLANK_NMI
	sta PPUCTRL

	lda #BG_ON
	sta PPUMASK

init_start_ppu:
	cli				; Enable interrupts

	lda #$25		
	sta frame_counter

main_loop:
	jmp main_loop

.endproc

.proc nmi_handler
	lda #$3F
	sta PPUADDR
	lda #$00
	sta PPUADDR
	lda frame_counter
	sta PPUDATA
	; inc frame_counter ; party mode
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
