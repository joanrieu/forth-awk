# forth-awk

Forth interpreter written in Awk

![](https://i.imgur.com/V7i0R62.gif)

## USAGE

Run the REPL like this:

```console
$ ./forth-awk
```

Then just start typing Forth code!

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

## REQUIREMENTS

This software has only been tested using GNU Awk.
It may or may not work with other implementations.
