
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include "file.h"

int main()
{
    FILE *f = fopen("a.txt", "r");
    fpos_t pos;
    flag(f);
    printf("\n");
    fseek(f, 2, SEEK_SET);
    flag(f);
    fsetpos(f, &pos);
    return 0;
}