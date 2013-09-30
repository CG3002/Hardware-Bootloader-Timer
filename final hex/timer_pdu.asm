$MOD186
$EP
NAME TIMER
; Main program for uPD70208 microcomputer system
;
; Author: 	Dr Tay Teng Tiow
; Address:     	Department of Electrical Engineering 
;         	National University of Singapore
;		10, Kent Ridge Crescent
;		Singapore 0511.	
; Date:   	6th September 1991
;
; This file contains proprietory information and cannot be copied 
; or distributed without prior permission from the author.
; =========================================================================

public	serial_rec_action, timer2_action
extrn	print_char:far, print_2hex:far, iodefine:far
extrn	LCD_INIT:far, MESSAGE_LCD:far, CLEAR_LCD:far, UPDATE_LCD_INPUT:far
extrn   set_timer2:far

;IO Setup for 80C188 
	UMCR    EQU    0FFA0H ; Upper Memory Control Register
	LMCR    EQU    0FFA2H ; Lower Memory control Register         
	PCSBA   EQU    0FFA4H ; Peripheral Chip Select Base Address
	MPCS    EQU    0FFA8H ; MMCS and PCS Alter Control Register
	A_8255  EQU    0080H
	B_8255  EQU    0081H
	C_8255  EQU    0082H
	CWR_8255  EQU    0083H
	INT0CON  EQU   0FF38H
	EOI EQU 0FF22H
	IMASK EQU 0FF28H

STACK_SEG	SEGMENT
		DB	256 DUP(?)
	TOS	LABEL	WORD
STACK_SEG	ENDS


DATA_SEG	SEGMENT
	TIMER0_MESS	DB	10,13,'TIMER2 INTERRUPT    '
	T_COUNT		DB	2FH
	T_COUNT_SET	DB	2FH
	REC_MESS	DB	10,13,'Period of timer0 =     '
	MESSAGE     DB  32 dup('h')
	M_SIZE		DB  32
	FLAG 		DB  0
	CHAR		DB  ?
	MY_ID		DB	'p1'
	ID_FLAG_@	DB	0
	ID_FLAG_p	DB	0
	REPLY_FLAG	DB 	0
	PDU_MESSAGE	DB	32 dup('?')
	PDU_COUNT	DB	0
	NEXT_LINE	DW	8 dup(' ')
	NEXT_LINE_SIZE DB 8
	ACK_MESSAGE DB '@0/'
	ACK_COUNT DB 3
DATA_SEG	ENDS


CODE_SEG	SEGMENT

	PUBLIC		START

ASSUME	CS:CODE_SEG, SS:STACK_SEG

START:
;initialize stack area
		MOV	AX,STACK_SEG		
		MOV	SS,AX
		MOV	SP,TOS

; Initialize the on-chip pheripherals
		CALL	FAR PTR	IODEFINE
		
;call set_timer2
                 STI

; ^^^^^^^^^^^^^^^^^  Start of User Main Routine  ^^^^^^^^^^^^^^^^^^
   
; Initialize MPCS to MAP peripheral to IO address
	
	MOV DX, MPCS
	MOV AX, 0083H
	OUT DX, AX

; PCSBA initial, set the parallel port start from 00H
	MOV DX, PCSBA
	MOV AX, 0003H ; Peripheral starting address 00H no READY, No Waits
	OUT DX, AX

; Initialize LMCS 
    MOV DX, LMCR
    MOV AX, 01C4H  ; Starting address 1FFFH, 8K, No waits, last shoud be 5H for 1 waits      
    OUT DX, AX

	MOV AX, DATA_SEG
	MOV DS, AX
			 
	MOV DX, CWR_8255
	MOV AX, 0080h
	OUT DX, AX
	
	MOV DX, A_8255
	MOV AL, 23h
	NOT AL
	OUT DX, AL

	
	CALL FAR PTR LCD_INIT
	
NEXT:
	; Begin	
	
	CALL FAR PTR MESSAGE_LCD
	
	
JMP NEXT


; ^^^^^^^^^^^^^^^ End of User main routine ^^^^^^^^^^^^^^^^^^^^^^^^^
SERIAL_REC_ACTION	PROC	FAR
		PUSH	CX
		PUSH 	BX
		PUSH	DS
		
		MOV	BX,DATA_SEG		;initialize data segment register
		MOV	DS,BX
		
		CMP DS:REPLY_FLAG, 1		
		JNE next_id
		CMP AL, ':'
		JE next_line_label
		CMP AL, '/'
		JE pdu_end
		CALL FAR PTR UPDATE_LCD_INPUT
		JMP id_skip
	
	next_line_label:
		MOV BX, 8
	nextlineloop:
		MOV AL, ' '
		PUSH BX
		CALL FAR PTR UPDATE_LCD_INPUT
		POP BX
		DEC BX
		JNZ nextlineloop
		JMP id_skip
	
	pdu_end:
		MOV DS:REPLY_FLAG, 0
		MOV DS:PDU_COUNT, 0
		XOR BX,BX
		XOR AX,AX
	ack:
		MOV AL,DS:ACK_MESSAGE[BX]
		CALL FAR PTR PRINT_CHAR
		INC BX
		CMP BL, DS:ACK_COUNT
		JNE ack
		JMP S_RET
		
	next_id:
		
		CMP DS:ID_FLAG_p, 1
		JNE id_flag_label
		CMP DS:MY_ID[1], AL
		JNE id_skip
		;start writing to pc
		MOV DS:REPLY_FLAG, 1
		MOV DS:ID_FLAG_p, 0
		JMP id_skip
	
	id_flag_label:
	
		CMP DS:ID_FLAG_@, 1
		JNE protocol_rec
		CMP AL,'p'
		JNE id_not_p
		MOV DS:ID_FLAG_p,1
		MOV DS:ID_FLAG_@, 0
		JMP S_RET
	id_not_p:
		MOV DS:ID_FLAG_@, 0
		JMP id_skip
		
	protocol_rec:
		CMP AL,'@'
		JNE id_skip
		MOV DS:ID_FLAG_@,1
		JMP id_skip
		
	id_skip:
		CMP AL, '~'
		JNE resume
		
		CALL FAR PTR CLEAR_LCD
		XOR BX,BX
		XOR AX,AX
	ack1:
		MOV AL,DS:ACK_MESSAGE[BX]
		CALL FAR PTR PRINT_CHAR
		INC BX
		CMP BL, DS:ACK_COUNT
		JNE ack1
	
		JMP S_RET
		resume:
		JMP S_RET
		
		continue3:
		
		CMP	AL,'<'
		JNE	S_FAST

		INC	DS:T_COUNT_SET
		INC	DS:T_COUNT_SET

		JMP	S_NEXT0
S_FAST:
		CMP	AL,'>'
		JNE	S_RET

		DEC	DS:T_COUNT_SET
		DEC	DS:T_COUNT_SET

S_NEXT0:
		MOV	CX,22			;initialize counter for message
		MOV	BX,0

S_NEXT1:	MOV	AL,DS:REC_MESS[BX]	;print message
		call	FAR ptr print_char
		INC	BX
		LOOP	S_NEXT1

		MOV	AL,DS:T_COUNT_SET	;print current period of timer0
		CALL	FAR PTR PRINT_2HEX
S_RET:
		POP	DS
		POP	BX
		POP	CX
		RET
SERIAL_REC_ACTION	ENDP



TIMER2_ACTION	PROC	FAR
		PUSH	AX
		PUSH	DS
		PUSH	BX
		PUSH	CX

		MOV	AX,DATA_SEG
		MOV	DS,AX
	
		DEC	DS:T_COUNT
		JNZ	T_NEXT1
		MOV	AL,DS:T_COUNT_SET
		MOV	DS:T_COUNT,AL

		MOV	CX,20
		MOV	BX,0H
T_NEXT0:
		MOV	AL,DS:TIMER0_MESS[BX]
		INC	BX
		CALL 	FAR PTR PRINT_CHAR
		LOOP	T_NEXT0

T_NEXT1:	
		POP	CX
		POP	BX
		POP	DS
		POP 	AX
		RET
TIMER2_ACTION	ENDP


CODE_SEG	ENDS
END