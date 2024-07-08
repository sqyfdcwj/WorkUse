
#ifndef AVLTREE_H
#define AVLTREE_H

#include "DSDef.h"

typedef struct _AVLTree* AVLTree;   // AVL tree pointer
typedef struct _AVLNode* AVLNode; // AVL node pointer
// typedef size_t DSTreeTraverseMode;        // AVL traverse mode

typedef void (*AVLNodeFunc)(AVLNode);  // void function which accepts AVLNode
typedef void (*AVLValFunc)(DSVal);  // void function which accepts DSVal

/* Begin of struct _AVLTree public function declarations */
AVLTree avl_new();
AVLTree avl_delete(AVLTree);

DSScalar avl_h(AVLTree);
DSScalar avl_elementCount(AVLTree);

DSResult avl_insert(AVLTree, DSKey, DSVal);
DSVal avl_remove(AVLTree, DSKey);
DSVal avl_search(AVLTree, DSKey);

DSResult avl_walk_n(AVLTree, AVLNodeFunc, DSTreeTraverseMode);
DSResult avl_walk_v(AVLTree, AVLValFunc, DSTreeTraverseMode);
/* End of of struct _AVLTree public function declarations */

/* Begin of struct _AVLNode public function declarations */
DSScalar avln_h(AVLNode);
DSKey avln_key(AVLNode);
DSVal avln_val(AVLNode);
/* End of struct _AVLNode public function declarations */

#endif