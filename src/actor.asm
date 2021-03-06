INCLUDE "hardware.inc"

INCLUDE "kernel.inc"
INCLUDE "actor.inc"

SECTION "Actor WRAM Data", WRAM0

Actor_Top:: dw
Actor_This:: dw
Actor_Pipeline_Signal:: dw

SECTION "Actor ROM0", ROM0

Actor_Pipeline_Begin::
; Call the Pipeline Method on each Actor from the Top
; de <~> Method signal
; bc <~ This

	; Set Actor_Pipeline_Signal
	push de
	POKE_WORD (Actor_Pipeline_Signal)

	; Set This to Top and put in HL
	PEEK_WORD (Actor_Top)
	POKE_WORD (Actor_This)
	ld b, d
	ld c, e

	; Put Actor_Pipeline_Signal in BC
	pop de

	jp Actor_Pipeline_CallMethod

Actor_Pipeline_Next::
; Get the next Actor to call the Pipeline method on
; bc <~ Actor_Pipeline_Signal
; hl <~ This->Next
	ACTOR_THIS

	; If we're at the end of the Actors, we break
	MEMBER_PEEK_WORD (ACTOR_NEXT)
	ld a, e
	or d
	ret z

	; Make it the new This
	POKE_WORD (Actor_This)
	ld b, d
	ld c, e

	; Put Actor_Pipeline_Signal in DE
	PEEK_WORD (Actor_Pipeline_Signal)

	jp Actor_Pipeline_CallMethod

Actor_Pipeline_CallMethod:
; bc ~> This
; de ~> Actor_Pipeline_Signal
	; Preserve Actor_Pipeline_Signal
	push de

	; Add the Signal to the type to get to correct callback
	MEMBER_PEEK_WORD (ACTOR_TYPE)
	ld h, d
	ld l, e
	pop de
	add hl, de

	; Put the callback in DE
	ld e, [hl]
	inc hl
	ld d, [hl]

	; Otherwise call the callback
	ld h, d
	ld l, e

	jp hl

Actor_Spawn::
; bc ~> Size
; bc <~ Data address
; Put the value of Top in HL and push to the stack

	; Get the old Top and push it to the stack
	PEEK_WORD (Actor_Top)
	push de

	; If the Top is empty
	ld a, e
	or d
	jr nz, .continue

	; then start at ACTOR_SPACE_START
	ld de, ACTOR_SPACE_START

.continue
	; Put Size in HL
	ld h, b
	ld l, c

	; Put new Top in DE
	SUB_WORD

	; Set Top to the new Top
	POKE_WORD (Actor_Top)

	; Load the old Top in to the new Top's next
	ld b, d
	ld c, e
	pop de
	MEMBER_POKE_WORD (ACTOR_NEXT)

	ret
