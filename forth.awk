# SUPPORTED (not fully implemented but easy to do)
# stack ops
# arithmetic
# comparison
# output

# KNOWN PROBLEMS
# minimal support for strings: ." works but consecutive spaces are collapsed
# syntax errors (such as unterminated branches or loops) can lead to undefined behavior

function interpret(word) {
  DEPTH=DEPTH+1
  # print "<"DEPTH">", "interpret", word
  # print length(BRANCHES)
  if (STRING) {
    # must be first in case the string contains a keyword
    # this block is not entered when evaluating a skipped branch
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
    BRANCHES[length(BRANCHES)]=is_in_skipped_branch() || !!pop()
  } else if (is_in_skipped_branch()) {
    # print "skip"
    # EVERYTHING BELOW WILL BE SKIPPED IF THE BRANCH IS SKIPPED
  } else if (word == word + 0)
    push(word + 0)
  else if (word == ".\"")
    STRING=word
  else
    run(word)
  # dump_stack()
  # print ""
  DEPTH=DEPTH-1
}

function is_in_skipped_branch(_, i) {
  for (i in BRANCHES)
    if (!BRANCHES[i])
      return 1
  return 0
}

function run(word, _, i, tos, nos) {
  if (word in WORDS)
    for (i in WORDS[word])
      interpret(WORDS[word][i])
  else switch (word) {
  case ".": print pop() ; break
  case "DROP": pop() ; break
  case "DUP": tos=pop() ; push(tos) ; push(tos) ; break
  case "SWAP": tos=pop() ; nos=pop() ; push(tos) ; push(nos) ; break
  case "+": tos=pop() ; nos=pop() ; push(nos + tos) ; break
  case "-": tos=pop() ; nos=pop() ; push(nos - tos) ; break
  case "*": tos=pop() ; nos=pop() ; push(nos * tos) ; break
  case "=": tos=pop() ; nos=pop() ; push(nos == tos) ; break
  case "<": tos=pop() ; nos=pop() ; push(nos < tos) ; break
  default: abort("unknown word: "word)
  }
}

function dump_stack() {
  print "stack"
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
  fflush()
  print "error: "reason > "/dev/stderr"
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
