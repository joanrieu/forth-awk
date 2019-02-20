BEGIN {
  FS="\n"
  RS=""
  reset()
}

function reset() {
  DEPTH=0
  delete TOKEN_BUFFER
  delete CURRENT_GROUP_ID
  delete GROUP
  delete GROUP_ID
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
  case ":":
    assert(DEPTH == 0)
    createGroup()
    saveTokenToGroup(token)
    break
  case "IF":
  case "BEGIN":
    createGroup()
    saveTokenToGroup(token)
    break
  case "ELSE":
    assert(DEPTH > 0 && isAlreadyInGroup("IF") && !isAlreadyInGroup("ELSE"))
    saveTokenToGroup(token)
    break
  case ";":
    assert(DEPTH == 1 && isAlreadyInGroup(":"))
    saveTokenToGroup(token)
    closeGroup()
    break
  case "THEN":
    assert(DEPTH > 0 && isAlreadyInGroup("IF"))
    saveTokenToGroup(token)
    closeGroup()
    break
  case "UNTIL":
    assert(DEPTH > 0 && isAlreadyInGroup("BEGIN"))
    saveTokenToGroup(token)
    closeGroup()
    break
  }
}

function createGroup() {
  CURRENT_GROUP_ID[++DEPTH]=NR
}

function saveTokenToGroup(token) {
  GROUP_ID[NR]=CURRENT_GROUP_ID[DEPTH]
  GROUP[GROUP_ID[NR]][token]=NR
}

function isAlreadyInGroup(token) {
  return token in GROUP[CURRENT_GROUP_ID[DEPTH]]
}

function closeGroup() {
  delete CURRENT_GROUP_ID[DEPTH--]
}

function printBufferedTokens(_, i) {
  if (DEPTH == 0) {
    for (i in TOKEN_BUFFER) {
      print TOKEN_BUFFER[i]
      if (i in GROUP_ID) {
        switch (TOKEN_BUFFER[i]) {
          case ":":
            print GROUP[GROUP_ID[i]][";"]
            break
          case "IF":
            if ("ELSE" in GROUP[GROUP_ID[i]])
              print GROUP[GROUP_ID[i]]["ELSE"]
            else
              print GROUP[GROUP_ID[i]]["THEN"]
            break
          case "ELSE":
            print GROUP[GROUP_ID[i]]["THEN"]
          case "UNTIL":
            print GROUP[GROUP_ID[i]]["BEGIN"]
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
