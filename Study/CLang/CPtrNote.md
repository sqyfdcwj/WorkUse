The size of a `pointer` can vary, depending on the memory model supported by the target system and compiler.

|expr|description|ptr<br>modifiable|*ptr<br>modifiable|
|:-|:-|:-:|:-:|
|type*|Non const ptr points to non const|&check;|&check;|
|const type*|Non const ptr points to const|&check;|&cross;|
|type* const|Const ptr points to non const|&cross;|&check;|
|const type* const|Const ptr points to const|&cross;|&cross;|

Usage of realloc
void* realloc(void* ptr, size_t size)

|1st param|2nd param|Behavior|
|:-|:-|:-|
|NULL|Arbitrary size|Same as malloc()|
|Not NULL|0|Same as free()|
|Not NULL|Non-zero size smaller than original block|Smaller block allocated using current block|
|Not NULL|Size larger than original block|If sufficient contiguous space available:<br>resize current block in space<br>If no sufficient contiguous space available:<br>1. Allocate new block with new size<br>2. Copy existing data from old block to new block<br>3. Call free() for old block|

Organization of stack frame
|Element|Description|
|:-|:-|
|Return address|The address in the program where the function is to return upon completion|
|Local data storage|Memory allocated for local variable|
|Param storage|Memory allocated for function params|
|Stack & base pointers|Pointers used by the runtime system to manage the stack|

The `stack pointer` usually points to the top of the stack.

The `stack base pointer (frame pointer)` is often present and points to an address within the stack frame, such as the return address. 


