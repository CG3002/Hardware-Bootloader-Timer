ASM86 MISC.ASM
ASM86 LCD.ASM
ASM86 TIMER.ASM
LINK86 TIMER.OBJ, LCD.OBJ, MISC.OBJ TO TIMER.LNK
LOC86 TIMER.LNK TO TIMER.ABS ST(START) AD(SEGMENTS(CODE_SEG(100H)))
OH86 TIMER.ABS TO TIMER.HEX