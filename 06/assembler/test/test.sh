#!/usr/bin/env zsh

nim c -r ../assembler.nim ../../max/Max.asm
diff Max.hack ../../max/Max.hack
if [ $? = 0 ]; then
  echo "[OK] Max.asm"
else
  echo "[NG] Max.asm"
fi

nim c -r ../assembler.nim ../../add/Add.asm
diff Add.hack ../../add/Add.hack
if [ $? = 0 ]; then
  echo "[OK] Add.asm"
else
  echo "[NG] Add.asm"
fi

nim c -r ../assembler.nim ../../rect/Rect.asm
diff Rect.hack ../../rect/Rect.hack
if [ $? = 0 ]; then
  echo "[OK] Rect.asm"
else
  echo "[NG] Rect.asm"
fi

nim c -r ../assembler.nim ../../pong/Pong.asm
diff Pong.hack ../../pong/Pong.hack
if [ $? = 0 ]; then
  echo "[OK] Pong.asm"
else
  echo "[NG] Pong.asm"
fi