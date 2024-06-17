Some notes about <stdio.h>

EOF is defined as -1

|Action|Method|Return on succ|Return on fail|
|:-:|:-:|:-:|:-:|
|write|fprintf|Number of chars written|EOF|
|write|printf|Number of chars written|EOF|
|write|sprintf||
|write|fputs|Number of chars written|EOF|
|write|puts|Non-negative int|EOF|
|write|fputc / putc|input char|EOF|
|write|putchar|input char|EOF|
|write|fwrite|Number of record written|0|


1. `fopen` returns `NULL` when `mode` is either `r` or `r+` and file does not exist
2. `fprintf` and `fputs` accepts param `FILE`. It returns number of characters written on success, or `-1 (EOF)` on failure. E.g. write to readonly `FILE`.
3. `puts` automatically appends `\n` at the last, which `fputs`, `printf` and `fprintf` does not.
4. `putchar` and `fputc` returns input character on success, or `-1(EOF)` on failure.
5. You must provide valid char buffer for `sprintf`. Passing char* which does not point to valid buffer causes fatal fault.
