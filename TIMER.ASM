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
	MMCS	EQU    0FFA6H 
	DAC EQU 4000H


STACK_SEG	SEGMENT
		DB	512 DUP(?)
	TOS	LABEL	WORD
STACK_SEG	ENDS


DATA_SEG	SEGMENT
	TIMER0_MESS	DB	10,13,'TIMER2 INTERRUPT    '
	T_COUNT		DB	24
	T_COUNT_SET	DB	24
	REC_MESS	DB	10,13,'Period of timer0 =     '
	MESSAGE     DB  32 dup('h')
	KEYPAD_INPUT DB  0,0,0,0,0,0,0,0
	BCD_MESSAGE DB  0,0,0,0,0,0
	ENABLE_BYTE DB  11111110b
	BCD_INDEX   DB  0
	KEYPAD_INDEX DW 0
	M_SIZE		DB  32
	FLAG 		DB  1
	CHAR		DB  ?
	REG_AL		DB  ?
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

;Initialize MMCS
	
	MOV DX, MMCS
	MOV AX, 4003H
	OUT DX, AX

; Initialize MPCS to MAP peripheral to IO address
	
	MOV DX, MPCS
	MOV AX, 2083H
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
	MOV AX, 0082h
	OUT DX, AX
	
NEXT:
	WAIT_1:MOV AH,03H
		   MOV DS:REG_AL,AH
		   
	      MOV BX, 0000H
		   MOV DX,C_8255
		   MOV AL,BL
		   OUT DX,AL
		   
		  MOV DX,B_8255
		  IN AL,DX
		  MOV BL,AL  
		  AND BL,0FCH
		  CMP BL,0FCH
		 
	JE WAIT_1
	
	CALL FAR PTR KEYPAD_LOOP
JMP NEXT

KEYPAD_LOOP PROC FAR
PUSH AX
PUSH BX
PUSH CX
PUSH DX
			 
		  CALL  FAR PTR DEBOUNCE
		 
		  MOV BL, 0FEH
		  MOV BH, 04H
		   
	NXTROW: ROL BL,07H
			MOV CH,BL
			MOV DX,C_8255
			CLI
			MOV AL,BL
			OUT DX,AL
			STI
			
			MOV DX,B_8255
			IN AL,DX
			MOV BL,AL
			AND BL,0FCH
			MOV CL,06H
			RCR BL,02H
	NXTCOL: RCR BL,01H
			JNC CODEKY
			DEC DS:REG_AL
			DEC CL
			CMP CL,03H
			JE KEYPAD_2
			
			CMP CL, 0H
			JE SUBTRACT
			JMP NXTCOL
			
			MOV BL,CH
			DEC BH
			JNZ NXTROW
			JMP RETURN
	 CODEKY:
			MOV CL, DS:REG_AL
		
			MOV DL, DS:FLAG
			CMP DL, 0
			JE zero_part
			MOV DL, 0
			MOV DS:FLAG, DL
			JMP non_zero_part
			
	 zero_part:
			MOV DL, 1
			MOV DS:FLAG, DL
			JMP NEXT
	non_zero_part:		
	
			MOV BX, DS:KEYPAD_INDEX
			MOV DS:KEYPAD_INPUT[BX], CL
			
			INC BX
			CMP BX, 9
			JNE skip_past
			MOV BX, 8
			
		skip_past:
			MOV DS:KEYPAD_INDEX, BX
		
		MOV BX, DS:KEYPAD_INDEX
		MOV DX, BX
		CMP DX, 6
		JLE update_display
		MOV DX, 6
		
		update_display:
			MOV CX, 5
			DEC BX
			MOV AL, DS:KEYPAD_INPUT[BX]
			INC BX
			
			PUSH DX
			MOV DX, DS:KEYPAD_INDEX
			SUB DX, BX
			
			PUSH BX
			
			SUB CX, DX
			MOV BX, CX
			MOV DS:BCD_MESSAGE[BX], AL
			
			POP BX
			POP DX
		DEC BX
		DEC DX
		JNZ update_display
			
			JMP RETURN
	KEYPAD_2: 
			  ADD DS:REG_AL,0FH
			  JMP NXTCOL
	ZERO_PRINT: MOV DS:REG_AL,00H
				JMP NXTCOL
	SUBTRACT: SUB DS:REG_AL,06H
			  MOV BL,CH
			  DEC BH
			  JMP NXTROW
	RETURN:
			POP DX
			POP CX
			POP BX
			POP AX
			RET

KEYPAD_LOOP ENDP
	  
DEBOUNCE PROC FAR
		  PUSH CX
		  
		  MOV CX, 8FFFH
BACK: 	  NOP
		  LOOP BACK
		  POP CX
		  RET
DEBOUNCE  ENDP


; ^^^^^^^^^^^^^^^ End of User main routine ^^^^^^^^^^^^^^^^^^^^^^^^^
SERIAL_REC_ACTION	PROC	FAR
		PUSH	CX
		PUSH 	BX
		PUSH	DS
		
		MOV	BX,DATA_SEG		;initialize data segment register
		MOV	DS,BX
		
		; CMP AL, '~'
		; JNE resume
		
		; CALL FAR PTR CLEAR_LCD
		; JMP S_RET
		
		; resume:
		; CALL FAR PTR UPDATE_LCD_INPUT
		
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
		PUSH 	DX
		
		
		MOV	AX,DATA_SEG
		MOV	DS,AX
	
		DEC	DS:T_COUNT
		JNZ	T_NEXT1
		MOV	AL,DS:T_COUNT_SET
		MOV	DS:T_COUNT,AL

T_NEXT0:
		MOV AL, DS:ENABLE_BYTE
		MOV DX, 180H
		OUT DX, AL
		
		XOR BX, BX
		MOV BL, DS:BCD_INDEX
		MOV AL, DS:BCD_MESSAGE[BX]
	
		CALL FAR PTR BCD_TO_7SEG

		MOV DX, 200H
		OUT DX, AL

		INC BL
		MOV AL, DS:ENABLE_BYTE
		ROL AL, 1
		CMP AL, 10111111b
		JNE loopend
		MOV AL, 11111110b 
		MOV BL, 0

		loopend:
		MOV DS:ENABLE_BYTE, AL
		MOV DS:BCD_INDEX, BL
T_NEXT1:
		
		POP DX
		POP	CX
		POP	BX
		POP	DS
		POP AX
		
		
		RET
TIMER2_ACTION	ENDP

BCD_TO_7SEG PROC FAR

	PUSH BX
	PUSH CX
	PUSH DX

	CMP AL, 11
	JNE zero
	MOV AL, 00111111b;
	JMP endfunc
	
	zero:
	CMP AL, 0
	JNE one
	MOV AL, 00111111b;
	JMP endfunc
	
	one:
	CMP AL, 1
	JNE two
	MOV AL, 00000110b;
	JMP endfunc
	
	two:
	CMP AL,2
	JNE three
	MOV AL, 01011011b;
	JMP endfunc
	
	three:
	CMP AL,3
	JNE four
	MOV AL, 01001111b;
	JMP endfunc
	
	four:
	CMP AL,4
	JNE five
	MOV AL, 01100110b;
	JMP endfunc
	
	five:
	CMP AL,5
	JNE six
	MOV AL, 01101101b;
	JMP endfunc
	
	six:
	CMP AL,6
	JNE seven
	MOV AL, 01111101b;
	JMP endfunc
	
	seven:
	CMP AL,7
	JNE eight
	MOV AL, 00000111b;
	JMP endfunc
	
	eight:
	CMP AL,8
	JNE nine
	MOV AL, 01111111b;
	JMP endfunc
	
	nine:
	CMP AL,9
	JNE endfunc
	MOV AL, 01101111b;
	JMP endfunc
	
	endfunc:
	POP DX
	POP CX
	POP BX

RET
BCD_TO_7SEG ENDP

CODE_SEG	ENDS
END
