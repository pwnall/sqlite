#!/usr/bin/tclsh
#
# This script appends additional token codes to the end of the
# parse.h file that lemon generates.  These extra token codes are
# not used by the parser.  But they are used by the tokenizer and/or
# the code generator.
#
#
set in [open [lindex $argv 0] rb]
set max 0
while {![eof $in]} {
  set line [gets $in]
  if {[regexp {^#define TK_([A-Z_]+) +(\d+)} $line all nm x]} {
    puts $line
    if {$x>$max} {set max $x}
    set tk($nm) $x
    set rtk($x) $nm
  }
}
close $in

# The following are the extra token codes to be added.  SPACE and 
# ILLEGAL *must* be the last two token codes and they must be in that order.
#
set extras {
  TRUEFALSE
  ISNOT
  FUNCTION
  COLUMN
  AGG_FUNCTION
  AGG_COLUMN
  UMINUS
  UPLUS
  TRUTH
  REGISTER
  VECTOR
  SELECT_COLUMN
  IF_NULL_ROW
  ASTERISK
  SPAN
  END_OF_FILE
  UNCLOSED_STRING
  SPACE
  ILLEGAL
}
if {[lrange $extras end-1 end]!="SPACE ILLEGAL"} {
  error "SPACE and ILLEGAL must be the last two token codes and they\
         must be in that order"
}
foreach x $extras {
  incr max
  puts [format "#define TK_%-29s %4d" $x $max]
  set tk($x) $max
  set rtk($max) $x
}

# Some additional #defines related to token codes.
#
puts "\n/* The token codes above must all fit in 8 bits */"
puts [format "#define %-20s %-6s" TKFLG_MASK 0xff]
puts "\n/* Flags that can be added to a token code when it is not"
puts "** being stored in a u8: */"
foreach {fg val comment} {
  TKFLG_DONTFOLD  0x100  {/* Omit constant folding optimizations */}
} {
  puts [format "#define %-20s %-6s %s" $fg $val $comment]
}

# Opcodes of significance to resolveExprStep()
#
set resolveOps {
  ROW
  ID
  DOT
  FUNCTION
  SELECT
  EXISTS
  VARIABLE
  IS
  ISNOT
  IN
  BETWEEN
  EQ
  NE
  LT
  LE
  GT
  GE
}

puts "\n"
puts {/* Symbols used by resolveExprStep() */}

set i 0
foreach x $resolveOps {
  puts [format "#define %-20s %3d" RESOLVE_$x $i]
  set rmap($x) $i
  incr i
}
set rmax $i
puts [format "#define %-20s %3d" RESOLVE_Max [expr {$rmax-1}]]
puts "#define RESOLVE_MAP \173\\"
set col 0
set sep \173
set rtk(0) noop
for {set i 0} {$i<=$max} {incr i} {
  if {$col>70} {
    puts "\\"
    set col 0
  }
  set nm $rtk($i)
  if {[info exists rmap($nm)]} {
    puts -nonewline " $rmap($nm),"
  } else {
    puts -nonewline " $rmax,"
  }
  incr col 4
}
puts " $rmax \175"
