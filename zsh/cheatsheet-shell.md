# Zsh/Bash Shell Scripting Cheat Sheet

## Special Variables

- `$@` : All arguments, as separate words
- `$*` : All arguments, as a single word
- `$#` : Number of arguments
- `$?` : Exit status of last command
- `$$` : PID of current shell
- `$!` : PID of last background job

## Quoting

- `"$var"` : Expands variables safely (preserves spaces)
- `'text'` : Literal string, no expansion

## Arrays

- `arr=(one two three)`
- `${arr[0]}` : First element
- `${arr[@]}` : All elements

## Functions

```sh
myfunc() {
  echo "Hello $1"
}
```

## printf

- `printf "%s\n" "$@"` : Print each argument on a new line

## Conditionals

```sh
if [[ "$var" == "foo" ]]; then
  echo "Match"
fi
```

## Loops

```sh
for x in "$@"; do
  echo $x
done
```

## Pipes & Redirection

- `|` : Pipe output
- `>` : Redirect output (overwrite)
- `>>` : Redirect output (append)
- `<` : Input redirection

## Common Symbols

- `%s` : String format in printf
- `\n` : Newline
- `#` : Comment

## Useful Commands

- `echo` : Print text
- `cat` : Show file contents
- `grep` : Search text
- `cut` : Split columns
- `awk` : Text processing
- `sed` : Stream editor
- `fzf` : Fuzzy finder

---

Keep this file open for quick reference!

:{range}![!]{filter} [!][arg] _:range!_
For executing external commands see |:!|
Filter {range} lines through the external program
{filter}. Vim replaces the optional bangs with the
latest given command and appends the optional [arg].
Vim saves the output of the filter command in a
temporary file and then reads the file into the buffer
|tempfile|. Vim uses the 'shellredir' option to
redirect the filter output to the temporary file.
However, if the 'shelltemp' option is off then pipes
are used when possible (on Unix).
When the 'R' flag is included in 'cpoptions' marks in
the filtered lines are deleted, unless the
|:keepmarks| command is used. Example:
:keepmarks '<,'>!sort
When the number of lines after filtering is less than
before, marks in the missing lines are deleted anyway.

4.2 Substitute

_:substitute_  
_:s_ _:su_

:[range]s[ubstitute]/{pattern}/{string}/[flags] [count]
For each line in [range] replace a match of {pattern}
with {string}.
For the {pattern} see |pattern|.
{string} can be a literal string, or something
special; see |sub-replace-special|.
When [range] and [count] are omitted, replace in the
current line only. When [count] is given, replace in
[count] lines, starting with the last line in [range].
When [range] is omitted start in the current line.
_E939_ _E1510_
[count] must be a positive number (max 2147483647)
Also see |cmdli
See |:s_flags| for [flags].
The delimiter doesn't need to be /, see
|pattern-delimiter|.

:[range]s[ubstitute] [flags] [count]
:[range]&[&][flags] [count]

Repeat last :substitute with same search pattern and
substitute string, but without the same flags. You
may add [flags], see |:s_flags|.
Note that after `:substitute` the '&' and '#' flags
can't be used, they're recognized as a pattern
separator.
The space between `:substitute` and the 'c', 'g',
'i', 'I' and 'r' flags isn't required, but in scripts
it's a good idea to keep it to avoid confusion.
Also see the two and three letter commands to repeat
:substitute below |:substitute-repeat|.

_:~_
:[range]~[&][flags] [count]  
epeat last substitute with same substitute string
but with last used search pattern. This is like
`:&r`. See |:s_flags| for [flags].

# --preview '[[$(file --mime {}) == *text*]] && bat # # --color=always --style=plain {} || ls -la --color=always {}'
