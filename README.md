# forth-awk

Forth interpreter written in Awk

## USAGE

Run the REPL like this:

```console
$ ./forth-awk
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
