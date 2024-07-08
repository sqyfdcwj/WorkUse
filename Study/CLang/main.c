
#include "DSDef.h"
#include "BTree.h"

int main()
{
    BTreeNode node = btnode_new(4, 1, 1);
    DSKey key;
    DSResult result;
    
    result = btnode_addKey(node, 10);
    result = btnode_addKey(node, 20);
    result = btnode_addKey(node, 30);

    btnode_print(node);
    result = btnode_delKey(node, 0, &key);
    printf("Result = %zu, key = %zu\n", result, key);

    btnode_print(node);
    result = btnode_delKey(node, 1, &key);
    printf("Result = %zu, key = %zu\n", result, key);

    btnode_print(node);
    result = btnode_delKey(node, 1, &key);
    printf("Result = %zu, key = %zu\n", result, key);
    btnode_print(node);
    // BTreeNode sib;
    // btnode_split(node, &sib, 31, NULL, &key);

    // printf("lhs = ");
    // btnode_print(node);
    // printf("key = %zu\n", key);
    // printf("rhs = ");
    // btnode_print(sib);

    btnode_delete(node);

    return 0;
}