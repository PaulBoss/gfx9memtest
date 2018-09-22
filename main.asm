BDOS: EQU 0x05

CHGMOD: EQU 0x5F

CALSLT: EQU    0x001C
EXPTBL: EQU    0xFCC1

; BDOS calls
_CONOUT: EQU 0x02
_STROUT: EQU 0x09

; V9990 ports
P0: EQU 0x60
P1: EQU 0X61
P2: EQU 0X62
P3: EQU 0X63
P4: EQU 0X64
P5: EQU 0X65
P6: EQU 0X66
P7: EQU 0X67
PF: EQU 0X6F


	org 0x100


	LD A,0
	LD (FIRST8OK), A
	LD (SND8OK), A

	LD A,5
	; Interslot call to the BIOS.
	ld     iy,(EXPTBL-1)       ;BIOS slot in iyh
	ld     ix,CHGMOD             ;address of BIOS routine
	call   CALSLT              ;interslot call

	LD A,0
	LD HL,0
	CALL SetVdp_Write
	
; DBC = Address to check
; L = verifier count. Reset every 8 checks. If 8 checks where succesfull
;     put a green pixel, else put a red pixel
	LD D, 0
	LD L, 0
TESTLOOP1:
	LD BC, 0

TESTLOOP2:
	
	
DONTPRINT:
	CALL CHECKADDRESS
	JP Z, ADDRESSOK
	; Not ok.

	LD A, C
	AND 16
	JP NZ, SECOND
	LD A, 1
	LD (FIRST8OK), A
SECOND:
	LD A, 1
	LD (SND8OK), A
	
ADDRESSOK


	LD A, C
	AND 31
	CP 31
	JP NZ, CONTINUE
	
	; Write 2 pixels to the screen
	CALL WRITETOSCREEN
	; Reset vars
	LD A,0
	LD (FIRST8OK), A
	LD (SND8OK), A

CONTINUE:	
	INC BC
	LD A,B
	OR C
	JP NZ, TESTLOOP2
	INC D
	LD A,8
	CP D
	JP NZ, TESTLOOP1


	LD A,0
	; Interslot call to the BIOS.
	ld     iy,(EXPTBL-1)       ;BIOS slot in iyh
    ld     ix,CHGMOD             ;address of BIOS routine
    call   CALSLT              ;interslot call

	
	LD DE, TXT_DONE
	LD C, _STROUT
	CALL BDOS
	RET

; Check address in DBC
; Changes:
;   AF
; IN:
;    DBC: Address to check
; OUT: 
;   ZERO = OK
;   NON ZERO: Not Ok
CHECKADDRESS:
	LD A, 0
	OUT (0x64), A
	CALL SETADDR
	LD A, %10101010
	OUT (0x60), A
	
	LD A,3
	OUT (0x64),A
	CALL SETADDR
	
	IN A,(0x60)
	CP %10101010
	RET
	
ENDERROR:
	PUSH DE
	PUSH BC
	
	LD DE, TXT_ERROR
	LD C, _STROUT
	CALL BDOS
	
	POP BC
	POP DE
	
	CALL DISPADDR
	
	RET


DISPADDR:
	LD A, D
	CALL DISPA
	LD A, 32
	CALL PUTCHAR
	LD A, B
	CALL DISPA
	LD A, 32
	CALL PUTCHAR
	
	LD A, C
	CALL DISPA
	LD A, 32
	CALL PUTCHAR
	
	RET
	

; Point to VRAM Address in DBC
; Changes AF
SETADDR:
	LD A, C
	OUT (0x63),A
	LD A, B
	OUT (0x63),A
	LD A, D
	OUT (0x63),A
	RET

; 	
DISPA:
	PUSH BC
	PUSH DE
	CALL DISPA2
	POP DE
	POP BC
	RET
	
DISPA2:

	ld	c,-100
	call	Na1
	ld	c,-10
	call	Na1
	ld	c,-1
Na1:	ld	b,'0'-1
Na2:	inc	b
	add	a,c
	jr	c,Na2
	sub	c		;works as add 100/10/1
	push af		;safer than ld c,a
	ld	a,b		;char is in b
	CALL	PUTCHAR	;plot a char. Replace with bcall(_PutC) or similar.
	pop af		;safer than ld a,c
	ret

PUTCHAR:
	PUSH DE
	PUSH BC
	
	LD E, A
	LD C, _CONOUT
	CALL BDOS
	
	POP BC
	POP DE
	
	RET

; Print 2 pixels
WRITETOSCREEN:
	LD A, (FIRST8OK)
	CP 0
	JP Z, GREEN1
	LD L, 8
	JP NEXTPIXEL
GREEN1:
	LD L, 2
	
NEXTPIXEL:	
	SLA L
	SLA L
	SLA L
	SLA L
	
	LD A, (SND8OK)
	CP 0
	JP Z, GREEN2
	LD A, 8
	JP PUTPIXELS
GREEN2:
	LD A, 2
	
PUTPIXELS:	
	OR L
	OUT (0x98),A 
	LD L,0
	RET


; VDP Routines
;
;Set VDP address counter to write from address AHL (17-bit)
;Enables the interrupts
;
SetVdp_Write:
	rlc	h
	rla
	rlc	h
	rla
	srl	h
	srl	h
	di
	out	(#99),a
	ld	a,14+128
	out	(#99),a
	ld	a,l
	nop
	out	(#99),a
	ld	a,h
	or	64
	ei
	out	(#99),a
	ret


TXT_ERROR: DB 13,10,"Error.",13,10,"$"
TXT_DONE: DB 13,30,"Done.",13,10,"$"	
	

FIRST8OK: DS VIRTUAL 1
SND8OK: DS VIRTUAL 1

