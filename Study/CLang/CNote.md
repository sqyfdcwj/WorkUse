`The C compilation process`
1. Pre-processing
2. Compiling
3. Assembling
4. Linking

`Static functions`
1. A static function in C has file scope. 
2. Functions are global, and extern by default
3. A function prototype declaration is a "tentative definition", that is implicitly extern.
4. A static function prototype declaration is a "tentative definition", that is explicitly not extern.
5. The First definition of a file signature is the one used for the whole program, including static or extern. 