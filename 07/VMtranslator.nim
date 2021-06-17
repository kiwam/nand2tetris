import strutils, os, sugar
import CodeWriter, Parser, constVMtranslator

# outfiles will be deleted
proc genInOutFiles(input: string): (seq[string], seq[string]) =
  if input.endsWith(".vm"):
    return (@[input], @[input.replace(".vm", ".asm")])
  let infiles = collect(newSeq):
    for file in walkFiles(input & "/*.vm"):
      file
      # file.replace(input&"/", "")
  let outfiles = collect(newSeq):
    for f in infiles:
      f.replace(".vm", ".asm")
  return (infiles, outfiles)


when isMainModule:
  if paramCount() != 1:
    echo "Need 1 arg.\nUsage example: ./VMtranslator [file.vm|dirname]"
    quit 1
  
  var infile: seq[string] = @[]
  var outfile: seq[string] = @[]
  let tpl = genInOutFiles(commandLineParams()[0])
  infile = tpl[0]
  outfile = tpl[1]

  for f in infile:
    var p: Parser = newParser(f)
    while hasMoreCommands(p):
      advance(p)