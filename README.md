# forth-awk

Forth interpreter written in Awk

## USAGE

Run the REPL like this:

```console
$ awk -f lexer.awk | awk -f parser.awk | awk -f interpreter.awk
```

## FEATURES

- Live evaluation
- Builtin words
  - Arithmetic operators
  - Number comparisons
  - Stack operations
- Word definition with `:` ... `;`
- Conditional execution with `IF` ... `ELSE` ... `THEN`
- Loops with
  - `BEGIN` ... `UNTIL`
  - `DO` ... `LOOP`
  - `DO` ... `+LOOP`
