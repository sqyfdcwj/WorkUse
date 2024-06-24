
#include <stdio.h>
#include "misc.h"

// The following macro prints the flag state if it is enabled
#define fep(lhs, rhs) \
do { \
    if (lhs & rhs) { \
        printf("Enabled:\t%4s\t0x%04x\n", #rhs, rhs); \
    } \
} while (0)

int misch = 330;


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

unsigned short getBit(unsigned short s, size_t offset) { return s & (1 << offset); }

/**
 * @param s
 * @param size_t Zero based offset
 */
unsigned short enable(unsigned short s, size_t offset) { return s | (1 << offset); }

/**
 * @param s
 * @param size_t Zero based offset
 */
unsigned short disable(unsigned short s, size_t offset) { return s & ~(1 << offset); }

/**
 * @param s
 * @param size_t Zero based offset
 */
unsigned short toggle(unsigned short s, size_t offset) { return s ^ (1 << offset); }

void printBin(unsigned short s)
{
    for (size_t i = 0; i < 16; i++) {
        printf("%s", s & (1 << (15 - i)) ? "1" : "0");
    }
    printf("\n");
}

/**
 * Compilation will fail if any code from other files try to access this function,
 * even the IDE intellicense has hints.
 */
static 
void test() { printf("Test"); }