
#include "AVLTree.h"

struct _AVLTree     // AVL tree
{
    DSScalar elementCount;
    AVLNode root;
};

struct _AVLNode     // AVL node 
{
    DSScalar height;
    DSKey key;
    DSVal val;
    AVLNode left;
    AVLNode right;
};

/* Begin of struct _AVLNode private functions */
AVLNode avln_new(DSKey, DSVal);
AVLNode avln_delete(AVLNode);   // Delete recursively
AVLNode avln_insert(AVLNode, DSKey, DSVal, DSResult*);
AVLNode avln_remove(AVLNode, DSKey, DSVal*);
void avln_search(AVLNode, DSKey, DSVal*);

AVLNode avln_rebalance(AVLNode);
AVLNode avln_ll(AVLNode); // Left rotation
AVLNode avln_rr(AVLNode); // Right rotation
AVLNode avln_lr(AVLNode); // Left-right rotation
AVLNode avln_rl(AVLNode); // Right-left rotation

DSScalar avln_ch(AVLNode);  // Get higher value of height of chilren
AVLNode avln_adjl(AVLNode); // Get node which value is smaller than node
AVLNode avln_adjr(AVLNode); // Get node which value is larger than node

void avln_swap_kv(AVLNode, AVLNode);
void avln_walk(AVLNode, AVLNodeFunc, DSTreeTraverseMode);
void avlv_walk(AVLNode, AVLValFunc, DSTreeTraverseMode);
/* End of struct _AVLNode private functions */

/* Begin of struct _AVLTree function implementations */
AVLTree avl_new()
{
    AVLTree tree = malloc(sizeof(struct _AVLTree));
    tree->root = NULL;
    tree->elementCount = 0;
    return tree;
}

AVLTree avl_delete(AVLTree tree)
{
    if (tree) {
        if (tree->root) {
            avln_delete(tree->root);
        }
        free(tree);
    }
    return NULL;
}

DSScalar avl_h(AVLTree tree) { return tree ? avln_h(tree->root) : 0; }

DSScalar avl_elementCount(AVLTree tree) { return tree ? tree->elementCount : 0; }

DSResult avl_insert(AVLTree tree, DSKey key, DSVal val)
{
    if (!tree || !val) { return DS_R_INVARG; }
    DSResult res;
    tree->root = avln_insert(tree->root, key, val, &res);
    if (res == DS_R_OK) {
        tree->elementCount++;
    }
    return res;
}

DSVal avl_remove(AVLTree tree, DSKey key)
{
    if (!tree) { return NULL; }
    DSVal result;
    tree->root = avln_remove(tree->root, key, &result);
    if (result == DS_R_OK) {
        tree->elementCount--;
    }
    return result;
}

DSVal avl_search(AVLTree tree, DSKey key)
{
    if (!tree) { return NULL; }
    DSVal result = NULL;
    avln_search(tree->root, key, &result);
    return result;
}

DSResult avl_walk_v(AVLTree tree, AVLValFunc fn, DSTreeTraverseMode mode)
{
    if (!tree || !fn || mode > DST_TMODE_POSTORDER) {
        return DS_R_INVARG;
    }
    if (tree->root) {
        avlv_walk(tree->root, fn, mode);
    }
    return DS_R_OK;
}

DSResult avl_walk_n(AVLTree tree, AVLNodeFunc fn, DSTreeTraverseMode mode)
{
    if (!tree || !fn || mode > DST_TMODE_POSTORDER) {
        return DS_R_INVARG;
    }
    if (tree->root) {
        avln_walk(tree->root, fn, mode);
    }
    return DS_R_OK;
}
/* End of struct _AVLTree function implementations */

/* Begin of struct _AVLNode function implementations */
DSKey avln_key(AVLNode node) { return node ? node->key : 0; }
DSVal avln_val(AVLNode node) { return node ? node->val : NULL; }
DSScalar avln_h(AVLNode node) { return node ? node->height : 0; }

DSScalar avln_ch(AVLNode node)
{
    if (!node) { return 0; }
    DSScalar lh = avln_h(node->left);
    DSScalar rh = avln_h(node->right);
    return lh >= rh ? lh : rh;
}

AVLNode avln_new(DSKey key, DSVal val)
{
    AVLNode node = malloc(sizeof(struct _AVLNode));
    if (node) {
        node->height = 1;
        node->key = key;
        node->val = val;
        node->left = NULL;
        node->right = NULL;
    }
    return node;
}

AVLNode avln_delete(AVLNode node)
{
    if (node) {
        node->left = avln_delete(node->left);
        node->right = avln_delete(node->right);
        free(node);
    }
    return NULL;
}

AVLNode avln_insert(AVLNode node, DSKey key, DSVal val, DSResult* result)
{
    if (!node) {
        node = avln_new(key, val);
        *result = node ? DS_R_OK : DS_R_MALLOC;
        return node;
    }

    if (key < node->key) {
        node->left = avln_insert(node->left, key, val, result);
    } else if (key > node->key) {
        node->right = avln_insert(node->right, key, val, result);
    } else {
        *result = DS_R_KEYDUP;
        return node;
    }

    node->height = avln_ch(node) + 1;
    return avln_rebalance(node);
}

AVLNode avln_remove(AVLNode node, DSKey key, DSVal* res)
{
    if (!node) { 
        *res = NULL;
        return NULL; 
    }

    if (key < node->key) {
        node->left = avln_remove(node->left, key, res);
    } else if (key > node->key) {
        node->right = avln_remove(node->right, key, res);
    } else {
        if (node->left && node->right) {
            if (avln_h(node->left) >= avln_h(node->right)) {
                avln_swap_kv(node, avln_adjl(node));
                node->left = avln_remove(node->left, key, res);
            } else {
                avln_swap_kv(node, avln_adjr(node));
                node->right = avln_remove(node->right, key, res);
            }
        } else {
            *res = node->val;
            free(node); // You can still access member after calling free()
            if (node->left) {
                return node->left;
            } else if (node->right) {
                return node->right;
            } else {
                return NULL;
            }
        }
    }

    node = avln_rebalance(node);
    node->height = avln_ch(node) + 1;
    return node;
}

void avln_search(AVLNode node, DSKey key, DSVal *res)
{
    if (!node) {
        *res = NULL;
        return;
    }
    if (key < node->key) {
        avln_search(node->left, key, res);
    } else if (key > node->key) {
        avln_search(node->right, key, res);
    } else {
        *res = node->val;
    }
}

void avln_swap_kv(AVLNode lhs, AVLNode rhs)
{
    if (!lhs || !rhs) { return; }
    DSKey k = lhs->key;
    DSVal v = lhs->val;
    lhs->key = rhs->key;
    rhs->key = k;
    lhs->val = rhs->val;
    rhs->val = v;
}

AVLNode avln_rebalance(AVLNode node)
{
    if (!node) { return NULL; }
    DSScalar lh = avln_h(node->left);
    DSScalar rh = avln_h(node->right);
    AVLNode child;
    
    if (lh - rh == 2) {
        child = node->left;     // Left child overweight
        return avln_h(child->left) >= avln_h(child->right) ? avln_rr(node) : avln_lr(node);
    } else if (rh - lh == 2) {
        child = node->right;    // Right child overweight
        return avln_h(child->right) >= avln_h(child->left) ? avln_ll(node) : avln_rl(node);
    } else {
        return node;
    }
}

AVLNode avln_ll(AVLNode root)
{
    AVLNode newRoot = root->right;
    root->right = newRoot->left;
    newRoot->left = root;
    root->height = avln_ch(root) + 1;
    return newRoot;
}

AVLNode avln_rr(AVLNode root)
{
    AVLNode newRoot = root->left;
    root->left = newRoot->right;
    newRoot->right = root;
    root->height = avln_ch(root) + 1;
    return newRoot;
}

AVLNode avln_lr(AVLNode root)
{
    root->left = avln_ll(root->left);
    return avln_rr(root);
}

AVLNode avln_rl(AVLNode root)
{
    root->right = avln_rr(root->right);
    return avln_ll(root);
}

void avln_walk(AVLNode node, AVLNodeFunc fn, DSTreeTraverseMode mode)
{
    if (!node) { return; }
    if (mode == DST_TMODE_INORDER) {
        avln_walk(node->left, fn, mode);
        fn(node);
        avln_walk(node->right, fn, mode);
    } else if (mode == DST_TMODE_PREORDER) {
        fn(node);
        avln_walk(node->left, fn, mode);
        avln_walk(node->right, fn, mode);
    } else {
        avln_walk(node->left, fn, mode);
        avln_walk(node->right, fn, mode);
        fn(node);
    }
}

void avlv_walk(AVLNode node, AVLValFunc fn, DSTreeTraverseMode mode)
{
    if (!node) { return; }
    if (mode == DST_TMODE_INORDER) {
        avlv_walk(node->left, fn, mode);
        fn(node->val);
        avlv_walk(node->right, fn, mode);
    } else if (mode == DST_TMODE_PREORDER) {
        fn(node->val);
        avlv_walk(node->left, fn, mode);
        avlv_walk(node->right, fn, mode);
    } else {
        avlv_walk(node->left, fn, mode);
        avlv_walk(node->right, fn, mode);
        fn(node->val);
    }
}

AVLNode avln_adjl(AVLNode node)
{
    if (!node || !node->left) { return NULL; }
    AVLNode result = node->left;
    while (result->right) { result = result->right; }
    return result;
}

AVLNode avln_adjr(AVLNode node)
{
    if (!node || !node->right) { return NULL; }
    AVLNode result = node->right;
    while (result->left) { result = result->left; }
    return result;
}
/* End of struct _AVLNode function implementations */
