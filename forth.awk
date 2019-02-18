BEGIN {
  FS=""
  PARSER_POSITION=0
  PARSER_STATE="interpret"
  delete TOKENS
  delete WORDS
  delete STACK
  delete IFS
  delete LOOPS
}

{
  tokenize()
  parse()
}

function tokenize(_, state, token, i) {
  $0=$0" "
  state="word"
  token=""
  for (i=1; i<=NF; ++i) {
    switch (state) {
    case "word":
      switch ($i) {
      case " ":
        if (token) {
          switch (token) {
          case ".\"":
            state="string"
            push(TOKENS, token)
            break
          case "(":
            state="comment"
            break
          default:
            push(TOKENS, token)
          }
          token=""
        }
        break
      default:
        token=token $i
      }
      break
    case "string":
      switch ($i) {
      case "\"":
        push(TOKENS, token)
        state="word"
        token=""
        break
      default:
        token=token $i
      }
      break
    case "comment":
      switch ($i) {
        case ")":
          state="word"
          break
      }
    }
  }
}

function push(arr, elem) {
  arr[length(arr)]=elem
  debug("push", elem)
}

function pop(arr, _, val) {
  if (length(arr) == 0)
    error("cannot pop value from empty stack")
  val=arr[length(arr)-1]
  delete arr[length(arr)-1]
  debug("pop", val)
  return val
}

function peek(arr) {
  if (length(arr) > 0)
    return arr[length(arr)-1]
}

function parse(_, state, token) {
  for (; PARSER_POSITION < length(TOKENS); ++PARSER_POSITION) {
    token=TOKENS[PARSER_POSITION]
    debug("parse", PARSER_STATE, token)
    switch (PARSER_STATE) {
    case "interpret":
      switch (token) {
      case ":":
        PARSER_STATE="compile"
        break
      case ".\"":
        run(token, TOKENS[PARSER_POSITION+1])
        ++PARSER_POSITION
        break
      default:
        run(token)
      }
      break
    case "compile":
      WORDS[token]=PARSER_POSITION+1
      PARSER_STATE="compile-body"
      break
    case "compile-body":
      if (token == ";")
        PARSER_STATE="interpret"
      break
    }
  }
}

function run(word, arg, _, tos, nos, i) {
  debug("run", word, arg)
  switch (word) {
  case "+": tos=pop(STACK) ; nos=pop(STACK) ; push(STACK, nos + tos) ; break
  case "*": tos=pop(STACK) ; nos=pop(STACK) ; push(STACK, nos * tos) ; break
  case "=": tos=pop(STACK) ; nos=pop(STACK) ; push(STACK, nos == tos) ; break
  case "DUP": tos=pop(STACK) ; push(STACK, tos) ; push(STACK, tos) ; break
  case "SWAP": tos=pop(STACK) ; nos=pop(STACK) ; push(STACK, tos) ; push(STACK, nos) ; break
  case ".": tos=pop(STACK) ; printf(tos == int(tos) ? "%d" : "%f", tos) ; break
  case ".\"": printf("%s", arg) ; break
  default:
    if (word == word+0)
      push(STACK, word+0)
    else if (word in WORDS)
      for (i = WORDS[word]; TOKENS[i] != ";"; ++i)
        run(TOKENS[i])
    else
      error("unknown word: " word)
  }
}

function error(msg) {
  fflush()
  print "error: " msg > "/dev/stderr"
  exit 1
}

function debug(a, b, c, d, e, f) {
  if (DEBUG) {
    fflush()
    print "debug:", a, b, c, d, e, f > "/dev/stderr"
  }
}
