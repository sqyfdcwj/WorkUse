
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <limits.h>

#include "misc.h"

int main()
{
    printBin(~(1 << 7));
    printBin(-1);
    printBin(-1 & ~(1 << 7));
    return 0;
}