BEGIN {
  FS=""
  delete TOKENS
}

{
  tokenize()
  fflush()
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
            print token
            break
          case "(":
            state="comment"
            break
          default:
            print token
            print ""
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
        state="word"
        print token
        print ""
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
