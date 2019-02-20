BEGIN {
  FS="\n"
  RS=""
  STATE="interpret"
  IPTR=1
  delete WORD_BUFFER
  delete ARG_BUFFER
  delete STACK
  delete RSTACK
}

{
  WORD_BUFFER[NR]=$1
  ARG_BUFFER[NR]=$2
  while (IPTR in WORD_BUFFER) {
    WORD=WORD_BUFFER[IPTR]
    ARG=ARG_BUFFER[IPTR]
    # print IPTR, STATE, WORD, ARG > "/dev/stderr"
    @STATE()
  }
  fflush()
}

function interpret() {
  switch (WORD) {
  case ":":
    ++IPTR
    STATE="compile"
    break
  case ";":
    IPTR=rpop()
    break
  case "IF":
    if (pop())
      ++IPTR
    else
      IPTR=ARG+1
    break
  case "ELSE":
    IPTR=ARG
  case "THEN":
    ++IPTR
    break
  case "BEGIN":
    ++IPTR
    break
  case "UNTIL":
    if (pop())
      ++IPTR
    else
      IPTR=ARG
    break
  default:
    if (WORD in WORDS) {
      rpush(IPTR+1)
      IPTR=WORDS[WORD]
    } else {
      builtin()
      ++IPTR
    }
  }
}

function compile() {
  WORDS[WORD]=IPTR+1
  IPTR=ARG_BUFFER[IPTR-1]+1
  STATE="interpret"
}

function builtin(_, tos, nos) {
  switch (WORD) {
  case "+": tos=pop() ; nos=pop() ; push(nos + tos) ; break
  case "-": tos=pop() ; nos=pop() ; push(nos - tos) ; break
  case "*": tos=pop() ; nos=pop() ; push(nos * tos) ; break
  case "/": tos=pop() ; nos=pop() ; push(nos / tos) ; break
  case "<": tos=pop() ; nos=pop() ; push(nos < tos) ; break
  case "<=": tos=pop() ; nos=pop() ; push(nos <= tos) ; break
  case "=": tos=pop() ; nos=pop() ; push(nos == tos) ; break
  case ">=": tos=pop() ; nos=pop() ; push(nos >= tos) ; break
  case ">": tos=pop() ; nos=pop() ; push(nos > tos) ; break
  case "DUP": tos=pop() ; push(tos) ; push(tos) ; break
  case "SWAP": tos=pop() ; nos=pop() ; push(tos) ; push(nos) ; break
  case "DROP": pop() ; break
  case ".": tos=pop() ; printf(tos % 1 ? "%f" : "%d", tos) ; break
  case ".\"": printf("%s", ARG) ; break
  case "CR": print "" ; break
  case "BYE": exit
  default:
    if (WORD == WORD + 0)
      push(WORD + 0)
    else
      error("unknown word")
  }
}

function push(value) {
  STACK[length(STACK)]=value
}

function pop(_, value) {
  if (!length(STACK))
    error("stack underflow")
  value=STACK[length(STACK)-1]
  delete STACK[length(STACK)-1]
  return value
}

function rpush(value) {
  RSTACK[length(RSTACK)]=value
}

function rpop(_, value) {
  if (!length(RSTACK))
    error("return stack underflow")
  value=RSTACK[length(RSTACK)-1]
  delete RSTACK[length(RSTACK)-1]
  return value
}

function error(message) {
  print "error: " message " (at " WORD ")" > "/dev/stderr"
  exit 1
}
