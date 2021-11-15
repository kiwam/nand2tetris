

type
  CommandType* = enum
    C_ARITHMETIC
    C_PUSH
    C_POP
    # C_LABEL
    # C_GOTO
    # C_IF
    # C_FUNCTION
    # C_RETURN
    # C_CALL
    C_NOP

type
  Registers* = enum
    R_0 = 0,
    R_1 = 1,
    R_2 = 2,
    R_3 = 3,
    R_4 = 4,
    R_5 = 5,
    R_6 = 6,
    R_7 = 7,
    R_8 = 8,
    R_9 = 9,
    R_10 = 10,
    R_11 = 11,
    R_12 = 12,
    R_13 = 13,
    R_14 = 14,
    R_15 = 15,
    R_16 = 16

type
  Regs* = enum
    R_SP = 0,
    R_LCL = 1,
    R_ARG = 2,
    R_THIS = 3,
    R_THAT = 4

type
  Segment* = enum
    S_ARG = "argument",
    S_LCL = "local",
    S_STATIC = "static",
    S_CONST = "constant",
    S_THIS = "this",
    S_THAT = "that",
    S_POINTER = "pointer",
    S_TEMP = "temp"
