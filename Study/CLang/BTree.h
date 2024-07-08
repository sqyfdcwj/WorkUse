
#ifndef BTREE_H
#define BTREE_H

#include "DSDef.h"
/*
A B-Tree node with order M has at least ceil(M / 2) - 1 keys
For a B-Tree node with K keys, if it is not leaf node then it have K + 1 children

*/

typedef struct _BTree* BTree;
typedef struct _BTreeNode* BTreeNode;
typedef DSScalar BTreeOrder;
typedef DSScalar BTreeIndex;

/* Begin of BTree public function declarations */
BTree btree_new(BTreeOrder);
BTree btree_delete(BTree);

DSResult btree_insert(BTree, DSKey, DSVal);
/* End of BTree public function declarations */

BTreeNode btnode_new(BTreeOrder, DSScalar, DSScalar);
BTreeNode btnode_delete(BTreeNode);

DSResult btnode_addKey(BTreeNode, DSKey);
DSResult btnode_delKey(BTreeNode, DSIndex, DSKey*);

DSResult btnode_addChild(BTreeNode, BTreeNode);
DSResult btnode_delChild(BTreeNode, DSIndex, BTreeNode*);

DSResult btnode_split(BTreeNode, BTreeNode*, DSKey, BTreeNode, DSKey*);

DSResult btnode_print(BTreeNode);

#endif