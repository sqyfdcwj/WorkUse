All division arithmetic operation here is integer division. Decimal part is discarded.

For a BTreeNode with order M:
It has key count, denoted as K:
Minimum K = (M - 1) / 2
Maximum K = M - 1

Example: 
M = 4, min K = (4 - 1) / 2 = 1, max K = 4 - 1 = 3
M = 5, min K = (5 - 1) / 2 = 2, max K = 5 - 1 = 4

It has childrenCount, denoted as C:
C = K + 1, if the node is not leaf

When we insert new key into a BTreeNode with K keys, we have K + 1 slots (DSIndex), from 0 to K.

When the node is full (already containing M - 1 keys), we need to split it.
If the order of original node M is even, the sibling node will contain less keys than original.

Example: 
M = 4, after rearrange, then original node contains 2 keys, sibling node contains 1 key
M = 5, after rearrange, both original node and sibling node contains 2 key

We use btnode_getKeyDSIndex() to get the DSIndex X which is the position the new key goes to.
If there is element on DSIndex X, all element start from X will be right shifted 1 DSIndex for new key

Given a full BTreeNode with K keys,
its median = 


