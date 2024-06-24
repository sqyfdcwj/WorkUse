C concepts and terms

A `symbol` refers to an identifier which is defined by user. It can be:
1. variables 
2. functions 
3. constants 
4. labels 
5. enums 
6. structure/union tags 
7. typedef names


A `translation unit` is the basic unit of compilation.
It consists of the source file being compiled (including any headers it includes) after preprocessing.

We can say that the `.o` target in a Makefile represents a translation unit.

`External linkage` refers to the visibility of functions or variables across `translation unit`. 
When a variable is declared with `extern` or is not `static`, it can be accessed by other translation unit.

`Internal linkage` restricts the visibility of functions or variables. It can only be accessed within the translation unit where it is defined.

In C, functions are considered `external` by default,
which means they have `external linkage`.
You can specify `static` keyword to restrict the function to have `internal linkage`.

In C, if the variable should be shared:
1. Delcare it in `.h` file. Use `static` keyword
2. Define it in `.c` file without `static` keyword

