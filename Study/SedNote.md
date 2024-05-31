**This note is based on GNU sed.**
**MacOS uses BSD sed. Some behavior may differ from GNU sed.**

**SYNOPSIS**
sed [**-Ealn**] command [file ...]
sed [**-Ealn**] [**-e** command] [**-f** command_file] [**-i** extension] [file ...]

**DESCRIPTION**<br>
Reads the specified files, or the **STDIN** if no files are specified,<br>modifying the input as specified by a list of **commands**.
The input is then written to the **STDOUT**.

A single command may be specified as the first argument to sed.<br> Multiple commands may be specified by using the **-e** or **-f** options.
> sed '' a.txt
> sed -n '3,5p' a.txt

All commands are applied to the input **in the order they are specified** regardless of their origin.<br>

**sed script overview**
A sed program consists of **one or more sed commands**.
sed commands follow this syntax:
> [addr][X][options]

|Part|Description|
|:-:|:-|
|addr|Optional line address<br>**addr** can be a single line number, a regex, or a range of lines|
|X|Single-letter sed command<br>If **addr** is specified, X will be executed **ONLY** on the matched lines|
|options|Used for some sed commands|

The following example deletes line 30 to 35 of file input.txt
> sed '30,35d' input.txt

|Part|Value|Descrption|
|:-|:-|:-|
|addr|30,35|Line range|
|X|d|Delete command|
|Options|Not specified in this example|N/A|

**sed substitute command**
> s/regexp/replacement/flags

The s command can be followed by **zero or more** of the following flags:

Possible value of flags
|flags|Description|
|:-:|:-|
|i|Case insensitive|
|g|Apply the replacement to **ALL** matches to the regexp, not just the first|
|number|Only replace the **number**th match of the regexp|
|w|Output filename|

Given a.txt with content:
this is line 1
this this is line 2
this this this is line 3

Replace all 'this' occurance with 'That', case sensitive:


**sed insert/append command**
Insert means to insert text **BEFORE** a line
Append means to insert text **AFTER** a line

Insert new line without condition
> sed 'i Newline' a.txt

Insert new line before line 2
> sed '2i Newline' a.txt

Insert new line before lines matching pattern
> sed '/pattern/i Newline' a.txt

> sed '2a Newline' a.txt

**sed delete command**
Delete all content
> sed 'd' a.txt

Delete line **X**
> sed '**X**d' a.txt

Delete last line
> sed '$d' a.txt

Delete from line **X** to line **Y**
> sed '**X**,**Y**d' a.txt

Delete from line **X** to last line
> sed '**X**,$d' a.txt

Delete lines match pattern
> sed '/pattern/d' a.txt

