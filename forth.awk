# KNOWN PROBLEMS
# minimal support for strings: ." works but consecutive spaces are collapsed

function interpret(word, _) {
  # print "interpret",word
  # print length(BRANCHES)
  if (STRING) {
    STRING=STRING " " word
    if (match(word, "\"$")) {
      print substr(STRING, 4, length(STRING)-4)
      STRING=""
    }
  } else if (word == "ELSE") {
    if (!length(BRANCHES))
      abort("mismatched ELSE statement")
    BRANCHES[length(BRANCHES)-1]=!BRANCHES[length(BRANCHES)-1]
  } else if (word == "THEN") {
    if (!length(BRANCHES))
      abort("mismatched THEN statement")
    delete BRANCHES[length(BRANCHES)-1]
  } else if (word == "IF") {
    BRANCHES[length(BRANCHES)]=isInSkippedBranch() || !!pop()
  } else if (isInSkippedBranch()) {
    # print "skip"
  } else if (word == word + 0)
    push(word + 0)
  else if (word == ".\"")
    STRING=word
  else
    run(word)
  # dump_stack()
  # print ""
}

function isInSkippedBranch(_, i) {
  for (i in BRANCHES)
    if (!BRANCHES[i])
      return 1
  return 0
}

function run(word, _, i, tmp1, tmp2) {
  if (word in WORDS)
    for (i in WORDS[word])
      interpret(WORDS[word][i])
  else switch (word) {
  case ".":
    print pop()
    break
  case "DUP":
    STACK[length(STACK)]=STACK[length(STACK)-1]
    break
  case "DROP":
    delete STACK[length(STACK)-1]
    break
  case "SWAP":
    tmp1=pop()
    tmp2=pop()
    push(tmp1)
    push(tmp2)
    break
  case "+":
    push(pop() + pop())
    break
  case "*":
    push(pop() * pop())
    break
  case "=":
    push(pop() == pop())
    break
  case "<":
    push(pop() > pop())
    break
  default:
    abort(word"?")
  }
}

function dump_stack() {
  for (i in STACK)
    print i": "STACK[length(STACK)-1-i]
}

function push(data) {
  STACK[length(STACK)]=data
}

function pop(_, data) {
  if (length(STACK) < 1) {
    abort("stack is empty!")
  }
  data=STACK[length(STACK)-1]
  delete STACK[length(STACK)-1]
  return data
}

function compile(word) {
  if (!COMPILED_WORD) {
    COMPILED_WORD=word
  } else {
    # print "compile",COMPILED_WORD,"adding",word
    WORDS[COMPILED_WORD][length(WORDS[COMPILED_WORD])]=word
  }
}

function compile_end(_, i, j) {
  # print "compile",COMPILED_WORD,"end"
  COMPILED_WORD=""
}

function abort(reason) {
  print reason > "/dev/stderr"
  exit 1
}

BEGIN {
  MODE="interpret"
  delete STACK
  delete WORDS
  delete BRANCHES
}

{
  repl()
}

function repl(_, i) {
  for (i = 1; i <= NF; ++i)
    if (COMMENT)
      COMMENT=!match($i,"\\)$")
    else
      switch ($i) {
      case ":":
        MODE="compile"
        break
      case ";":
        compile_end()
        MODE="interpret"
        break
      case "(":
        COMMENT=1
        break
      default:
        @MODE($i)
      }
}

END {
  # dump_stack()
}
