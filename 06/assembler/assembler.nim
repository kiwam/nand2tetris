import strutils, os, system
import parser, code, symbolTable

type
  Assembler* = ref object of RootObj
    symbols: Symbols
    symbolAddr: int

proc newAssembler(): Assembler =
  return Assembler(symbols: newSymbols(), symbolAddr: 16)

proc getSymbolAddress(asmb: var Assembler, symbol: string): int =
  var address = -1
  try:
    address = parseInt(symbol)
  except ValueError:
    if not containsSymbol(asmb.symbols, symbol):
      addEntry(asmb.symbols, symbol, asmb.symbolAddr)
      asmb.symbolAddr += 1
    address = getAddress(asmb.symbols, symbol)
  finally:
    return address

proc pass1(filepath: string, symbols: var Symbols) =
  var p: Parser = newParser(filepath)
  var address = 0
  while p.hasMoreCommands():
    p.advance()
    var cmd = p.commandType
    if (cmd == A_COMMAND) or (cmd == C_COMMAND):
      address += 1
    elif cmd == L_COMMAND:
      addEntry(symbols, p.symbol, address)
    else:
      discard

proc pass2(inFile: string, asmb: var Assembler): int =
  var p: Parser = newParser(inFile)

  let (d, n, ext) = inFile.splitFile
  if ext != ".asm":
    return 1
  let ouF = d & "/" & n & ".hack"
  let outf = open(ouF, FileMode.fmWrite)
  defer:
    close(outf)

  while p.hasMoreCommands():
    p.advance()
    case p.commandType:
      of A_COMMAND:
        var addd = getSymbolAddress(asmb, p.symbol)
        outf.writeLine(makeA(addd))
      of C_COMMAND:
        outf.writeLine(makeC(p.comp, p.dest, p.jump))
      of L_COMMAND:
        discard
      else:
        discard
  
  return 0

when isMainModule:
  if paramCount() == 0:
    echo "need filepath of .asm, ex: `./assembler foo.asm`"
    programResult = 1
    quit programResult
  
  let filepath = commandLineParams()[0]

  var asmb = newAssembler()

  # generate symbole table
  pass1(filepath, asmb.symbols)

  var ret = pass2(filepath, asmb)
  if ret != 0:
    echo "something wrong occured: " & $ret
    programResult = 2
    quit programResult
