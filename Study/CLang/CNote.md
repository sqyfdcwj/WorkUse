Some notes about <stdio.h>

EOF is defined as -1

|Action|Method|retval on succ|retval on fail|
|:-:|:-:|:-:|:-:|
|read|fgetc / getc|First read char|?|
|read|getchar|First read char|?|
|read|fgets|Pointer to buffer provided|NULL|
|read|fread|Number of read record|0|
|write|fprintf|Number of chars written|EOF|
|write|printf|Number of chars written|EOF|
|write|fputs|Number of chars written|EOF|
|write|puts|Non-negative int|EOF|
|write|fputc / putc|input char|EOF|
|write|putchar|input char|EOF|
|write|fwrite|Number of written record|0|
|pointer|fseek|0|Non 0|
|pointer|ftell|Current index|Unlikely fail|
|pointer|rewind|void|void|
|pointer|feof|1|0|
|error|clearerr|0|0|

1. `fopen` returns `NULL` when `mode` is either `r` or `r+` and file does not exist
