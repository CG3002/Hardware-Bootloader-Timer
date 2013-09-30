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

; LCD Initialization ;

;Function set 1;
; 45 ms delay ;
	MOV CX, 7FD8h ; 32728 dec
	loop45ms:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop45ms ; 16 clocks
	
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0030h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	

;Function set 2;
; 4.5 ms delay;
	MOV CX, 0CC9h ; 3273 dec
	loop4point5ms:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop4point5ms ; 16 clocks
	
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0030h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	
;Function set 3;
; 100 us delay;
	MOV CX, 0049h ; 73 dec
	loop4point100us:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop4point100us ; 16 clocks
	
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0030h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Function set: Font and Number of display lines;
	
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 003Ch
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Display Off;
	
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0008h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Display Clear;
	
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0001h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Entry Mode Set;
	
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0006h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	
	
	
	;Letter Begin;
	
	;Setting Addres of DDRAM;
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0080h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Writing Data to DDRAM;
	MOV AX, 00A0h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0084h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Letter End;	
	
	
	;Letter Begin;
	
	;Setting Addres of DDRAM;
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0081h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Writing Data to DDRAM;
	MOV AX, 00A0h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0014h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Letter End;	
	
	
	;Letter Begin;
	
	;Setting Addres of DDRAM;
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0082h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Writing Data to DDRAM;
	MOV AX, 00A0h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0034h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Letter End;	
	
	
	;Letter Begin;
	
	;Setting Addres of DDRAM;
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0083h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Writing Data to DDRAM;
	MOV AX, 00A0h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 00B4h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Letter End;	
	
	
	;Letter Begin;
	
	;Setting Addres of DDRAM;
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0084h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Writing Data to DDRAM;
	MOV AX, 00A0h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0054h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Letter End;	
	
	
	;Letter Begin;
	
	;Setting Addres of DDRAM;
	MOV AX, 0020h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0085h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Writing Data to DDRAM;
	MOV AX, 00A0h
	MOV DX, B_8255
	OUT DX, AX
	
	MOV AX, 0025h
	MOV DX, C_8255
	OUT DX, AX
	
	MOV AX, 0000h
	MOV DX, B_8255
	OUT DX, AX
	
	;Letter End;	
	

	
NEXT:     JMP NEXT

; ^^^^^^^^^^^^^^^ End of User main routine ^^^^^^^^^^^^^^^^^^^^^^^^^
SERIAL_REC_ACTION	PROC	FAR
		PUSH	CX
		PUSH 	BX
		PUSH	DS

		MOV	BX,DATA_SEG		;initialize data segment register
		MOV	DS,BX

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
