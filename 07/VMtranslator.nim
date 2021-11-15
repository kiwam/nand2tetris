import strutils, os, sugar, strformat
import CodeWriter, Parser, constVMtranslator

# number of outfile must be 1
proc genInOutFiles(input: string): (seq[string], string) =
  if input.endsWith(".vm"):
    return (@[input], input.replace(".vm", ".asm"))
  let infiles = collect(newSeq):
    for file in walkFiles(input & "/*.vm"):
      file
      # file.replace(input&"/", "")
  var outfile = input 
  if outfile.endsWith('/'):
    outfile = outfile[0..^2]
  outfile = outfile & '/' & lastPathPart(outfile)  & ".asm"
  return (infiles, outfile)

proc writeAsm(parser: Parser, writer: Writer) =
  let cmdType = parser.cmdType
  case cmdType:
  of C_ARITHMETIC:
    writeArithmetic(writer, parser.cmd)
  of C_PUSH, C_POP:
    writePushOrPop(writer, parser.cmdType, parser.arg1, parser.arg2)
  of C_NOP:
    # echo "C_NOP"
    discard

proc translateFiles(infiles: seq[string], outfile: string) =
  if infiles == @[""]:
    return
  var writer: Writer = newCodeWriter(outfile)
  writer.initStackPointer()
  for f in infiles:
    var parser: Parser = newParser(f)
    while parser.hasMoreCommands():
      parser.advance()
      writeAsm(parser, writer)

when isMainModule:
  if paramCount() != 1:
    echo fmt"{paramCount()} param(s) counted."
    echo "usage : ./VMtranslator [file.vm|dirName]"
    quit 1
  
  let (infiles, outfile)= genInOutFiles(commandLineParams()[0])
  echo outfile
  translateFiles(infiles, outfile)