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
      if ($i ~ /\s/) {
        if (token) {
          switch (token) {
          case ".\"":
            state="string"
            printf("%s\0", token)
            break
          case "(":
            state="comment"
            break
          case "\\":
            i=NF
            break
          default:
            printf("%s\n", token)
          }
          token=""
        }
      } else {
        token=token $i
      }
      break
    case "string":
      if ($i == "\"") {
        state="word"
        printf("%s\n", token)
        token=""
      } else {
        token=token $i
      }
      break
    case "comment":
      if ($i == ")")
        state="word"
      break
    }
  }
}
