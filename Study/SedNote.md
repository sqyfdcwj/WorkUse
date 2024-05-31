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
|g|Apply the replacement to **ALL** matches to the regexp, not just the first|
|number|Only replace the **number**th match of the regexp|
|w|Output filename|

**sed insert/append command**

MacOS uses BSD sed, which is not GNU sed. 
