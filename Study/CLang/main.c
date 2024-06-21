
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
    test(); // Compilation fails because it is a static keyword
    return 0;
}