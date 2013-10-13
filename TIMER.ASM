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
	MESSAGE     DB  32 dup('h')
	M_SIZE		DB  32
	INPUT       DB  32 dup('q')
	INPUT_SIZE  DB  0
	FLAG 		DB  0
	CHAR		DB  ?
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
		
call set_timer2
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
	
	
	; XOR AX, AX
	; MOV AL, DS:M_SIZE1
	; MOV DS:M_SIZE, AL
	
	; displayloop:
	; XOR BX, BX
	; MOV BL, DS:M_SIZE1
	; SUB BL, AL

	; MOV DL, DS:MESSAGE_1[BX]
	; MOV DS:MESSAGE[BX], DL
	
	; DEC AL
	; JNZ displayloop
	
	CALL FAR PTR MESSAGE_LCD
	
	
JMP NEXT

LCD_INIT PROC FAR

	; LCD Initialization ;

;Function set 1;
; 60 ms delay ;
	MOV CX, 0AA75h ; 43637 dec
	loop60ms:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop60ms ; 16 clocks
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00111100b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	

;Function set 2;
; 5 ms delay;
	MOV CX, 0E35h ; 3637 dec
	loop5ms:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop5ms ; 16 clocks
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00111100b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	
;Function set 3;
; 100 us delay;
	MOV CX, 0049h ; 73 dec
	loop4point100us:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop4point100us ; 16 clocks
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00111100b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
		
	; 40 us delay;
	MOV CX, 001Eh ; 30 dec
	loop40us:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop40us ; 16 clocks
	
	;Display Clear;
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000001b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	; 1.6ms delay;
	MOV CX, 048Ch ; 30 dec
	loop1point6ms:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop1point6ms ; 16 clocks
	
	
	;Entry Mode Set;
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000110b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	; 40 us delay;
	MOV CX, 001Eh ; 30 dec
	loop40us2:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop40us2 ; 16 clocks
	
	
	;Setting Address of DDRAM;
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 10000000b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	; 40 us delay;
	MOV CX, 001Eh ; 30 dec
	loop40us3:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop40us3 ; 16 clocks
	
	
	;Display On;
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00001100b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	; 40 us delay;
	MOV CX, 001Eh ; 30 dec
	loop40us4:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop40us4 ; 16 clocks
	

RET
LCD_INIT ENDP

MESSAGE_LCD	PROC FAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX

	;Display Clear;
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000001b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	; 1.6ms delay;
	MOV CX, 048Ch ; 30 dec
	loop1point6ms2:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop1point6ms2 ; 16 clocks
	
	XOR BX, BX
	MOV BL, DS:INPUT_SIZE
	CMP BL, 0
	JNE display
	JMP overfunc
	
	display:
	XOR DX, DX
	MOV DL, DS:INPUT_SIZE
	SUB DL, BL
	CMP DL, 10h
	JE address
	JMP continue
	
	address:
	;Setting Addres of DDRAM;	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 11000000b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	; 40 us delay;
	MOV CX, 001Eh ; 30 dec
	loop40us30:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop40us30 ; 16 clocks
	
	continue:
	;Letter Begin;
	
	;Writing Data to DDRAM;
	XOR AX, AX
	MOV AL, 10100000b
	MOV DX, B_8255
	OUT DX, AL
	
	MOV DX, BX
	MOV BL, DS:INPUT_SIZE
	SUB BL, DL
	XOR AX, AX
	MOV AL, DS:INPUT[BX]
	MOV BX, DX
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 10000000b
	MOV DX, B_8255
	OUT DX, AL
	
	;Letter End;

; 40 us delay;
	MOV CX, 001Eh ; 30 dec
	loop40us5:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop40us5 ; 16 clocks

	DEC BX
	JNZ display
	
	; 40 us delay;
	MOV CX, 0FFFFh ; 30 dec
	looplong:	
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clocks
		NOP	   ; 3 clock
		DEC CX	   ; 3 clocks
	JNZ looplong ; 16 clocks
	
	;Display Clear;
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000001b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	; 1.6ms delay;
	MOV CX, 048Ch ; 30 dec
	loop1point6ms3:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop1point6ms3 ; 16 clocks
overfunc:
	POP DX
	POP CX
	POP BX
	POP AX
	RET
MESSAGE_LCD	ENDP

CLEAR_LCD PROC FAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	;Display Clear;
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000001b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	; 1.6ms delay;
	MOV CX, 048Ch ; 30 dec
	loop1point6ms2_1:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop1point6ms2_1 ; 16 clocks
	
	;Setting Address of DDRAM;
	
	XOR AX, AX
	MOV AL, 00100000b
	MOV DX, B_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 10000000b
	MOV DX, C_8255
	OUT DX, AL
	
	XOR AX, AX
	MOV AL, 00000000b
	MOV DX, B_8255
	OUT DX, AL
	
	; 40 us delay;
	MOV CX, 001Eh ; 30 dec
	loop40us3_1:	
		NOP	   ; 3 clocks
		DEC CX	   ; 3 clocks
	JNZ loop40us3_1 ; 16 clocks
	
	MOV BL, 0
	MOV DS:INPUT_SIZE, BL
	
	POP DX
	POP CX
	POP BX
	POP AX
RET
CLEAR_LCD ENDP

; ^^^^^^^^^^^^^^^ End of User main routine ^^^^^^^^^^^^^^^^^^^^^^^^^
SERIAL_REC_ACTION	PROC	FAR
		PUSH	CX
		PUSH 	BX
		PUSH	DS
		
		MOV	BX,DATA_SEG		;initialize data segment register
		MOV	DS,BX
		
		CMP AL, '~'
		JNE resume
		
		CALL FAR PTR CLEAR_LCD
		JMP S_RET
		
		resume:
		XOR BX, BX
		MOV BL, DS:INPUT_SIZE
		MOV DS:INPUT[BX], AL
		INC BL
		MOV DS:INPUT_SIZE, BL
		
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
