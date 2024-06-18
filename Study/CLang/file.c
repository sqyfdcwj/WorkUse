
#include <stdio.h>
#include "file.h"

// The following macro prints the flag state if it is enabled
#define fep(lhs, rhs) \
do { \
    if (lhs & rhs) { \
        printf("Enabled:\t%4s\t0x%04x\n", #rhs, rhs); \
    } \
} while (0)

void flag(FILE *fp)
{
    if (!fp) { return; }
    short f = fp->_flags;
    fep(f, __SLBF);
    fep(f, __SNBF);
    fep(f, __SRD);
    fep(f, __SWR);
    fep(f, __SRW);
    fep(f, __SEOF);
    fep(f, __SERR);
    fep(f, __SMBF);
    fep(f, __SAPP);
    fep(f, __SSTR);
    fep(f, __SOPT);
    fep(f, __SNPT);
    fep(f, __SOFF);
    fep(f, __SMOD);
    fep(f, __SALC);
    fep(f, __SIGN);
}