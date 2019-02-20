BEGIN {
  FS="\n"
  RS=""
  reset()
}

function reset() {
  DEPTH=0
  delete TOKEN_BUFFER
  delete CONTROL_ID
  delete CONTROL_TABLE
  delete CONTROL_REF
}

{
  parse()
  fflush()
}

function parse(_) {
  TOKEN_BUFFER[NR]=$0
  updateControlStructures()
  printBufferedTokens()
}

function updateControlStructures(_, token) {
  token=$1
  switch (token) {
  case "IF":
  case "BEGIN":
    ++DEPTH
    CONTROL_ID[DEPTH]=NR
    CONTROL_REF[NR]=CONTROL_ID[DEPTH]
    CONTROL_TABLE[CONTROL_REF[NR]][token]=NR
    break
  case "ELSE":
    assert(DEPTH)
    CONTROL_REF[NR]=CONTROL_ID[DEPTH]
    assert("IF" in CONTROL_TABLE[CONTROL_REF[NR]])
    assert(!("ELSE" in CONTROL_TABLE[CONTROL_REF[NR]]))
    CONTROL_TABLE[CONTROL_REF[NR]][token]=NR
    break
  case "THEN":
    assert(DEPTH)
    CONTROL_REF[NR]=CONTROL_ID[DEPTH]
    assert("IF" in CONTROL_TABLE[CONTROL_REF[NR]])
    assert(!("THEN" in CONTROL_TABLE[CONTROL_REF[NR]]))
    CONTROL_TABLE[CONTROL_REF[NR]][token]=NR
    --DEPTH
    break
  case "UNTIL":
    assert(DEPTH)
    CONTROL_REF[NR]=CONTROL_ID[DEPTH]
    assert("BEGIN" in CONTROL_TABLE[CONTROL_REF[NR]])
    assert(!("UNTIL" in CONTROL_TABLE[CONTROL_REF[NR]]))
    CONTROL_TABLE[CONTROL_REF[NR]][token]=NR
    --DEPTH
    break
  }
}

function printBufferedTokens(_, i) {
  if (!DEPTH) {
    for (i in TOKEN_BUFFER) {
      print TOKEN_BUFFER[i]
      if (i in CONTROL_REF) {
        switch (TOKEN_BUFFER[i]) {
          case "IF":
            if ("ELSE" in CONTROL_TABLE[CONTROL_REF[i]])
              print CONTROL_TABLE[CONTROL_REF[i]]["ELSE"]
            else
              print CONTROL_TABLE[CONTROL_REF[i]]["THEN"]
            break
          case "UNTIL":
            print CONTROL_TABLE[CONTROL_REF[i]]["BEGIN"]
            break
        }
      }
      print ""
    }
    reset()
  }
}

function assert(condition) {
  if (!condition) {
    print "syntax error: unexpected " $1 > "/dev/stderr"
    exit 1
  }
}
