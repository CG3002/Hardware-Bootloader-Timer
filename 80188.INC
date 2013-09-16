;IO Setup for 80C188XL 

         UMCR    EQU    0FFA0H ; Upper Memory Control Register
         LMCR    EQU    0FFA2H ; Lower Memory control Register         
         PCSBA   EQU    0FFA4H ; Peripheral Chip Select Base Address
         MPCS    EQU    0FFA8H ; MMCS and PCS Alter Control Register

; Initial 80C188XL UCS Pin
; |start address|block size| value for No waits, No Ready   
;   FE000H            8K                 3E04H
;   FC000H           16K                 3C04H
;   F8000H           32K                 3804H
      
; Initialize Upper Chip Select pin with 8K ROM 
;         MOV DX, UMCR
;         MOV AX, 03E04H
;         OUT DX, AX

; Initialize Lower Chip Select pin with 8k RAM
;         MOV DX, LMCR
;         MOV AX, 01C4H  ; Start address 1FFFH, 8K, No waits
;         OUT DX, AL

; Initialize MPCS to MAP peripheral to IO address
         MOV DX, MPCS
         MOV AX, 0083H
         OUT DX, AL

; PCSBA initial, set the serial port start from 00H
         MOV DX, PCSBA
         MOV AX, 0003H ; Peripheral starting address 00H no READY, No Waits
         OUT DX, AL

; Serial port definition and initialize 
         SRB     EQU       00H ; Serial Receiver Buffer Register (R)
         STB     EQU       00H ; Serial Transmitter Holding Register(W)  
         SIER    EQU       01H ; Serial Interrupt Enable Register (W)
         SMD     EQU       03H ; Serial Line Control Register
         SST     EQU       05H ; Serial Line Status Register
         DLL     EQU       00H ; Divisor Latch Least Significant BYTE
         DLM     EQU       01H ; Divisor Latch most  Significant BYTE

;Definition of content of SST register
;|Not Use|TE|THRE|BI|FE|PE|OE|DR|
;TE Transmitter empty	;THRE Transmittor Holding Register Empty
;BI Breakr Interrupt 	;FE Framing Error
;PE Parity Error		;OE Overrun Error 	;DR Data Ready
         REC_RDY    EQU   00000001B
         TRAN_RDY   EQU   00100000B
         ERR_DET    EQU   00001110B
         BREAK_DET  EQU   00010000B

; Serial Line Control Data
        SMD_DATA     EQU    00000111B
;1st bit set 1 to access the Divisor latch 
;2 stop bits, 8 data bits, no parity check
        SMD_DATA_DIV EQU    10000111B
; Set divisor value        
        MOV DX, SMD
        MOV AL, SMD_DATA_DIV
        OUT DX, AL
        MOV DX, DLL
        MOV AL, 52
        OUT DX, AL
        MOV DX, DLM
        MOV AL, 0
        OUT DX, AL

;SET SERIAL PORT WORKING MODE
         MOV DX, SMD
         MOV AL, SMD_DATA
         OUT DX, AL

;DISABLE SERIAL PORT INT
         MOV DX, SIER
         MOV AL, 0
         OUT DX, AL

; Timer control Unit
         T2_CON    EQU      0FF66H ; Timer 2 Control Register
         T2_CA     EQU      0FF62H ; Timer 2 compare register
         T2_CNT    EQU      0FF60H ;

         T1_CON    EQU      0FF5EH ;
         T1_CB     EQU      0FF5CH ;
         T1_CA     EQU      0FF5AH ;
         T1_CNT    EQU      0FF58H
         
         T0_CON    EQU      0FF56H ;
         T0_CB     EQU      0FF54H ;
         T0_CA     EQU      0FF52H ;
         TO_CNT    EQU      0FF50H   

; Timer1 control Data
; Use Timer1 to generate the clock for serial port  
         MOV AX, 1
         MOV DX, T1_CB
         OUT DX, AL
         MOV DX, T1_CA
         OUT DX, AL

         MOV AX, 0
         MOV DX, T1_CNT
         OUT DX, AL

         MOV DX, T1_CON
         MOV AX, 0C003H
         OUT DX, AL
