Unless specified, the term `sed` refers to GNU sed.

sed maintain 2 buffers: **PATTERN SPACE** and **HOLD SPACE**.<br>

**SED WORKFLOW**<br>
For each line in **input**, sed perform following steps until all lines have been processed.

The **input** is either a file specified by user, or **stdin** if no filename is specified

1. Read one line into **PATTERN SPACE**
2. Execute sed command at **PATTERN SPACE**
3. Write modified content to **stdout**
4. Clear all content in **PATTERN SPACE**

**Sed commands**
|Command|Description|
|:-:|:-|
|q [Exit code]|Exit sed without processing any more commands or input.|
|d|Delete the pattern space; immediately start next cycle.|
|p|Print out the pattern space to **stdout**|
|n|If auto-print is not disabled, print the pattern space, then, regardless, replace the pattern space with the next line of input.<br> If there is no more input then sed exits without processing any more commands.|
|{ commands }|A group of commands may be enclosed between { and } characters.<br> This is particularly useful when you want a group of commands to be triggered by a single address (or address-range) match.|
|y/source-chars/dest-chars/|Transliterate any characters in the pattern space which match any of the source-chars with the corresponding character in dest-chars.|
|a [text]|Append [text] after a line|
|i [text]|Insert [text] before a line|
|c [text]|Replace lines with [text]|
|||