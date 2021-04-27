// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)
//
// This program only needs to handle arguments that satisfy
// R0 >= 0, R1 >= 0, and R0*R1 < 32768.

// compare R0, R1
    @R0
    D = M
    @R1
    D = D - M
    @BIGR0
    D;JGE
    @BIGR1
    0;JMP

(BIGR0)
    @MULTIPLY
    0;JMP

// swap
(BIGR1)
    @R0
    D = M
    @tmp
    M = D // tmp = M[R0]
    @R1
    D = M
    @R0
    M = D
    @tmp
    D = M
    @R1
    M = D
    @MULTIPLY
    0;JMP

(MULTIPLY)
    @R1
    D = M
    @i
    M = D // i = R1
    @R2
    M = 0

// R0+R0+... R1 times
(LOOP)
    @i
    D = M
    @END
    D;JLE
    @R0
    D = M
    @R2
    M = M + D
    @i
    M = M - 1
    @LOOP
    0;JMP 

(END)
    @END
    0;JMP
