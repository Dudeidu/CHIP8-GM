

// Game maker related   //////////////////////////////
#macro WINDOW_WIDTH 640
#macro WINDOW_HEIGHT 320

// Emulator related     //////////////////////////////

#macro CH8_MEMORY_MAX 4096

// Memory locations:
// Some of these are unused since game maker has its own variables that are faster to use
// Instead they serve as theoretical addresses.

// (1*5*16) font sprites (0~F)
#macro CH8_ADDR_SPR 0x0
// (10*10)  high resolution font sprites (0~9)
#macro CH8_ADDR_SPR_HIGHRES 0x6E
// (1*16)   V0 (general purpose variables 0~F) 
#macro CH8_ADDR_V 0xD2
// (2)      I (index)
#macro CH8_ADDR_I 0xE2
// (2)      program counter
#macro CH8_ADDR_PC 0xE4
// (1)      delay timer
#macro CH8_ADDR_DT 0xE6
// (1)      Sound timer
#macro CH8_ADDR_ST 0xE7
// (1)      Stack pointer
#macro CH8_ADDR_SP 0xE8
// (2*16)   Stack

#macro CH8_ADDR_STACK 0xE9

#macro CH8_ADDR_PROG 0x200

#macro CH8_DISPLAY_WIDTH 128
#macro CH8_DISPLAY_HEIGHT 64
