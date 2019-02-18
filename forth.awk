BEGIN {
  FS=""
  delete TOKENS
  delete WORDS
  delete STACK
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
  val=arr[length(arr)-1]
  delete arr[length(arr)-1]
  debug("pop", val)
  return val
}

function parse(_, state, i, j, token, compiled_word, compiled_body, arg) {
  state="interpret"
  for (i in TOKENS) {
    token=TOKENS[i]
    debug("parse", state, token)
    switch (state) {
    case "interpret":
      switch (token) {
      case ":":
        state="compile"
        break
      case ".\"":
        arg=TOKENS[i+1]
        delete TOKENS[i+1]
        run(token, arg)
        break
      case "":
        break
      default:
        run(token)
      }
      break
    case "compile":
      compiled_word=token
      delete compiled_body
      state="compile-body"
      break
    case "compile-body":
      switch (token) {
      case ";":
        for (j in compiled_body)
          WORDS[compiled_word][j]=compiled_body[j]
        printf(": %s", compiled_word)
        for (j in compiled_body)
          printf(" %s", compiled_body[j])
        print " ;"
        state="interpret"
        break
      default:
        push(compiled_body, token)
      }
      break
    }
  }
  if (state == "interpret")
    for (j in TOKENS)
      if (j <= i)
        delete TOKENS[j]
  # else reprocess everything
}

function run(word, arg, _, tos, nos, i) {
  # DEBUG=1
  debug("run", word, arg)
  switch (word) {
  case "+": tos=pop(STACK) ; nos=pop(STACK) ; push(STACK, nos + tos) ; break
  case "*": tos=pop(STACK) ; nos=pop(STACK) ; push(STACK, nos * tos) ; break
  case "=": tos=pop(STACK) ; nos=pop(STACK) ; push(STACK, nos == tos) ; break
  case "DUP": tos=pop(STACK) ; push(STACK, tos) ; push(STACK, tos) ; break
  case "SWAP": tos=pop(STACK) ; nos=pop(STACK) ; push(STACK, tos) ; push(STACK, nos) ; break
  case ".": tos=pop(STACK) ; printf(tos == int(tos) ? "%d" : "%f", tos) ; break
  default:
    if (word == word+0)
      push(STACK, word+0)
    else if (word in WORDS)
      for (i in WORDS[word])
        run(WORDS[word][i])
    else
      error("unknown word: " word)
  }
  debug()
  # DEBUG=0
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
