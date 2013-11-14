$MOD186
$EP
NAME TIMER

; =========================================================================
; Main Timer Driver Program
; Author: Vaghul Aditya Balaji

; This file contains proprietary information and cannot be copied 
; or distributed without prior permission from the author.
; =========================================================================

public	serial_rec_action, timer2_action
extrn	print_char:far, print_2hex:far, iodefine:far
extrn   set_timer2:far

;IO Setup for 80C188 
	UMCR    EQU    0FFA0H ; Upper Memory Control Register
	LMCR    EQU    0FFA2H ; Lower Memory control Register         
	PCSBA   EQU    0FFA4H ; Peripheral Chip Select Base Address
	MMCS    EQU    0FFA6H ; Used for controlling the MCS pins on the 8088
	MPCS    EQU    0FFA8H ; MMCS and PCS Alter Control Register
	
	PORTA  EQU    0080H
	PORTB  EQU    0081H
	PORTC  EQU    0082H
	CWR    EQU    0083H
	
	INT0CON  EQU   0FF38H
	EOI      EQU   0FF22H
	IMASK    EQU   0FF28H
	
	PCS2_ADDR EQU 100H ; Used for controlling which BCD displays the digit
	PCS3_ADDR EQU 180H ; Used for controlling the pattern that is displayed on the BCDs
	PCS4_ADDR EQU 200H ; Used for controlling the DAC chip of the speaker system

	
STACK_SEG	SEGMENT
	DB	256 DUP(?)
	TOS	LABEL	WORD
STACK_SEG	ENDS


DATA_SEG	SEGMENT
	TIMER2_MESS	DB	10,13,'TIMER2 INTERRUPT    '
	T_COUNT		DB	2FH
	T_COUNT_SET	DB	2FH
	REC_MESS	DB	10,13,'Period of timer =     '
	
	;Keypad Variables	
	KEYS_PART1  db '|','0','_','L','K','J','9','8','7','I','H','G' 
	KEYS_PART2  db '6','5','4','F','E','D','3','2','1','C','B','A'
	KEY_FLAG    db 00H ;This variable is used for controlling multiple detections of the same key-press inside the keypad loop
	
	;Sound Variables
	SOUND_OFFSET   DW   0000H, 1269H, 2121H, 2EA9H, 3BD3H, 478DH, 546EH
	SOUND_SIZE	   DW   1268H, 0EB7H, 0D87H, 0D29H, 0BB9H, 0CE0H, 1199H
	EEPROM_START   DW   4000H, 4000H, 4000H, 4000H, 4000H, 4000H, 4000H
	SOUND_ADDRESS  DW   0000H
	SOUND_COUNT    DW   0000H
	SOUND_QUEUE    DB   32 DUP(?)
	SOUND_HEAD     DB   00H
	SOUND_TAIL     DB   00H
	
	;7-Segment Variables
	; BCD Digit Mapping:    0	 1 	  2	   3    4    5    6    7    8    9	
    BCD_NUMBERS	       DB  5FH, 50H, 6DH, 79H, 72H, 3BH, 3EH, 51H, 7FH, 73H						
	BCD_DISPLAY	       DB  5FH, 50H, 6DH, 79H, 72H, 3BH
	CURRENT_BCD        DB  00H
DATA_SEG	ENDS

	
CODE_SEG	SEGMENT

	PUBLIC		START

ASSUME	CS:CODE_SEG, SS:STACK_SEG, DS:DATA_SEG

START:
;initialize stack area
	MOV	AX,STACK_SEG		
	MOV	SS,AX
	MOV	SP,TOS
		
	MOV AX, DATA_SEG
	MOV DS, AX

; Initialize the on-chip peripherals
	CALL FAR PTR IODEFINE
	
; Initialize MPCS to MAP peripheral to IO address
	
	MOV  DX, MPCS  
	MOV  AX, 2083H 
	OUT  DX, AX
	
	MOV  DX, MMCS ; send MCS start address to 40000
	MOV  AX, 4003H 
	OUT  DX, AX

; PCSBA initial, set the parallel port start from 00H
	MOV DX, PCSBA
	MOV AX, 0003H ; Peripheral starting address 00H no READY, No Waits
	OUT DX, AX

; Initialize LMCS 
    MOV DX, LMCR
    MOV AX, 01C4H  ; Starting address 1FFFH, 8K, No waits, last should be 5H for 1 waits      
    OUT DX, AX
	
	MOV AL, 89H ;mode 0, [A-out(for led)] [B - out, C-in (for reading keypad))]
	MOV DX, CWR ; load CWR to DX
	OUT DX, AL	;load CWR value from AL
	
; ######################### Start of User Main Routine ###########################
  
    CALL FAR PTR set_timer2
    STI
		
	XOR AX, AX
	XOR BX, BX
	XOR CX, CX
	XOR DX, DX
	
	NEXT:
		CALL FAR PTR KEYPAD_READ
		JMP NEXT
	
; ######################### End of User Main Routine #############################	

KEYPAD_READ PROC FAR
	PUSH DX
	PUSH CX
	PUSH BX
	PUSH AX
	PUSH SI
	                                
	MOV BL, 00H        ;initialize BL for key code
	XOR AL, AL        ;clear all flags
	MOV DX, PORTB  ;port B address to DX
	OUT DX, AL        ;ground all rows
	MOV DX, PORTC        ;Port C address to DX
             
	IN AL, DX        ;read all columns
	AND AL,77H  ;D0-D2 and D4-D6 are the 6 input pins for two keypads 0111 0111(77H)                          
	CMP AL,77H
	JZ RESET_FLAG        

	CALL DEBOUNCE ;wait for 10ms if key press
	MOV AL, 07FH        ;load data byte to ground a row
	MOV BH, 04H        ;set row counter

NXTROW:                
	ROL AL, 01H       ;rotate AL to ground next row
	MOV CH, AL        ;save data byte to ground next row
	MOV DX, PORTB        ;port B address to DX
	OUT DX, AL        ;ground one of the rows
	MOV DX, PORTC        ;port C address to DX
	IN AL, DX        ;read input port for key closure
	
	MOV AH,AL
	ROR AH,01H
	
	AND AH,38H
	AND AL,07H
	OR AL,AH

	AND AL,3FH ;D0-D2 and D4-D6 are the 6 input pins for two keypads 0111 0111(77H)
	MOV CL, 06H        ;set column counter

POLL_COLUMNS:        
	RCR AL, 01H       ;move D0 to CF        
	JNC FOUND_KEY        ;key closure is found, if CF=0
	INC BL                ;inc BL for next binary key code                         

	DEC CL                ;dec column counter if no key closure
	JNZ POLL_COLUMNS        ;check for key closure in next column
	MOV AL, CH        ;Load data byte to ground next row
	DEC BH                ;if no key closure found in all columns in this row, go to ground next row
	JNZ NXTROW        ;go back to ground next row	
	JMP SKIP_SEND       

RESET_FLAG:
	MOV DS:KEY_FLAG, 00H  ;if no keypad input is found, reset flag so that next keypad input is printed
	JMP SKIP_SEND        ;if flag is set don't send keypad input to hyperterminal
	
FOUND_KEY:        
	CMP DS:KEY_FLAG, 01H
	JZ SKIP_SEND        ;if flag is set don't send keypad input to hyperterminal

SEND_KEY:
	CMP BL,0BH
	JG LOAD_KEYS_PART2
        
LOAD_KEYS_PART1:        
    LEA SI,KEYS_PART1 
    JMP SEND_CHAR
        
LOAD_KEYS_PART2:
    SUB BL,0CH
    LEA SI,KEYS_PART2
        
SEND_CHAR:
    XOR AX, AX
    MOV AL,BL
    ADD SI,AX
    MOV AL,[SI]
	;call FAR ptr print_char
	
    SUB AL, 48 ;Converting to number
	CMP AL, 09H ;If number is > 9 then it is some other character and not a numeric digit
	JLE SEND_NUMBER
	JMP KEYPAD_END

SEND_NUMBER:
	;manipulated the number
	MOV SI,AX
	MOV AH, DS:BCD_NUMBERS[SI]
	MOV DS:BCD_DISPLAY[0], AH
	
KEYPAD_END:
    MOV DS:KEY_FLAG, 01H ;set flag to one so that next time same key input is not printed
        
SKIP_SEND:
	POP SI
	POP AX
	POP BX
	POP CX
	POP DX
	RET	
KEYPAD_READ ENDP
		
	
;This procedure generates a delay at 8MHz operating frequency for debouncing the keypad buttons
DEBOUNCE PROC NEAR
	PUSH CX
	
    MOV CX, 094Ch ; 2380 decimal
BACK:
    NOP ; 3 clocks
	LOOP BACK; 18 clocks

	POP CX
	RET
DEBOUNCE ENDP


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

		MOV	AL,DS:T_COUNT_SET	;print current period of timer
		CALL	FAR PTR PRINT_2HEX
S_RET:
		POP	DS
		POP	BX
		POP	CX
		RET
SERIAL_REC_ACTION	ENDP


TIMER2_ACTION	PROC	FAR
	PUSH AX
	PUSH DS
	PUSH BX
	PUSH CX
	PUSH DX

	MOV	AX,DATA_SEG
	MOV	DS,AX
	
	XOR AX, AX
	XOR BX, BX
	XOR CX, CX
	XOR DX, DX
	
	CALL FAR PTR DISPLAY_7SEGMENT
	
T2_END:	
	POP DX
	POP	CX
	POP	BX
	POP	DS
	POP AX
	RET
TIMER2_ACTION	ENDP


DISPLAY_7SEGMENT PROC FAR	
	PUSH AX
	PUSH DS
	PUSH BX
	PUSH CX
	PUSH DX

	MOV	AX,DATA_SEG
	MOV	DS,AX
	
	XOR AX, AX
	XOR BX, BX
	
	; BCD Select: [-] [-] [6] [5] [4] [3] [2] [1]
	MOV DX, PCS2_ADDR
	MOV AL, 0FEH
	MOV CL, DS:CURRENT_BCD
	ROL AL, CL
	OUT DX, AL
	
	MOV DX, PCS3_ADDR
	MOV BL, CURRENT_BCD
	MOV AL, BCD_DISPLAY[BX]
	OUT DX, AL
	
	INC CURRENT_BCD
	CMP CURRENT_BCD, 06H
	JE RESET_CURRENT_BCD
	JMP DISP_END
	
RESET_CURRENT_BCD:
	MOV CURRENT_BCD, 00H

DISP_END:	
	POP DX
	POP	CX
	POP	BX
	POP	DS
	POP AX
	RET
DISPLAY_7SEGMENT ENDP




CODE_SEG	ENDS
END