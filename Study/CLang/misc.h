
#include <stdio.h>

void flag(FILE *f);

unsigned short getBit(unsigned short, size_t);

unsigned short enable(unsigned short, size_t);

unsigned short disable(unsigned short, size_t);

unsigned short toggle(unsigned short, size_t);

void printBin(unsigned short);

/**
 * If used static keyword, it is visibie only in this file
 * compilation will fail if any code from other file call this test();
 */
static 
void test();