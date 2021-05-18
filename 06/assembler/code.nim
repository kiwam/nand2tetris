import strutils, tables

proc dest*(dest: string): string =
  return case dest:
    of "M":   "001"
    of "D":   "010"
    of "MD":  "011"
    of "A":   "100"
    of "AM":  "101"
    of "AD":  "110"
    of "AMD": "111"
    else:     "000"

let aAndComp = {
  # a: "0"
  "0": "0101010", "1": "0111111", "-1": "0111010", "D": "0001100", 
  "A": "0110000", "!D": "0001101", "!A": "0110001", "-D": "0001111", 
  "-A": "0110011", "D+1": "0011111", "A+1": "0110111", "D-1": "0001110", 
  "A-1": "0110010", "D+A": "0000010", "D-A": "0010011", "A-D": "0000111", 
  "D&A": "0000000", "D|A": "0010101",
  # a: "1"
  "M": "1110000", "!M": "1110001", "-M": "1110011", "M+1": "1110111", 
  "M-1": "1110010", "D+M": "1000010", "D-M": "1010011", "M-D": "1000111", 
  "D&M": "1000000", "D|M": "1010101"
}.toTable

proc comp*(comp: string): string =
  return aAndComp[comp] 

proc jump*(jump: string): string =
  return case jump:
    of "JGT": "001"
    of "JEQ": "010"
    of "JGE": "011"
    of "JLT": "100"
    of "JNE": "101"
    of "JLE": "110"
    of "JMP": "111"
    else:     "000"

proc makeA*(address: int): string =
  let valueBits = 15
  return "0" & address.toBin(valueBits)

proc makeC*(comp: string, dest: string, jump: string): string =
  return "111" & comp(comp) & dest(dest) & jump(jump)
