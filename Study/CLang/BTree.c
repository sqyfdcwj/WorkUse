
#include "BTree.h"
#include <assert.h>
#include <string.h>

struct _BTree
{
    BTreeOrder ord;
    BTreeNode root;
};

struct _BTreeNode
{
    BTreeOrder order;
    DSScalar h; // Height;
    DSKey* keys;
    DSScalar keyCount;
    BTreeNode* children;
    DSScalar childCount;
};

/* Begin of struct _BTreeNode function declarations */
// BTreeNode btnode_new(BTreeOrder, DSScalar, DSScalar);
// BTreeNode btnode_delete(BTreeNode);

BTreeNode btnode_insert(BTreeNode, BTreeNode, DSKey, DSVal, DSResult*);
BTreeNode btnode_parent_insert(BTreeNode, DSKey, BTreeNode, DSResult*);

DSResult btnode_keyInsertIdx(BTreeNode, DSKey, DSIndex*);
DSResult btnode_childInsertIdx(BTreeNode, BTreeNode, DSIndex*);

DSScalar btnode_isFull(BTreeNode);

/* End of struct _BTreeNode function declarations */

/* Begin of struct _BTree function implementations */
BTree btree_new(BTreeOrder deg)
{
    if (deg < 3) {
        return NULL;
    }
    BTree tree = malloc(sizeof(struct _BTree));
    if (tree) {
        tree->ord = deg;
        tree->root = NULL;
    }
    return tree;
}

DSResult btree_insert(BTree tree, DSKey key, DSVal val)
{
    return 0;
}


/* End of struct _BTree function implementations */

/* Begin of struct _BTreeNode function implementations */

/**
 * A BTreeNode with order m can have most m - 1 keys
 * If it is not children, it can have most m children
 */
BTreeNode btnode_new(BTreeOrder order, DSScalar h, DSScalar isLeaf)
{
    BTreeNode node = malloc(sizeof(struct _BTreeNode));
    if (node) {
        node->keys = malloc(sizeof(DSKey) * (order - 1));
        if (!node->keys) {
            free(node);
            return NULL;
        }

        if (isLeaf) {
            node->children = NULL;
        } else {
            node->children = malloc(sizeof(BTreeNode) * order);
            if (!node->children) {
                free(node);
                return NULL;
            }
        }
        node->h = h;
        node->keyCount = 0;
        node->childCount = 0;
        node->order = order;
    }
    return node;
}

BTreeNode btnode_delete(BTreeNode node)
{
    if (node) {
        free(node->keys);
        if (node->children) {
            free(node->children);
        }
        free(node);
    }
    return NULL;
}

BTreeNode btnode_insert(
    BTreeNode parent,
    BTreeNode node, 
    DSKey key, 
    DSVal val,
    DSResult* result
)
{
    BTreeNode tmpParent = parent;
    size_t isRoot = parent == NULL;
    size_t isLeaf = node->children == NULL;

    if (!node) { return NULL; }   

    DSIndex idx;
    if (!isLeaf) {
        for (idx = 0; idx < node->childCount; idx++) {
            if (key < node->children[idx]->keys[0]) { break; }
            if (key == node->children[idx]->keys[0]) { 
                *result = DS_R_KEYDUP; 
                return NULL;
            }
        }
        BTreeNode child = btnode_insert(node, node->children[idx], key, val, result);
        // ...
    } else {
        if (btnode_isFull(node)) {    // IsFull
            DSKey *keyToParent;
            BTreeNode* pSib;
            *result = btnode_split(node, pSib, key, NULL, keyToParent);
            if (*result == DS_R_KEYDUP) { return node; }
            if (isRoot) {
                if (!(parent = btnode_new(node->order, node->h + 1, 0))) {
                    *result = DS_R_MALLOC;
                    return node;
                }
                btnode_addChild(parent, node);
            }
            parent = btnode_parent_insert(parent, key, *pSib, *result);
        } else {
            *result = btnode_addKey(node, key);
        }
    }

    return tmpParent == parent ? node : parent;
}

BTreeNode btnode_parent_insert(BTreeNode parent, DSKey key, BTreeNode child, DSResult* result)
{
    assert(parent->children != NULL);
    assert(parent->h > 1);
    assert(child != NULL);

    BTreeNode tmpParent = parent;
    if (btnode_isFull(parent)) {
        DSKey *keyToParent;
        BTreeNode* pSib;
        *result = btnode_split(parent, pSib, key, child, keyToParent);
        if (*result == DS_R_KEYDUP) { return parent; }
        if (isRoot) {
            if (!(parent = btnode_new(node->order, node->h + 1, 0))) {
                *result = DS_R_MALLOC;
                return node;
            }
            btnode_addChild(parent, node);
        }
        parent = btnode_parent_insert(parent, key, *pSib, *result);
    } else {
        *result = btnode_addKey(parent, key);
        assert(result == DS_R_OK);
        *result = btnode_addChild(parent, child);
        assert(result == DS_R_OK);
    }

    return NULL;
}

DSScalar btnode_isFull(BTreeNode node)
{
    assert(node);
    assert(node->h == 1 ? !node->children : node->children);
    DSScalar isFull = node->keyCount == node->order - 1;
    if (isFull && node->h > 1) {
        assert(node->childCount == node->order);
    }
    return isFull;
}


DSResult btnode_split(BTreeNode node, BTreeNode* pSib, DSKey key, BTreeNode child, DSKey* keyToParent)
{
    if (!node) { return DS_R_INVARG; }
    if (node->keyCount < node->order - 1) { return DS_R_INVARG; }
    if (!child && node->children) { return DS_R_INVARG; }
    if (child && (!node->children || node->childCount < node->order)) { return DS_R_INVARG; }
    if (child && ((child->h >= node->h) || (node->h - child->h != 1))) { return DS_R_INVARG; }

    BTreeNode sib = btnode_new(node->order, node->h, !node->children);
    if (!sib) { return DS_R_MALLOC; } 
    *pSib = sib;

    DSIndex idx;
    DSResult result = btnode_keyInsertIdx(node, key, &idx);
    if (result != DS_R_OK) {    // Key duplicate
        return result;
    }

    DSScalar median = node->order / 2;
    DSScalar mvKeySize = node->keyCount / 2;

    if (idx > median) {
        mvKeySize--;
    }

    // Move last mvKeySize keys from orig node to sib node
    memmove(&sib->keys[0], &node->keys[node->keyCount - mvKeySize], sizeof(DSKey) * mvKeySize);
    memset(&node->keys[node->keyCount - mvKeySize], 0, sizeof(DSKey) * mvKeySize);
    node->keyCount -= mvKeySize;
    sib->keyCount += mvKeySize;

    if (idx == median) {
        *keyToParent = key;
    } else {
        btnode_addKey(idx < median ? node : sib, key);
        *keyToParent = node->keys[node->keyCount - 1];
        node->keys[node->keyCount - 1] = 0;
        node->keyCount--;
    }

    if (!node->children) {
        return result;
    }

    DSScalar mvChildSize = sib->keyCount + 1;
    result = btnode_childInsertIdx(node, child, &idx);
    assert(result == DS_R_OK);

    if (idx > median) {
        mvChildSize--;
    }

    memmove(&sib->children[0], &node->children[node->childCount - mvChildSize], sizeof(DSKey) * mvChildSize);
    memset(&node->children[node->childCount - mvChildSize], 0, sizeof(DSKey) * mvChildSize);
    node->childCount -= mvChildSize;
    sib->childCount += mvChildSize;
    btnode_addChild(idx <= median ? node : sib, child);

    return result;
}


/**
 * Internal function 
 * Try to set the index where the key should go to. 
 */
DSResult btnode_keyInsertIdx(BTreeNode node, DSKey key, DSIndex* idx)
{
    if (!node) { return DS_R_INVARG; }
    DSIndex i = 0;
    for (; i < node->keyCount && key > node->keys[i]; i++);
    if (key == node->keys[i]) {
        return DS_R_KEYDUP; // Duplicated
    }
    *idx = i;
    return DS_R_OK;
}

DSResult btnode_childInsertIdx(BTreeNode node, BTreeNode child, DSIndex* idx)
{
    if (!node || !child) { return DS_R_INVARG; }
    if (child->h >= node->h || node->h - child->h != 1) { return DS_R_INVARG; }
    DSIndex i = 0; 
    DSKey key = child->children[0]->keys[0];
    for (; i < node->keyCount; i++) {
        if (child == node->children[i]) { return DS_R_INVOP; }
        if (key < node->children[i]->keys[0]) { break; }
        if (key == node->children[i]->keys[0]) { return DS_R_INVARG; }
    }
    *idx = i;
    return DS_R_OK; 
}

/**
 * Insert a key into the appropriate index of node
 * Validated
 */
DSResult btnode_addKey(BTreeNode node, DSKey key)
{
    if (!node) { return DS_R_INVARG; }
    if (node->keyCount == node->order - 1) { return DS_R_KEYFULL; }
    DSIndex idx;
    DSResult result = btnode_keyInsertIdx(node, key, &idx);
    if (result == DS_R_OK) {
        memmove(&node->keys[idx + 1], &node->keys[idx], sizeof(DSKey) * (node->keyCount - idx));
        node->keys[idx] = key;
        node->keyCount++;
    }    
    return result;
}

DSResult btnode_delKey(BTreeNode node, DSIndex idx, DSKey* key)
{
    if (!node || idx >= node->keyCount) { return DS_R_INVARG; }
    *key = node->keys[idx];
    memmove(&node->keys[idx], &node->keys[idx + 1], sizeof(DSKey) * (node->keyCount - 1 - idx));
    node->keys[node->keyCount - 1] = 0;
    node->keyCount--;
    return DS_R_OK;
}

DSResult btnode_addChild(BTreeNode node, BTreeNode child)
{
    if (!node) { return DS_R_INVARG; }
    if (node->childCount == node->order) { return DS_R_KEYFULL; }
    DSIndex idx;
    DSResult result = btnode_childInsertIdx(node, child, &idx);
    if (result == DS_R_OK) {
        memmove(&node->children[idx + 1], &node->children[idx], sizeof(DSKey) * (node->childCount - idx));
        node->children[idx] = child;
        node->childCount++;
    }
    return result;
}

DSResult btnode_delChild(BTreeNode node, DSIndex idx, BTreeNode* child)
{
    if (!node || idx >= node->childCount) { return DS_R_INVARG; }
    *child = node->children[idx];
    memmove(&node->children[idx], &node->children[idx + 1], sizeof(DSKey) * (node->childCount - 1 - idx));
    node->children[node->keyCount - 1] = NULL;
    node->childCount--;
    return DS_R_OK;
}


DSResult btnode_print(BTreeNode node)
{
    if (!node) {
        return DS_R_INVARG;
    }
    for (DSIndex i = 0; i < node->keyCount; i++) {
        printf("%zu->", node->keys[i]);
    }
    printf("\n");
    return DS_R_OK;
}

/* End of struct _BTreeNode function implementations */