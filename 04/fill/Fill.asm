// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed. 
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// clear screen
@0
D = A
@i
M = D
@SCREEN
D = A
@addr
M = D
(LOOP_CLEAR_DISP)
    @i
    D = M
    @8192
    D = D - A
    @LOOP_ALL
    D;JGE
    @addr
    A = M
    M = 0 
    @i
    M = M + 1
    @addr
    M = M + 1
    @LOOP_CLEAR_DISP
    0;JMP

// main loop
(LOOP_ALL)

    @KBD
    D = M
    @key
    M = D
    @SCREEN
    D = M
    @scrnow
    M = D

    @key
    D = M
    @BLACK
    D;JGT
    @WHITE
    D;JEQ
    (BLACK)
        @color
        M = -1
        @BACK
        0;JMP
    (WHITE)
        @color
        M = 0
        @BACK
        0;JMP
    (BACK)
    @color
    D = M
    @scrnow
    D = D - M
    @LOOP_ALL
    D;JEQ     // go top if there's no need to change color 

    @0
    D = A
    @i        // i = 0
    M = D
    @SCREEN
    D = A
    @addr
    M = D     // addr = 0x4000

    (LOOP_DRAW)
        // while(i < 8192) 8192 = 32 * 256rows. 32 = 512cols / 16
        @i
        D = M
        @8192
        D = D - A
        @DRAW_END
        D;JGE
        
        // write
        @color
        D = M
        @addr
        A = M
        M = D 
        @i
        M = M + 1
        @addr
        M = M + 1
        @LOOP_DRAW
        0;JMP
        
    (DRAW_END)
        @LOOP_ALL
        0;JMP

