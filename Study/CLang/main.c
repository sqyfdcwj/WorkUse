
#include <stdio.h>
#include <errno.h>
#include "file.h"

int main()
{
    FILE *f = fopen("a.txt", "a");
    fclose(f);
    return 0;
}