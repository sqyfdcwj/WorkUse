Unless specifed, the term `awk` refers to GNU awk.

Built-in functions of awk

String manipulation related

`index(haystack, needle)` 
Return the index (1 based) of first occurance of `needle` in `haystack`, or 0 if not found.
> index("abca", "a") # 1
> index("abca", "b") # 2
> index("abca", "bc") # 2
> index("abca", "d") # 0

`substr(str, start [, length])`
Return a substring from `str` at index `start` (1 based) with `length`
If `length` is not provided, return the whole substring from index `start`.
> print substr("abcdefg", 1) # abcdefg
> print substr("abcdefg", 3, 4) # cdef
> print substr("abcdefg", 6, 3) # fg

`length(str)`
Return the length of string

`match(haystack, regexp)`
Find ocurrances in `haystack` that matched by `regexp`.
After that, the built-in variable `RSTART` and `RLENGTH` will be set based on the first occurance found.
`RSTART` index of matched string in `haystack`, 0 if not found
`RLENGTH` length of matched string in `haystack`, -1 if not found

> match("bananaban", "(an)+")
> print RSTART, RLENGTH # 2, 4
> match("bananaban", "nox")
> print RSTART, RLENGTH # 0, -1

`split(str, arrayName, separator)`
Split `str` with `separator` and save the result into `arrayName`
In awk, array index is 1 based
> split("abpcdpef", arr, "p")
> print arr[1], arr[2], arr[3] # ab, cd, ef

`join()`

`sprintf(format, data)`
Format `data` with `format` and return the formatted result
> print sprintf("%.3f", "1.2345") # 1.234
> print sprintf("%.3f", "1.2346") # 1.235

`sub(regexp, replacement [, target])`
Alter `target` by substituting the leftmost longest substring matched by `regexp` with `replacement` and return the number of substitution made (either 1 or 0).
> str = bananaban
> print sub("(an)+", "en", str) # 1
> print str # benaban

`sub(regexp, replacement [, target])`
This is similar to `sub` function, except `gsub` replaces all of the longest, leftmost, nonoverlapping matching substrings it can find.
> str = bananaban
> print gsub("(an)+", "en", str) # 2
> print str # benaben

`gensub(regexp, replacement, how [, target])`
Searches target string for matches of `regexp` like `sub` and `gsub` do. Unlike `sub` and `gsub`, the modified string is returned as result of function and the original string is not changed. 
If `how` is a string beginning with `g` or `G`, then it replaces all matches of `regexp` with `replacement`.
Otherwise `how` is treated as a number that `how`th match of `regexp` is replaced.
If no `target` is supplied, `$0` is used.
> before = "a b c a d e a "
> after = gensub("a", "A", 2, before)

`gensub` can also specify components of a regexp in the replacement text.
This is done by using parentheses in the `regexp` to mark the components and then specifying `\N` in the replacement text, where `N` is a digit from 1 to 9.

> a = "123 456 789"
> b = gensub("([0-9]+) ([0-9]+) ([0-9]+)", "\\3 \\1 \\2", "g", a)
> print b # 789 123 456 (a is not affected)

`toupper(str)`
`tolower(str)`