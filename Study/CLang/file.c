
#include <stdio.h>
#include "file.h"

void flag(FILE *f)
{
    if (!f) { return; }
    printf("Flag: %x\n", f->_flags & -1);
}

