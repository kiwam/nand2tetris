import tables, strutils, sequtils, sugar, re, strformat
import constVMtranslator

type
  Writer* = ref object of RootObj
    outfile*: File
    vmfile: string

proc initCodeWriter(w: Writer, outfile: string)
proc initStackPointer*(w: Writer)
proc cmdA(w: Writer, adr: string)
proc cmdC(w: Writer, dest: string, comp: string, jump: string = "")
proc setDataToReg(w: Writer, adr: int, data: string)
# stack
proc moveDataToStack(w: Writer, data: string)
proc moveStackDataTo(w: Writer, dest: string)
# SP related
proc increSP(w: Writer)
proc decreSP(w: Writer)
proc jumpToSP(w: Writer)

# arithmetic/logic command
proc execBinaryFuncCmd(w: Writer, compMnemonic: string)
proc execUnaryFuncCmd(w: Writer, compMnemonic: string)
proc execCompareJump(w: Writer, jumpMnemonic: string)

proc setFileName*(w: Writer, fileName: string)
proc writeArithmetic*(w: Writer, command: string)
proc writePushOrPop*(w: Writer, cmdType: CommandType, segment: string, index: int)
proc close*(w: Writer)
proc newCodeWriter*(outfile: string): Writer

##
# def
##
proc initCodeWriter(w: Writer, outfile: string) =
  writeFile(outfile, "")
  w.outfile = open(outfile, FileMode.fmAppend)

# proc overwriteFile(file: string, content: string) = 
#   let f = open(file, fmAppend)
#   defer: f.close()
#   f.writeLine(content)

proc cmdA(w: Writer, adr: string) =
  echo fmt"aCmd adr {adr}"
  writeLine(w.outfile, '@' & adr)

proc cmdC(w: Writer, dest: string, comp: string, jump: string = "") =
  # d=c;j  
  # d=c    j is empty 
  # c;j    d is empty
  # c      d&j are empty
  # echo fmt"cmdC dcj: {dest} {comp} {jump}"
  var wr: string = ""
  if dest != "":
    wr &= dest & '='
  wr &= comp
  if jump != "":
    wr &= ';' & jump
  echo fmt"wr: {wr}"
  writeLine(w.outfile, wr)

proc setDataToReg(w: Writer, adr: int, data: string) =
  cmdA(w, "R" & $adr) # @R#
  cmdC(w, "M", data)      # *R#=data

proc moveDataToStack(w: Writer, data: string) =
  cmdA(w, data)      # @[data]
  cmdC(w, "D", "A")  # D=A
  jumpToSP(w)
  cmdC(w, "M", "D")  # *SP=D

proc moveStackDataTo(w: Writer, dest: string) =
  jumpToSP(w)
  cmdC(w, dest, "M") # dest=*SP

proc increSP(w: Writer) =
  cmdA(w, "SP")
  cmdC(w, "M", "M+1")

proc decreSP(w: Writer) =
  cmdA(w, "SP")
  cmdC(w, "M", "M-1")

proc jumpToSP(w: Writer) =
  cmdA(w, "SP")
  cmdC(w, "A", "M")

proc execBinaryFuncCmd(w: Writer, compMnemonic: string) =
  decreSP(w)                 # SP--
  moveStackDataTo(w, "D")    # D=*SP (get 2nd data from stack)
  decreSP(w)                 # SP--
  moveStackDataTo(w, "A")    # A=*SP (get 1st data from stack)
  cmdC(w, "D", compMnemonic) # D=[compMnemonic] (save result to D reg)
  jumpToSP(w)
  cmdC(w, "M", "D")          # *SP=D
  increSP(w)                 # SP++

proc execUnaryFuncCmd(w: Writer, compMnemonic: string) =
  decreSP(w)                 # SP--
  moveStackDataTo(w, "D")    # D=*SP
  cmdC(w, "D", compMnemonic) # D=[compMnemonic]
  jumpToSP(w)
  cmdC(w, "M", "D")          # *SP=D
  increSP(w)                 # SP++

## JEQ(=)/JGT(>)/JLT(<)
proc execCompareJump(w: Writer, jumpMnemonic: string) =
  decreSP(w)                       # SP--
  moveStackDataTo(w, "D")          # D=*SP (get 2nd from stack)
  decreSP(w)                       # SP--
  moveStackDataTo(w, "A")          # A=*SP (get 1st from stack)
  cmdC(w, "D", "A-D")              # D=A-D ('1st' - '2nd')
  jumpToSP(w)
  cmdc(w, "M", "0")               ## *SP=0(false)  set previously
  # IF D==/>/<0 *SP=true(0xFFFF) else *SP=false(0x0000)
  cmdA(w, "LABEL_EQ")              ## @LABEL_EQ
  cmdC(w, "", "D", jumpMnemonic)   ## c;d
  cmdA(w, "LABEL_NE")              ## @LABEL_NE
  cmdC(w, "", "0", "JMP")          ## force jump
  writeLine(w.outfile, "(LBL_EQ)") ## (LABEL_EQ)
  jumpToSP(w)
  cmdc(w, "M", "-1")                ## *SP=-1(true), if equal.
  writeLine(w.outfile, "(LBL_NE)") ## (LABEL_NE)
  ## do nothing cuz *SP=false previously and do not change if eq.
  increSP(w) # SP++

proc initStackPointer*(w: Writer) =
  cmdA(w, "256")    # @256
  cmdC(w, "D", "A") # D=A
  cmdA(w, "SP")     # @SP
  cmdC(w, "M", "D") # M=D

proc setFileName*(w: Writer, fileName: string) =
  w.vmfile = fileName

proc writeArithmetic*(w: Writer, command: string) =
  case command:
  of "add": execBinaryFuncCmd(w, "D+A")
  of "sub": execBinaryFuncCmd(w, "A-D")
  of "neg": execUnaryFuncCmd(w, "-D")
  of "eq": execCompareJump(w, "JEQ") 
  of "gt": execCompareJump(w, "JGT")
  of "lt": execCompareJump(w, "JLT")
  of "and": execBinaryFuncCmd(w, "D&A")
  of "or": execBinaryFuncCmd(w, "D|A")
  of "not": execUnaryFuncCmd(w, "!D")
  return

proc writePushOrPop*(w: Writer, cmdType: CommandType, segment: string, index: int) =
  if cmdType == C_PUSH:
    if segment == $S_CONST:
      moveDataToStack(w, $index)
    # more. case segment. static/memory/register
    increSP(w) # SP++
  if cmdType == C_POP:
    # TODO
    # set data to each segmentt static/memory/register
    decreSP(w) # SP--, first!

proc close*(w: Writer) =
  close(w.outfile)

proc newCodeWriter*(outfile: string): Writer =
  var w = new Writer
  initCodeWriter(w, outfile)
  return w 
