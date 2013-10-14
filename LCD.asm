$mod186
$EP
NAME LCD


public	LCD_INIT, MESSAGE_LCD, CLEAR_LCD, UPDATE_LCD_INPUT

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

STACK_SEG_LCD	SEGMENT
		DB	256 DUP(?)
	TOS	LABEL	WORD
STACK_SEG_LCD	ENDS


DATA_SEG_LCD	SEGMENT
	INPUT       DB  32 dup('q')
	INPUT_SIZE  DB  0
	
DATA_SEG_LCD	ENDS


CODE_SEG_LCD	SEGMENT

ASSUME	CS:CODE_SEG_LCD, SS:STACK_SEG_LCD

START:

MOV	AX,STACK_SEG_LCD
MOV	SS,AX
MOV	SP,TOS

MOV AX, DATA_SEG_LCD
MOV DS, AX

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

UPDATE_LCD_INPUT PROC FAR

	XOR BX, BX
	MOV BL, DS:INPUT_SIZE
	MOV DS:INPUT[BX], AL
	INC BL
	MOV DS:INPUT_SIZE, BL
	
RET
UPDATE_LCD_INPUT ENDP

CODE_SEG_LCD	ENDS
END
