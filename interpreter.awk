BEGIN {
  FS="\0"
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
    # print "IPTR=" IPTR " STATE=" STATE " WORD=" WORD " ARG=" ARG > "/dev/stderr"
    @STATE()
  }
  fflush()
}

function interpret() {
  interpret_word_definition() || interpret_if_else_then() || interpret_begin_until() || interpret_do_loop() || interpret_builtin_word() || interpret_number() || interpret_user_defined_word() || error("unknown word")
}

# : word foo bar ;
function interpret_word_definition() {
  switch (WORD) {
  case ":":
    ++IPTR
    STATE="compile"
    return 1
  case ";":
    IPTR=rpop()
    return 1
 }
}

# condition IF foo ELSE bar THEN
function interpret_if_else_then() {
  switch (WORD) {
  case "IF":
    if (pop())
      ++IPTR
    else
      IPTR=ARG+1
    return 1
  case "ELSE":
    IPTR=ARG+1
    return 1
  case "THEN":
    ++IPTR
    return 1
  }
}

# BEGIN foo bar condition UNTIL
function interpret_begin_until() {
  switch (WORD) {
  case "BEGIN":
    ++IPTR
    return 1
  case "UNTIL":
    if (pop())
      ++IPTR
    else
      IPTR=ARG
    return 1
  }
}

# limit start DO foo bar LOOP
# limit start DO foo bar increment +LOOP
# I --> index inside loop
# J --> index of outer loop when nested
function interpret_do_loop(_, i, limit) {
  switch (WORD) {
  case "DO":
    i=pop()
    limit=pop()
    rpush(limit)
    rpush(i)
    ++IPTR
    return 1
  case "I":
    push(rpeek())
    ++IPTR
    return 1
  case "J":
    i=rpop()
    limit=rpop()
    push(rpeek())
    rpush(limit)
    rpush(i)
    ++IPTR
    return 1
  case "LOOP":
  case "+LOOP":
    i=rpop()
    limit=rpeek()
    i+=(WORD == "LOOP" ? 1 : pop())
    rpush(i)
    if (i != limit) {
      IPTR=ARG+1
    } else {
      ++IPTR
      rpop()
      rpop()
    }
    return 1
  }
}

function interpret_builtin_word(_, tos, nos) {
  switch (WORD) {
  # arithmetic operations
  case "+": tos=pop() ; nos=pop() ; push(nos + tos) ; break
  case "-": tos=pop() ; nos=pop() ; push(nos - tos) ; break
  case "*": tos=pop() ; nos=pop() ; push(nos * tos) ; break
  case "/": tos=pop() ; nos=pop() ; push(nos / tos) ; break
  # number comparisons
  case "<": tos=pop() ; nos=pop() ; push(nos < tos) ; break
  case "<=": tos=pop() ; nos=pop() ; push(nos <= tos) ; break
  case "=": tos=pop() ; nos=pop() ; push(nos == tos) ; break
  case ">=": tos=pop() ; nos=pop() ; push(nos >= tos) ; break
  case ">": tos=pop() ; nos=pop() ; push(nos > tos) ; break
  # stack operations
  case "DUP": tos=pop() ; push(tos) ; push(tos) ; break
  case "SWAP": tos=pop() ; nos=pop() ; push(tos) ; push(nos) ; break
  case "OVER": tos=pop() ; nos=pop() ; push(nos) ; push(tos) ; push(nos) ; break
  case "DROP": tos=pop() ; break
  # IO
  case ".": tos=pop() ; printf(tos % 1 ? "%f" : "%d", tos) ; break
  case ".\"": printf("%s", ARG) ; break
  case "EMIT": tos=pop() ; printf("%c", tos) ; break
  case "CR": printf("\n") ; break
  # control
  case "BYE": exit
  default: return
  }
  ++IPTR
  return 1
}

function interpret_number() {
  if (WORD == WORD + 0) {
    push(WORD + 0)
    ++IPTR
    return 1
  }
}

function interpret_user_defined_word() {
  if (WORD in WORDS) {
    rpush(IPTR+1)
    IPTR=WORDS[WORD]
    return 1
  }
}

function compile() {
  WORDS[WORD]=IPTR+1
  IPTR=ARG_BUFFER[IPTR-1]+1
  STATE="interpret"
}

function push(value) {
  STACK[length(STACK)+1]=value
}

function peek() {
  if (!length(STACK))
    error("stack underflow")
  return STACK[length(STACK)]
}

function pop(_, value) {
  value=peek()
  delete STACK[length(STACK)]
  return value
}

function rpush(value) {
  RSTACK[length(RSTACK)+1]=value
}

function rpeek() {
  if (!length(RSTACK))
    error("return stack underflow")
  return RSTACK[length(RSTACK)]
}

function rpop(_, value) {
  value=rpeek()
  delete RSTACK[length(RSTACK)]
  return value
}

function error(message) {
  print "error: " message " (at " WORD ")" > "/dev/stderr"
  exit 1
}
