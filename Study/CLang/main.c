
#include "misc.h"

/*
auto	
register	
extern	
volatile
static	
 */

int main()
{
    printBin(~(1 << 7));
    printBin(-1);
    printBin(-1 & ~(1 << 7));
    return 0;
}