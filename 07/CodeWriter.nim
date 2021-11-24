import tables, strutils, sequtils, sugar, re, strformat, os
import constVMtranslator

type
  Writer* = ref object of RootObj
    outfile*: File
    vmfile: string

# avoiding forward declaration of functions(proc)
{.experimental: "codeReordering".}

proc initCodeWriter(w: Writer, outfile: string) =
  writeFile(outfile, "")
  w.outfile = open(outfile, FileMode.fmAppend)
  w.vmfile = ""

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
  cmdC(w, "M", data)  # *R#=data

proc moveDataToStack(w: Writer, data: string) =
  cmdA(w, data)      # @[data]
  cmdC(w, "D", "A")  # D=A
  jumpToSP(w)
  cmdC(w, "M", "D")  # *SP=D

proc moveMemDataToStack(w: Writer, segment: string, idx: int) =
  cmdA(w, $idx)       # A=idx
  cmdC(w, "D", "A")   # D=A
  cmdA(w, segment)    # A=segment
  cmdC(w, "A", "D+A") # A=D+A
  cmdC(w, "D", "M")   # D=*(segment+idx)
  jumpToSP(w)         # *SP=D
  cmdC(w, "M", "D")

proc moveStackDataTo(w: Writer, dest: string) =
  jumpToSP(w)
  cmdC(w, dest, "M") # dest=*SP

proc moveStackDataToMem(w: Writer, segment: string, idx: int) =
  cmdA(w, $idx)       # A=idx
  cmdC(w, "D", "A")   # D=A
  cmdA(w, segment)    # A=segment
  cmdC(w, "A", "D+A") # A=D+A
  moveStackDataTo(w, "D") # D=*SP
  cmdC(w, "M", "D")   # *A=D

proc moveRegDataToStack(w: Writer, segment: string, idx: int) =
  let baseAddr = {"pointer": R_THIS, "temp": R_TEMP}.toTable
  let reg: int = int(baseAddr[segment]) + idx
  cmdA(w, "R" & $reg) # @R#
  cmdC(w, "D", "M")   # D=*R#
  jumpToSP(w)
  cmdC(w, "M", "D")   # *SP=D

proc moveStackDataToReg(w: Writer, segment: string, idx: int) =
  let baseAddr = {"pointer": R_THIS, "temp": R_TEMP}.toTable
  let reg: int = int(baseAddr[segment]) + idx
  moveStackDataTo(w, "D") # D=*SP
  cmdA(w, "R" & $reg)     # @R#
  cmdC(w, "M", "D")       # *R#=D

proc moveStaticDataToStack(w: Writer, segment: string, idx: int) =
  let file = lastPathPart(w.vmfile).split('.')[0] ## assume only one dot in file name
  cmdA(w, file & "." & $idx) # A=vmfile.#
  cmdC(w, "D", "M")          # D=M
  jumpToSP(w)
  cmdC(w, "M", "D")          # *SP=D

proc moveStackDataToStatic(w: Writer, segment: string, idx: int) =
  let file = lastPathPart(w.vmfile).split('.')[0] ## assume only one dot in file name
  moveStackDataTo(w, "D")    # D=*SP
  cmdA(w, file & "." & $idx) # A=vmfile.#
  cmdC(w, "M", "D")          # *(vmfile.#)=D

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
  cmdc(w, "M", "0")                ## *SP=0(false)
  # IF D==/>/<0 *SP=true(0xFFFF) else *SP=false(0x0000)
  cmdA(w, "LBL_EQ")                ## @LABEL_EQ
  cmdC(w, "", "D", jumpMnemonic)   ## c;d
  cmdA(w, "LBL_NE")                ## @LABEL_NE
  cmdC(w, "", "0", "JMP")          ## force jump
  writeLine(w.outfile, "(LBL_EQ)") ## (LABEL_EQ)
  jumpToSP(w)
  cmdc(w, "M", "-1")               ## *SP=-1(true), if equal.
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
  case cmdType:
  of C_PUSH:
    case segment:
    of $S_CONST:
      moveDataToStack(w, $index)
    of $S_LCL, $S_ARG, $S_THIS, $S_THAT:
      moveMemDataToStack(w, segment, index)
    of $S_POINTER, $S_TEMP:
      moveRegDataToStack(w, segment, index)
    of $S_STATIC:
      moveStaticDataToStack(w, segment, index)
    increSP(w) # SP++
  of C_POP:
    decreSP(w)
    case segment:
    of $S_LCL, $S_ARG, $S_THIS, $S_THAT:
      moveStackDataToMem(w, segment, index)
    of $S_POINTER, $S_TEMP:
      moveStackDataToReg(w, segment, index)
    of $S_STATIC:
      moveStackDataToStatic(w, segment, index)
  else:
    discard

proc close*(w: Writer) =
  close(w.outfile)

proc newCodeWriter*(outfile: string): Writer =
  var w = new Writer
  initCodeWriter(w, outfile)
  return w 
