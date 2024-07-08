
#ifndef DSDEF_H
#define DSDEF_H

#include <stdlib.h>
#include <stdio.h>

typedef size_t DSResult;    // Data structure operation result
typedef size_t DSScalar;    // Represent a scalar
typedef size_t DSTreeTraverseMode;  // Traverse mode for tree structure
typedef DSScalar DSIndex;

#define DS_R_OK 0     // Tree operation is successful
#define DS_R_INVARG 1 // Tree argument is invalid
#define DS_R_MALLOC 2 // Failed to allocate memory
#define DS_R_KEYNF 3  // Tree key not found
#define DS_R_KEYDUP 4 // Tree key duplicated
#define DS_R_INVOP 5  // Tree operation failed
#define DS_R_KEYFULL 6  // Some tree structure specific

#define DST_TMODE_INORDER 0
#define DST_TMODE_PREORDER 1
#define DST_TMODE_POSTORDER 2

enum DSValType
{    
    vt_n,    // NULL (this value is used when incoming AVLVal is NULL)
    vt_i,    // int
    vt_d,    // double
    vt_s,    // char*
    vt_p     // void*
};

typedef size_t DSKey;        // Key used in tree structure
typedef struct _DSVal* DSVal;// Value used in tree structure

typedef void (*DSValDtor)(void*);

/* Begin of struct _AVLValue public function declarations */
DSVal dsval_i_new(int);
DSVal dsval_d_new(double);
DSVal dsval_s_new(char*);
DSVal dsval_p_new(void*);
DSVal dsval_delete(DSVal, DSValDtor);

enum DSValType dsval_type(DSVal);   // Get AVLVal value type. Return avlvt_n if param is NULL
int dsval_i(DSVal);
double dsval_d(DSVal);
char* dsval_s(DSVal);
void* dsval_p(DSVal);
/* End of struct _AVLValue public function declarations */

#endif