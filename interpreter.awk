BEGIN {
  FS="\n"
  RS=""
  STATE="interpret"
  IPTR=1
  delete WORD_BUFFER
  delete ARG_BUFFER
  delete STACK
  delete RSTACK
  delete LOOP_INDEX
  delete LOOP_LIMIT
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
  interpret_function_definition() || interpret_if_else_then() || interpret_begin_until() || interpret_do_loop() || interpret_builtin_word() || interpret_number() || interpret_user_defined_word() || error("unknown word")
}

# : word foo bar ;
function interpret_function_definition() {
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
function interpret_do_loop() {
  switch (WORD) {
  case "DO":
    LOOP_INDEX[length(LOOP_INDEX)+1]=pop()
    LOOP_LIMIT[length(LOOP_LIMIT)+1]=pop()
    ++IPTR
    return 1
  case "I":
    if (length(LOOP_INDEX) < 1)
      error("no loop")
    push(LOOP_INDEX[length(LOOP_INDEX)])
    ++IPTR
    return 1
  case "J":
    if (length(LOOP_INDEX) < 2)
      error("no outer loop")
    push(LOOP_INDEX[length(LOOP_INDEX)-1])
    ++IPTR
    return 1
  case "LOOP":
  case "+LOOP":
    LOOP_INDEX[length(LOOP_INDEX)]+=(WORD == "LOOP" ? 1 : pop())
    if (LOOP_INDEX[length(LOOP_INDEX)] != LOOP_LIMIT[length(LOOP_LIMIT)]) {
      IPTR=ARG+1
    } else {
      ++IPTR
      delete LOOP_INDEX[length(LOOP_INDEX)]
      delete LOOP_LIMIT[length(LOOP_LIMIT)]
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
  case "CR": print "" ; break
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

function pop(_, value) {
  if (!length(STACK))
    error("stack underflow")
  value=STACK[length(STACK)]
  delete STACK[length(STACK)]
  return value
}

function rpush(value) {
  RSTACK[length(RSTACK)+1]=value
}

function rpop(_, value) {
  if (!length(RSTACK))
    error("return stack underflow")
  value=RSTACK[length(RSTACK)]
  delete RSTACK[length(RSTACK)]
  return value
}

function error(message) {
  print "error: " message " (at " WORD ")" > "/dev/stderr"
  exit 1
}
