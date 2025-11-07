# .mk files
MK += Makefile $(wildcard mk/*.mk)
MK += $(wildcard   hw/*/*.mk)
MK += $(wildcard  cpu/*/*.mk)
MK += $(wildcard arch/*/*.mk)
MK += $(wildcard   os/*/*.mk)

# cmake files
CM += CMake* $(wildcard cmake/*.cmake)
CM += $(wildcard   hw/*/*.cmake)
CM += $(wildcard  cpu/*/*.cmake)
CM += $(wildcard arch/*/*.cmake)
CM += $(wildcard   os/*/*.cmake)

# C/C++
C  += $(wildcard src/*.c*)
H  += $(wildcard inc/*.h*)
LX += $(wildcard src/*.lex src/*.yacc src/*.ragel)
# libs
C  += $(wildcard lib/src/*.c*) $(wildcard lib/*/src/*.c*)
H  += $(wildcard lib/inc/*.h*) $(wildcard lib/*/inc/*.h*)
# cross
C  += $(wildcard   hw/src/*.c*) $(wildcard   hw/*/src/*.c*)
H  += $(wildcard   hw/inc/*.h*) $(wildcard   hw/*/inc/*.h*)
C  += $(wildcard  cpu/src/*.c*) $(wildcard  cpu/*/src/*.c*)
H  += $(wildcard  cpu/inc/*.h*) $(wildcard  cpu/*/inc/*.h*)
C  += $(wildcard arch/src/*.c*) $(wildcard arch/*/src/*.c*)
H  += $(wildcard arch/inc/*.h*) $(wildcard arch/*/inc/*.h*)
C  += $(wildcard   os/src/*.c*) $(wildcard   os/*/src/*.c*)
H  += $(wildcard   os/inc/*.h*) $(wildcard   os/*/inc/*.h*)

# ini
S  += $(wildcard lib/*.ini) $(wildcard lib/*.f)

# Python
P += $(wildcard src/*.py) $(wildcard lib/*.py)

# OCaml
O += $(wildcard lib/*.ml*)
