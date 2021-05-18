import tables

type
  Symbols* = Table[string, int]

proc newSymbols*: Symbols =
  var s: Symbols = {
    "SP":     0,
    "LCL":    1,
    "ARG":    2,
    "THIS":   3,
    "THAT":   4,
    "SCREEN": 16384,
    "KBD":    24576
  }.toTable

  for i in 0..15:
    s["R" & $i] = i
  
  return s

proc addEntry*(s: var Symbols, symbol: string, address: int) =
  s[symbol] = address

proc containsSymbol*(s: var Symbols, symbol: string): bool =
  return s.contains(symbol) 

proc getAddress*(s: Symbols, symbol: string): int =
  return s[symbol]
