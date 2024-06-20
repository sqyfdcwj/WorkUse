
#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <limits.h>

typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;

void printBin(ushort i)
{
    for (uint bit = 0; bit < 16; bit++) {
        printf("%s", i & (1 << (15 - bit)) ? "1" : "0");
    }
    printf("\n");
}

ushort enable(ushort i, ushort bit)
{
    return i | (1 << bit);
}

ushort disable(ushort i, ushort bit)
{
    return i & ~(1 << bit);
}

ushort toggle(ushort i, ushort bit)
{
    return i;
}

int main()
{
    ushort s = -1;
    printBin(s);
    s = disable(s, 3);
    printBin(s);
    s = disable(s, 4);
    printBin(s);

    return 0;
}