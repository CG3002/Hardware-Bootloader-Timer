; file:		BOOT86MC.INC
;
; author:	Dr Tay Teng Tiow
;		Dept of Electrical Engineering
;		National University of Singapore
;
; date:		20 April 1992
;
; This file contains proprietory information and should not be copied or
; distributed without permission from the author.
;------------------------------------------------------------------------
;
; This file contains the Macro definition for the bootstrap loader.
; This file is to be included in BOOTLOAD.ASM.
; Contains the following macros
;	GET_CHAR	: Get an ASCII byte from the serial port.
;	PUT_CHAR	: Put an ASCII byte to the serial port.
;	GET_2HEX	: Get 2 Hex byte in ASCII and convert to 8 bit integer.
;	ECHO		: Echo back what is received.
;	PUT_MESSAGE	: Put a string to the serial port.
;-------------------------------------------------------------------------

; Macro to get char from the serial port
%*DEFINE(GET_CHAR) LOCAL N_RDY0 NO_ERR0 ( 
              ;  MOV     AL,S_SCM_DATA
              ;  OUT     SCM,AL
%N_RDY0:	IN	AL,SST
		TEST	AL,ERR_DET
		JZ	%NO_ERR0
		JMP 	ERROR_ROUTINE
%NO_ERR0:	TEST	AL,REC_RDY		;test for byte received
		JZ	%N_RDY0
		IN	AL,SRB
		%echo
)


; Macro to put a character to screen
%*DEFINE(PUT_CHAR) LOCAL N_RDY_P0 ( 
		mov	ah,al
%N_RDY_P0:	in	al,sst
		test	al,tran_rdy
		jz	%N_RDY_P0
		mov	al,ah
		out	STB,al
)


; Macro to get 2 hex digits from the serial port and convert to single byte
%*DEFINE(GET_2HEX) LOCAL N_RDY1 N_RDY2 NO_ERR1 NO_ERR2 NUMER0 NUMER1( 
             ;   MOV     AL,S_SCM_DATA
             ;   OUT     SCM,AL
%N_RDY1:	IN	AL,SST			;get status for 1st HEX char
		TEST	AL,ERR_DET
		JZ	%NO_ERR1
		JMP 	ERROR_ROUTINE
%NO_ERR1:	TEST	AL,REC_RDY		;test for 1st HEX char received
		JZ	%N_RDY1
		IN	AL,SRB
		%echo		
		CMP	AL,3AH			;numerial:30h-39h;alpha:41h-46h
		JS	%NUMER0
		ADD	AL,9
%NUMER0:	SHL	AL,4			;shift left 4 bits
		MOV	AH,AL			;store temporary in AH
%N_RDY2:	IN	AL,SST			;get status for 2nd HEX char
		TEST	AL,ERR_DET
		JZ	%NO_ERR2
		JMP 	ERROR_ROUTINE
%NO_ERR2:	TEST	AL,REC_RDY		;test for 2nd HEX char received
		JZ	%N_RDY2
		IN	AL,SRB
		%echo
		CMP	AL,3AH			;numerial:30h-39h;alpha:41h-46h
		JS	%NUMER1
		ADD	AL,9
%NUMER1:	AND	AL,00001111B
		OR	AL,AH
		XOR	AH,AH
		ADD	BX,AX			;compute the checksum
)


; Macro to echo a hex character to screen
; In this macro, the transmit ready is not checked
%*DEFINE(echo) LOCAL no_echo ( 
		test	dh,0ffh
		jz	%no_echo
		out	stb,al
%no_echo:
)


; Macro to put message to the serial port
%*DEFINE(PUT_MESSAGE(var)) LOCAL N_RDY_PUT (
ASSUME	ES:MESSAGE_SEG
		MOV	AX, MESSAGE_SEG
		MOV	ES,AX
		MOV	DI,00H
		MOV	CX,42
%N_RDY_PUT:	IN	AL,SST
		TEST	AL,TRAN_RDY
		JZ	%N_RDY_PUT
		MOV	AL,ES:%var[DI]
		OUT 	STB,AL
		INC	DI
		LOOP	%N_RDY_PUT
)

