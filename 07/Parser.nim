import tables, strutils, sequtils, sugar, re
import constVMtranslator

type
  Parser* = ref object of RootObj
    lines: seq[string]
    cmd*: string
    cmdType*: CommandType
    arg1*: string
    arg2*: int

# new commands will be added...
let CommandTypeTable = {
   "add": C_ARITHMETIC, "sub": C_ARITHMETIC, "neg": C_ARITHMETIC,
   "eq": C_ARITHMETIC, "gt": C_ARITHMETIC, "lt": C_ARITHMETIC,
   "and": C_ARITHMETIC, "or": C_ARITHMETIC, "not": C_ARITHMETIC,
   "push": C_PUSH, "pop": C_POP
  }.toTable

let CommandsNoArg = [
  "add", "sub", "neg", "eq", "gt", "lt", "and", "or", "not",
]
# let Commands1Arg = [
#
# ]
let Commands2Arg = ["push", "pop"]

proc initParser(p: Parser) =
  p.cmd = ""
  p.cmdType = C_NOP
  p.arg1 = ""
  p.arg2 = 0

proc hasMoreCommands*(p: Parser): bool =
  return p.lines.len() != 0 

proc advance*(p: Parser) =
  initParser(p)
  # pop from lines
  var line = p.lines[0].split(" ").toSeq
  p.lines.delete(0)
  
  # parse
  if line != @[""]:
    p.cmd = line[0]
    if p.cmd in CommandsNoArg:
      p.cmdType = CommandTypeTable[p.cmd]
      if p.cmdType == C_ARITHMETIC:
        p.arg1 = p.cmd
      echo p.cmdType, " ", p.arg1
    # if p.cmd in Commands1Arg:
    #   p.cmdType = CommandTypeTable[p.cmd]
    #   p.arg1 = line[1] 
    if p.cmd in Commands2Arg:
      p.cmdType = CommandTypeTable[p.cmd]
      p.arg1 = line[1]
      p.arg2 = parseInt(line[2])
      echo p.cmdType, " ", p.arg1, " ", p.arg2

proc commandType*(p: Parser): CommandType =
  return p.cmdType

proc arg1*(p: Parser): string =
  return p.arg1 

proc arg2*(p: Parser): int =
  return p.arg2 

# proc setCommandType(p: Parser, cmd: string) =
#   p.cmdType = CommandTypeTable[cmd]

# proc parseCmd(p: Parser, cmd: string) =
#   setCommandType(p, cmd)
#   if CommandTypeTable[cmd] == C_ARITHMETIC:
#     p.arg1 = cmd

proc removeComments(str: seq[string]): seq[string] =
  return str.map(s => replace(s, re"//.*", ""))

proc newParser*(file: string): Parser =
  var p = new Parser
  initParser(p)
  p.lines = splitLines(readFile(file).string)
  p.lines = removeComments(p.lines)
  return p
