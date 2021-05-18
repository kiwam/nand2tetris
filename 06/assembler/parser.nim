import strutils, sequtils, sugar, re

type
  Command* = enum
    A_COMMAND
    C_COMMAND
    L_COMMAND
    NOP

  Parser* = ref object of RootObj
    lines: seq[string]
    # data for current command(ex. line)
    cmd*: string
    cmdIndex*: int
    cmdType: Command
    symbol: string
    dest: string
    comp: string
    jump: string

proc hasMoreCommands*(p: Parser): bool =
  return p.cmdIndex < len(p.lines)

proc initCurrentCmdInfo(p: Parser) =
  p.cmd = ""
  p.cmdType = NOP
  p.symbol = ""
  p.dest = ""
  p.comp = ""
  p.jump = ""

proc parseAcmd(p: Parser) =
  # @value: value is non-minus decimal or symbol
  # TODO: handling symbol
  p.cmdType = A_COMMAND
  p.symbol = replace(p.cmd, "@", "")

proc parseCcmd(p: Parser) =
  p.cmdType = C_COMMAND
  # d=c;j, d or j may be empty/not
  # d=c    j is empty 
  # c;j    d is empty
  # c      d&j are empty
  var
    cmd = p.cmd
    tempSeq = cmd.split('=')
  if len(tempSeq) == 2: # '=' found!
    p.dest = tempSeq[0]
    cmd = tempSeq[1]
  else:
    p.dest = ""
  
  tempSeq = cmd.split(';')
  if len(tempSeq) == 2: # ';' found
    p.comp = tempSeq[0]
    p.jump = tempSeq[1]
  else:
    p.comp = cmd
    p.jump = ""

proc parseLcmd(p: Parser) =
  p.cmdType = L_COMMAND
  p.symbol = p.cmd.multiReplace(("(", ""), (")", ""))

proc advance*(p: Parser) =
  initCurrentCmdInfo(p)
  p.cmd = p.lines[p.cmdIndex]
  if p.cmd == "":
    p.cmdType = NOP
  else:
    case p.cmd[0]:
      of '@':
        parseAcmd(p)
      of '(':
        parseLcmd(p)
      else:
        parseCcmd(p)

  p.cmdIndex += 1

proc commandType*(p: Parser): Command =
  return p.cmdType

proc symbol*(p: Parser): string = 
  return p.symbol

proc dest*(p: Parser): string =
  return p.dest

proc comp*(p: Parser): string =
  return p.comp

proc jump*(p: Parser): string =
  return p.jump

proc rmCommentsSpaces(str: seq[string]): seq[string] =
  return str.map(s => replace(s, re"//.*", "")).map(s => s.strip())

proc newParser*(filepath: string): Parser =
  var p = new Parser
  p.lines = splitLines(readFile(filepath).string)
  p.lines = rmCommentsSpaces(p.lines)
  p.cmdIndex = 0
  return p

