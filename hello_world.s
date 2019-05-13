.segment "STATICCODE"
.proc reset_handler
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
